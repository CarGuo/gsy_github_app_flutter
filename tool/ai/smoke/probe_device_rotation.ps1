<#
.SYNOPSIS
    Discussions §3.1 pt.4 前置：真机旋转 override 中立诊断脚本（Windows PowerShell 7+）。

.DESCRIPTION
    真机验收 pt.1/2/4/5 共同卡在同一个前置："设备旋转 override 排查"。
    过去每个 author 上手时都要临时拼一遍 `settings get` / `dumpsys display` /
    `wm user-rotation lock` 组合命令，跑完就散，下一次接手又得重来。

    本脚本把 roadmap §3.1 pt.4 里那 4 条排查思路（见 docs/00-overview/roadmap.md）
    翻译成 4 步中立诊断，产物一次性落到 evidence/<yyyymmdd_hhmm>/：

        step1_baseline       : 只读，抓 baseline rotation / display / size / prop
        step2_settings_probe : 只读，探测 accelerometer_rotation / user_rotation
                               当前值，不写。仅在 -Apply 时写 override（0=竖屏）
        step3_wm_probe       : 只读探测 `wm user-rotation lock` 是否被 ROM 支持
                               （查询 status）。仅在 -Apply 时下发 lock 0
        step4_summary        : 汇总 + 生成 fix 建议清单（纯文本报告）

    默认**完全只读**，不会 force-stop 任何 app、不会改任何 settings、不会
    重启设备。加 -Apply 才写 override；-OfferReboot 只做提示，不会替用户执行
    `adb reboot`（reboot 是 pt.4 排查思路第 3 步的兜底，交给 author 手动决定）。

    产物：
      - <OutDir>\rotation_probe_report.txt        步骤化人类可读报告
      - <OutDir>\rotation_probe_raw.json          结构化字段（reviewer / 后续脚本可用）
      - <OutDir>\dumpsys_display.txt              全量 dumpsys display，避免 rotation
                                                  字段丢失时回头找不到证据
      - <OutDir>\settings_dump.txt                system namespace settings 快照
      - <OutDir>\wm_size.txt / wm_density.txt     物理分辨率 & 密度快照
      - <OutDir>\screencap_before.png             (可选) -Screenshot 时抓一张当前画面
      - <OutDir>\screencap_after.png              (可选) -Apply 时对照抓一张

.PARAMETER OutDir
    证据落地目录（可用 -Out 别名）。默认 tool/ai/smoke/evidence/<yyyymmdd_hhmm>/。

.PARAMETER Device
    传给 adb -s 的设备 id。默认不传，adb 自己挑（多设备时请显式传）。

.PARAMETER Apply
    切到"写模式"：会依次尝试
        settings put system accelerometer_rotation 0
        settings put system user_rotation 0
        wm user-rotation lock 0
    每一步失败或不被 ROM 支持都会记录到 report，不 abort。默认关。

.PARAMETER Screenshot
    每次探测前后各抓一张 screencap。默认关（避免污染 evidence 时的隐私）。

.PARAMETER OfferReboot
    在 report 末尾打印 `adb reboot` 建议命令 + 观察项。**不会**替用户执行。

.EXAMPLE
    tool\ai\smoke\probe_device_rotation.ps1
        默认只读诊断，evidence 落到 tool/ai/smoke/evidence/<当前时间>/

.EXAMPLE
    tool\ai\smoke\probe_device_rotation.ps1 -Apply -Screenshot -Device jfxgpjeul7lrpjkz
        显式写 rotation override 到 0（竖屏），抓前后对比截图

.NOTES
    对齐 AGENTS.md 允许清单：本脚本不做 mutation（GitHub API 意义上），
    settings put / wm user-rotation lock 属于**设备侧诊断修改**，仅在 -Apply
    显式开关时才会下发；author 负责在完成汇报里显式说明是否 -Apply 过。
