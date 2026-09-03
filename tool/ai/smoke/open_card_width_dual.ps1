<#
.SYNOPSIS
    P2 §1 wrapListChild 卡片限宽三分档冒烟脚本（Windows / PowerShell 7.x）。

.DESCRIPTION
    单次运行内跑三档，验证 GSYAdaptiveNavigation.wrapListChild 的断点行为：

        - compact  (portrait,             ~460dp)  → 卡片顶到左右边缘，无 ConstrainedBox
        - medium   (landscape 原生,        ~872dp) → 卡片被限到 720dp 且水平居中
        - expanded (landscape + density,  ~1440dp) → 卡片仍限 720dp，两侧留白更大

    覆盖场景：首页动态 tab。使用同一 APK 装机，避免 flutter install 抹掉
    fixture 数据（AGENTS.md §"运行时冒烟验证" 禁止行为）。

    产出文件名与 docs/00-overview/roadmap.md P2 §1 及
    docs/06-decisions/ADR-0005 §演进 里引用的证据一一对应：
        p2s1_compact_full_width.png
        p2s1_medium_card_width.png
        p2s1_expanded_card_width.png

.NOTES
    分辨率假设：1080x2400，原生 density ~440dpi。
    expanded 档通过 `wm density 240` 把 1440dp 撑出来；脚本收尾会 `wm density reset`。
    tap / swipe 坐标：Android 7+ `input` 命令走 rotated coordinate，脚本假设 API 25 及以上。
#>
[CmdletBinding()]
param(
    [Alias('Out')]
    [string]$OutDir,
    [string]$Device
)

$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

$PKG = 'com.shuyu.gsygithub.gsygithubappflutter'
$adbArgs = @()
if ($Device) { $adbArgs = @('-s', $Device) }

if (-not $OutDir) {
    $ts = (Get-Date).ToString('yyyyMMdd_HHmm')
    $OutDir = Join-Path $PSScriptRoot "evidence\card_width_$ts"
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Write-Host "[card_width_dual] evidence dir: $OutDir"

function Invoke-AdbSilent {
    & adb @adbArgs @args *>&1 | Out-Null
}

function Save-Screencap {
    param([string]$Path)
    Invoke-AdbSilent shell screencap -p /sdcard/_gsy_smoke.png
    & adb @adbArgs pull /sdcard/_gsy_smoke.png $Path *>&1 | Out-Null
    Invoke-AdbSilent shell rm /sdcard/_gsy_smoke.png
}

# ------------------------------------------------------------------
# [1/7] compact 冷启（竖屏原生 density）
# ------------------------------------------------------------------
Write-Host '[1/7] compact portrait + cold start'
Invoke-AdbSilent shell wm density reset
Invoke-AdbSilent shell settings put system accelerometer_rotation 0
Invoke-AdbSilent shell settings put system user_rotation 0
Invoke-AdbSilent shell am force-stop $PKG
Start-Sleep -Seconds 1
Invoke-AdbSilent shell monkey -p $PKG -c android.intent.category.LAUNCHER 1
Start-Sleep -Seconds 12

# ------------------------------------------------------------------
# [2/7] compact 切 Dynamic tab（首页共 3 个 tab：动态 / 趋势 / 我的）
# 底部 tab 布局：1080/3 = 360 一格。Dynamic tab 是第 1 个（index 0），
# 中心 x ≈ 180。Dynamic 页使用 GSYPullLoadWidget，是本次抽象层落地点。
# ------------------------------------------------------------------
Write-Host '[2/7] compact → dynamic tab, snapshot'
Invoke-AdbSilent shell input tap 180 2280
Start-Sleep -Seconds 3
Save-Screencap -Path (Join-Path $OutDir 'p2s1_compact_full_width.png')

# ------------------------------------------------------------------
# [3/7] 切横屏（medium 档：原生 density，~872dp 宽）
# accelerometer_rotation=1 会让 user_rotation 被自动旋转覆盖，
# 必须先关掉 auto-rotate，再写 user_rotation=1。
# ------------------------------------------------------------------
Write-Host '[3/7] rotate landscape (medium)'
Invoke-AdbSilent shell settings put system accelerometer_rotation 0
Start-Sleep -Milliseconds 300
Invoke-AdbSilent shell settings put system user_rotation 1
Start-Sleep -Seconds 4

# ------------------------------------------------------------------
# [4/7] medium 抓卡片限宽形态
# 横屏 1080 -> 2400 逻辑坐标。滚一屏让卡片区呈现，避开顶部 header。
# ------------------------------------------------------------------
Write-Host '[4/7] medium landscape scroll + snapshot'
Invoke-AdbSilent shell input swipe 1200 800 1200 200 300
Start-Sleep -Seconds 2
Save-Screencap -Path (Join-Path $OutDir 'p2s1_medium_card_width.png')

# ------------------------------------------------------------------
# [5/7] expanded 档：横屏 + wm density 240 撑到 ~1440dp
# 保持 rotation=1，仅缩 density。密度切完 UI 会自动重建。
# ------------------------------------------------------------------
Write-Host '[5/7] expanded landscape (wm density 240) snapshot'
Invoke-AdbSilent shell wm density 240
Start-Sleep -Seconds 5
Invoke-AdbSilent shell input swipe 1200 800 1200 200 300
Start-Sleep -Seconds 2
Save-Screencap -Path (Join-Path $OutDir 'p2s1_expanded_card_width.png')

# ------------------------------------------------------------------
# [6/7] logcat 抓异常
# ------------------------------------------------------------------
Write-Host '[6/7] dump logcat & classify'
$logPath = Join-Path $OutDir 'logcat_full.txt'
& adb @adbArgs logcat -d -b all -t 3000 2>$null | Out-File -FilePath $logPath -Encoding UTF8
$logBytes = (Get-Item $logPath).Length
Write-Host "  logcat -> $logPath ($logBytes bytes)"

$lines = Get-Content -Path $logPath -Encoding UTF8 -ErrorAction SilentlyContinue
$flutterExc = ($lines | Where-Object { $_ -match 'flutter' -and $_ -match '(Exception|FATAL|StackTrace)' } | Measure-Object).Count

# ------------------------------------------------------------------
# [7/7] 复位设备状态：density / rotation / auto-rotate
# 不复位会污染后续会话（AGENTS.md 冒烟规约要求）
# ------------------------------------------------------------------
Write-Host '[7/7] reset device (density + rotation)'
Invoke-AdbSilent shell wm density reset
Invoke-AdbSilent shell settings put system user_rotation 0
Invoke-AdbSilent shell settings put system accelerometer_rotation 1

Write-Host ''
Write-Host '==== summary ===='
Write-Host "  flutter Exception/FATAL : $flutterExc (期望 0)"

Write-Host ''
Write-Host '证据文件:'
Get-ChildItem $OutDir | Format-Table Name, Length -AutoSize

if ($flutterExc -gt 0) {
    Write-Warning '有 flutter 异常命中，请查看 logcat_full.txt。'
    exit 2
}
