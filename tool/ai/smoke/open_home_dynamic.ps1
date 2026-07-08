<#
.SYNOPSIS
    Windows 侧 GSY 首页动态真机冒烟脚本。等价于 open_home_dynamic.sh。

.DESCRIPTION
    让 GSY app 回到"首页动态 tab"，走完 receive feed 的下拉刷新 + 上拉加载 + 慢滚
    一整轮，把 5 张证据截图 + logcat 抓到 -Out 指定目录（默认
    tool/ai/smoke/evidence/<今日 yyyymmdd_hhmm>/）。

    主要用来验证 lib/page/dynamic/dynamic_page.dart 与 lib/common/utils/event_utils.dart
    里的事件识别在真机上是否稳定。

    与 open_home_dynamic.sh 保持 6 步一致：
        1  强制竖屏 + am force-stop + 冷启
        2  下拉刷新
        3  连续上滑 8 次触发分页 + 深滚到 1-2 天前
        4  慢滚回中段
        5  再触发 2 次上拉 load more
        6  抓 logcat 并按 EventUtils/IssueTimeline warning + flutter Exception 分类计数

.PARAMETER OutDir
    证据落地目录（可用 -Out 别名）。默认走 tool/ai/smoke/evidence/<当前时间>/，
    脚本会自动 mkdir -p。

.PARAMETER Device
    传给 adb -s 的设备 id。默认不传，adb 自己挑（多设备时请显式传）。

.PARAMETER KeepAttach
    与 sh 版 SMOKE_KEEP_ATTACH=1 语义等价：保留 flutter run attach，不 force-stop。
    副作用：无法保证清空 back stack。

.EXAMPLE
    tool\ai\smoke\open_home_dynamic.ps1

.EXAMPLE
    tool\ai\smoke\open_home_dynamic.ps1 -OutDir D:\tmp\c1 -Device jfxgpjeul7lrpjkz

.NOTES
    分辨率假设：1080x2400。换分辨率请先跑 `adb shell wm size` + 抓一张 screencap
    校准坐标，然后同步改 open_home_dynamic.sh 和本文件。

    Windows 编码坑：`adb logcat -d > file` 走 PowerShell 重定向可能只写出几十字节
    （UTF-16 padding 问题），本脚本用 `adb exec-out logcat` + 二进制重定向绕过。
#>
[CmdletBinding()]
param(
    [Alias('Out')]
    [string]$OutDir,
    [string]$Device,
    [switch]$KeepAttach
)

$ErrorActionPreference = 'Stop'
$PKG = 'com.shuyu.gsygithub.gsygithubappflutter'

# adb 前缀：可选 -s <device>
$adb = @('adb')
if ($Device) { $adb += @('-s', $Device) }