#>
[CmdletBinding()]
param(
    [Alias('Out')]
    [string]$OutDir,
    [string]$Device,
    [switch]$Apply,
    [switch]$Screenshot,
    [switch]$OfferReboot
)

$ErrorActionPreference = 'Stop'

# adb 前缀：可选 -s <device>
$adb = @('adb')
if ($Device) { $adb += @('-s', $Device) }

# 默认 evidence 目录：tool/ai/smoke/evidence/yyyymmdd_hhmm/
if (-not $OutDir) {
    $ts = (Get-Date).ToString('yyyyMMdd_HHmm')
    $OutDir = Join-Path $PSScriptRoot "evidence\$ts"
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Write-Host "[probe_device_rotation] evidence dir: $OutDir"

# 校验设备可见：`adb devices` 不接受 -s，必须裸调；若显式传了 -Device 再校验该 id 在线
$devicesRaw = (& $adb[0] devices 2>&1) -join "`n"
$onlineIds = ($devicesRaw -split "`n") |
    Where-Object { $_ -match '^\S+\s+device\s*$' } |
    ForEach-Object { ($_ -split '\s+')[0] }
if (-not $onlineIds -or $onlineIds.Count -eq 0) {
    Write-Error '[probe_device_rotation] adb 未检测到 online 设备，先跑 adb devices'
    exit 1
}
if ($Device -and ($onlineIds -notcontains $Device)) {
    Write-Error "[probe_device_rotation] 指定 -Device '$Device' 不在 online 设备列表：$($onlineIds -join ', ')"
    exit 1
}

function Invoke-Adb {
    # 用 $args 自动变量把所有透传参数交给 adb，避免函数进入 advanced mode 后
    # PowerShell 抢占 '-p' / '-o' 等 CmdletBinding 通用参数前缀
    & $adb[0] ($adb[1..($adb.Length - 1)] + $args)
}

function Save-AdbBinary {
    # 与 open_home_dynamic.ps1 同款：绕开 PowerShell 重定向对二进制流的 UTF-16 padding
    param([string]$Path, [string[]]$AdbCmd)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $adb[0]
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    foreach ($a in $adb[1..($adb.Length - 1)]) { $psi.ArgumentList.Add($a) }
    foreach ($a in $AdbCmd) { $psi.ArgumentList.Add($a) }
    $proc = [System.Diagnostics.Process]::Start($psi)
    $mem = New-Object System.IO.MemoryStream
    $proc.StandardOutput.BaseStream.CopyTo($mem)
    $proc.WaitForExit()
    [System.IO.File]::WriteAllBytes($Path, $mem.ToArray())
}

function Save-Text {
    param([string]$Path, [string]$Content)
    Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8
}

$report = New-Object System.Collections.Generic.List[string]
$raw = [ordered]@{}

function Add-Line { param([string]$Line) $report.Add($Line) | Out-Null }
function Add-Section { param([string]$Title) Add-Line ''; Add-Line "=== $Title ===" }

$startedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
Add-Line "# probe_device_rotation report"
Add-Line "started_at: $startedAt"
Add-Line "device: $($Device ? $Device : '(adb default)')"
Add-Line "apply: $Apply"
Add-Line "screenshot: $Screenshot"
Add-Line "offer_reboot: $OfferReboot"

$raw['started_at'] = $startedAt
$raw['device']     = ($Device ? $Device : '')
$raw['apply']      = [bool]$Apply
$raw['screenshot'] = [bool]$Screenshot
$raw['offer_reboot'] = [bool]$OfferReboot

# ------------------------------------------------------------------
# [1/4] baseline: wm size / density / dumpsys display / props
# ------------------------------------------------------------------
Write-Host '[1/4] baseline snapshot (read-only)'
Add-Section 'step1 baseline (read-only)'

$wmSize = (Invoke-Adb shell wm size) -join "`n"
$wmDensity = (Invoke-Adb shell wm density) -join "`n"
Save-Text (Join-Path $OutDir 'wm_size.txt') $wmSize
Save-Text (Join-Path $OutDir 'wm_density.txt') $wmDensity
Add-Line "wm size:    $($wmSize -replace "`n",' | ')"
Add-Line "wm density: $($wmDensity -replace "`n",' | ')"
$raw['wm_size'] = $wmSize
$raw['wm_density'] = $wmDensity

# 全量 dumpsys display 落文件；从中挑 rotation / orientation 相关行落 report
$dumpsysDisplayRaw = (Invoke-Adb shell dumpsys display) -join "`n"
Save-Text (Join-Path $OutDir 'dumpsys_display.txt') $dumpsysDisplayRaw
$rotLines = ($dumpsysDisplayRaw -split "`n") | Where-Object { $_ -match '(?i)rotation|orientation' } | Select-Object -First 12
Add-Line 'dumpsys display | grep -Ei rotation|orientation (first 12):'
foreach ($ln in $rotLines) { Add-Line "  $ln" }
$raw['dumpsys_display_rotation_lines'] = $rotLines

# 关键 prop
$propKeys = @(
    'ro.sf.hwrotation',
    'persist.sys.orientation',
    'persist.demo.hdmirotation'
)
$propMap = [ordered]@{}
foreach ($k in $propKeys) {
    $v = ((Invoke-Adb shell getprop $k) -join '').Trim()
    $propMap[$k] = $v
    Add-Line "getprop ${k}: ${v}"
}
$raw['props'] = $propMap

if ($Screenshot) {
    Save-AdbBinary -Path (Join-Path $OutDir 'screencap_before.png') -AdbCmd @('exec-out','screencap','-p')
    Add-Line 'screencap_before.png saved'
}

# ------------------------------------------------------------------
# [2/4] settings probe: accelerometer_rotation / user_rotation
# ------------------------------------------------------------------
Write-Host '[2/4] settings probe (read; write only if -Apply)'
Add-Section 'step2 settings probe'

$settingsKeys = @('accelerometer_rotation','user_rotation')
$settingsBefore = [ordered]@{}
foreach ($k in $settingsKeys) {
    $v = ((Invoke-Adb shell settings get system $k) -join '').Trim()
    $settingsBefore[$k] = $v
    Add-Line "settings get system ${k}: ${v}"
}
$raw['settings_before'] = $settingsBefore

# 快照 system namespace（长文件另存，方便回头 diff）
$settingsDump = (Invoke-Adb shell settings list system) -join "`n"
Save-Text (Join-Path $OutDir 'settings_dump.txt') $settingsDump

$settingsAfter = [ordered]@{}
if ($Apply) {
    Write-Host '  -Apply: writing accelerometer_rotation=0, user_rotation=0'
    Invoke-Adb shell settings put system accelerometer_rotation 0 | Out-Null
    Invoke-Adb shell settings put system user_rotation 0 | Out-Null
    Start-Sleep -Milliseconds 400
    foreach ($k in $settingsKeys) {
        $v = ((Invoke-Adb shell settings get system $k) -join '').Trim()
        $settingsAfter[$k] = $v
        Add-Line "after put system ${k}: ${v}"
    }
    $raw['settings_after'] = $settingsAfter
} else {
    Add-Line 'skip write (default read-only; pass -Apply to actually write)'
    $raw['settings_after'] = $null
}

# ------------------------------------------------------------------
# [3/4] wm user-rotation lock probe (ROM 兼容性差异)
# ------------------------------------------------------------------
Write-Host '[3/4] wm user-rotation probe (some ROMs lack this subcommand)'
Add-Section 'step3 wm user-rotation probe'

# 先无参调用探测是否可用；老 ROM / AOSP 早期版本会返回 usage 报错
$wmUserRotProbe = (Invoke-Adb shell wm user-rotation 2>&1) -join "`n"
Add-Line 'wm user-rotation (probe stdout+stderr):'
foreach ($ln in ($wmUserRotProbe -split "`n") | Select-Object -First 8) { Add-Line "  $ln" }
$raw['wm_user_rotation_probe'] = $wmUserRotProbe

$wmSupported = -not ($wmUserRotProbe -match '(?i)unknown command|error: no such|Unknown option|not found|Usage:')

if ($Apply -and $wmSupported) {
    Write-Host '  -Apply + wm user-rotation supported: locking to 0'
    $wmLockOut = (Invoke-Adb shell wm user-rotation lock 0 2>&1) -join "`n"
    Add-Line 'wm user-rotation lock 0:'
    foreach ($ln in ($wmLockOut -split "`n") | Select-Object -First 6) { Add-Line "  $ln" }
    $raw['wm_user_rotation_lock_output'] = $wmLockOut
} else {
    Add-Line "skip wm user-rotation lock (Apply=$Apply, supported=$wmSupported)"
}

if ($Apply -and $Screenshot) {
    Start-Sleep -Milliseconds 800
    Save-AdbBinary -Path (Join-Path $OutDir 'screencap_after.png') -AdbCmd @('exec-out','screencap','-p')
    Add-Line 'screencap_after.png saved'
}

# ------------------------------------------------------------------
# [4/4] summary + suggestions
# ------------------------------------------------------------------
Write-Host '[4/4] summary & suggestions'
Add-Section 'step4 summary & next actions'

# roadmap pt.4 排查思路 4 步的落地建议
$verdict = @()
if ($settingsBefore['user_rotation'] -ne '0') {
    $verdict += 'user_rotation != 0：默认坐标脚本假设竖屏，非 0 会导致 open_pr_timeline.sh / open_repo_discussions_tab.sh tap 落错。跑一遍 -Apply 或人工强制竖屏。'
}
if ($settingsBefore['accelerometer_rotation'] -eq '1') {
    $verdict += 'accelerometer_rotation=1：自动旋转开着，冒烟中途手机翻身会打乱坐标。建议 -Apply 关掉。'
}
if (-not $wmSupported) {
    $verdict += 'wm user-rotation 不被当前 ROM 支持：走 settings put 那条即可，跳过 wm lock。'
}
if ($OfferReboot) {
    $verdict += 'OfferReboot=on：兜底方案是 adb reboot 后重新跑本脚本 baseline，观察 rotation 是否恢复。脚本不会替你执行 adb reboot。'
}
if ($verdict.Count -eq 0) {
    $verdict += 'baseline 未发现明显异常。若真机上冒烟仍然 tap 落错，考虑 pt.4 思路 4：改走 flutter_driver / integration_test 按 semantics label 定位（需新增依赖，PR 描述里显式提出）。'
}
foreach ($v in $verdict) { Add-Line "- $v" }
$raw['verdict'] = $verdict

Add-Line ''
Add-Line 'roadmap §3.1 pt.4 排查思路对应表：'
Add-Line '  思路1  settings get/put accelerometer_rotation + user_rotation  -> step2'
Add-Line '  思路2  wm user-rotation lock 0                                  -> step3'
Add-Line '  思路3  adb reboot 后重看 wm size / dumpsys display               -> -OfferReboot 提示（不代跑）'
Add-Line '  思路4  改用 flutter_driver / integration_test 按 semantics 定位  -> 需 PR 描述里显式提出，脚本不引入依赖'

# 落文件
Save-Text (Join-Path $OutDir 'rotation_probe_report.txt') ($report -join "`n")
$rawJson = $raw | ConvertTo-Json -Depth 6
Save-Text (Join-Path $OutDir 'rotation_probe_raw.json') $rawJson

Write-Host ''
Write-Host "[probe_device_rotation] done"
Write-Host "  report: $(Join-Path $OutDir 'rotation_probe_report.txt')"
Write-Host "  raw:    $(Join-Path $OutDir 'rotation_probe_raw.json')"
Write-Host ''
foreach ($v in $verdict) { Write-Host "  - $v" }