# 默认 evidence 目录：tool/ai/smoke/evidence/yyyymmdd_hhmm/
if (-not $OutDir) {
    $ts = (Get-Date).ToString('yyyyMMdd_HHmm')
    $OutDir = Join-Path $PSScriptRoot "evidence\$ts"
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Write-Host "[open_home_dynamic] evidence dir: $OutDir"

# 校验设备可见
$devicesRaw = & $adb[0] $adb[1..($adb.Length - 1)] devices 2>&1
if (-not ($devicesRaw -match '\bdevice\b')) {
    Write-Error '[open_home_dynamic] adb 未检测到设备，先跑 adb devices'
    exit 1
}

function Invoke-Adb {
    # 用 $args 自动变量把所有透传参数交给 adb，避免函数进入 advanced mode 后
    # PowerShell 抢占 '-p' / '-o' 等 CmdletBinding 通用参数前缀
    & $adb[0] ($adb[1..($adb.Length - 1)] + $args)
}

function Save-AdbBinary {
    # 把 adb exec-out 的二进制 stdout 存成文件。
    # 直接走 PowerShell `>` 重定向会被 UTF-16 padding 破坏（同 C/1 遇过的坑），
    # Set-Content -Encoding Byte 在 PS7 已废弃，改成 [IO.File]::WriteAllBytes。
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

# ------------------------------------------------------------------
# [1/6] 强制竖屏 + 冷启动
# ------------------------------------------------------------------
Write-Host '[1/6] rotate portrait + cold start'
Invoke-Adb shell settings put system accelerometer_rotation 0 | Out-Null
Invoke-Adb shell settings put system user_rotation 0 | Out-Null

if ($KeepAttach) {
    Write-Host '  KeepAttach=true，保留 flutter run attach，不 force-stop'
} else {
    Invoke-Adb shell am force-stop $PKG | Out-Null
    Start-Sleep -Seconds 1
}
Invoke-Adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null
Start-Sleep -Seconds 12
Save-AdbBinary -Path (Join-Path $OutDir '01_launch.png') -AdbCmd @('exec-out','screencap','-p')

# ------------------------------------------------------------------
# [2/6] 下拉刷新
# ------------------------------------------------------------------
Write-Host '[2/6] pull to refresh'
Invoke-Adb shell input swipe 540 400 540 1400 400
Start-Sleep -Seconds 5
Save-AdbBinary -Path (Join-Path $OutDir '02_refreshed.png') -AdbCmd @('exec-out','screencap','-p')

# ------------------------------------------------------------------
# [3/6] 连续上滑 8 次触发分页 + 深入 1-2 天前
# ------------------------------------------------------------------
Write-Host '[3/6] scroll up 8 times (trigger page 2 dedupe path)'
for ($i = 1; $i -le 8; $i++) {
    Invoke-Adb shell input swipe 540 1900 540 400 250
    Start-Sleep -Milliseconds 500
}
Start-Sleep -Seconds 3
Save-AdbBinary -Path (Join-Path $OutDir '03_scrolled_deep.png') -AdbCmd @('exec-out','screencap','-p')

# ------------------------------------------------------------------
# [4/6] 慢滚回中段
# ------------------------------------------------------------------
Write-Host '[4/6] scroll back middle'
Invoke-Adb shell input swipe 540 800 540 1500 400
Start-Sleep -Seconds 1
Invoke-Adb shell input swipe 540 800 540 1500 400
Start-Sleep -Seconds 1
Save-AdbBinary -Path (Join-Path $OutDir '04_middle.png') -AdbCmd @('exec-out','screencap','-p')

# ------------------------------------------------------------------
# [5/6] 触发第 2 页 load more（再往下拉几次）
# ------------------------------------------------------------------
Write-Host '[5/6] trigger load more x2'
Invoke-Adb shell input swipe 540 1900 540 200 300
Start-Sleep -Seconds 3
Invoke-Adb shell input swipe 540 1900 540 200 300
Start-Sleep -Seconds 3
Save-AdbBinary -Path (Join-Path $OutDir '05_after_loadmore.png') -AdbCmd @('exec-out','screencap','-p')

# ------------------------------------------------------------------
# [6/6] 抓 flutter 层 EXCEPTION（应为空）+ EventUtils/IssueTimeline warning
#
# 用 exec-out 二进制流避免 PowerShell 重定向的 UTF-16 padding 坑
# ------------------------------------------------------------------
Write-Host '[6/6] dump logcat & classify'
$logPath = Join-Path $OutDir 'logcat_full.txt'
Save-AdbBinary -Path $logPath -AdbCmd @('exec-out','logcat','-d','-b','all','-t','5000')
$logBytes = (Get-Item $logPath).Length
Write-Host "  logcat -> $logPath ($logBytes bytes)"

# 分类计数：注意有的 log tag 里带 "flutter" 只是 SurfaceFlinger 报告的 activity 路径，
# 不是 Dart 侧日志，这里只做粗计。真正判定看 Exception|FATAL 命中的 tag。
$lines = Get-Content -Path $logPath -Encoding UTF8
$unknownWarn = ($lines | Select-String -Pattern 'EventUtils|IssueTimeline' -CaseSensitive:$false | Measure-Object).Count
$flutterExc  = ($lines | Where-Object { $_ -match 'flutter' -and $_ -match '(Exception|FATAL|StackTrace)' } | Measure-Object).Count

Write-Host ''
Write-Host '==== summary ===='
Write-Host "  EventUtils/IssueTimeline warning : $unknownWarn (期望 0，命中说明未收编事件)"
Write-Host "  flutter Exception/FATAL          : $flutterExc (期望 0)"
Write-Host ''
Write-Host '证据文件:'
Get-ChildItem $OutDir | Format-Table Name, Length -AutoSize

if ($unknownWarn -gt 0 -or $flutterExc -gt 0) {
    Write-Warning '有告警命中，请查看 logcat_full.txt / 截图定位。'
    exit 2
}
