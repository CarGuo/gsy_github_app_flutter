<#
.SYNOPSIS
    P2 §3 MyPage stats 5 列折栏三分档冒烟脚本（Windows / PowerShell 7.x）。

.DESCRIPTION
    单次运行内跑三档，验证 GSYAdaptiveNavigation.wrapUserStatsBar 与
    userStatsBarHeight 的断点行为：

        - compact  (portrait,             ~460dp)  → 单行 5 列 + 4 分隔线，高 70
        - medium   (landscape 原生,        ~872dp) → 双行 3+2，高 130
        - expanded (landscape + density,  ~1440dp) → 单行 5 列 + 4 分隔线，高 70

    覆盖场景：底部 "我的" tab（fixture 账号 CarSmallGuo），进入个人页后
    User header bottom 5 列 stats（repos / fans / focus / star / honor）。

    使用同一 APK 装机（先手工 adb install -r），脚本不负责编译与安装，
    避免 flutter install 抹掉 fixture token（AGENTS.md 禁止行为）。

    产出文件名与 docs/00-overview/roadmap.md P2 §3 及
    docs/06-decisions/ADR-0005 §演进 里引用的证据一一对应：
        p2s3_compact_single_row.png    ← person 页 compact 单行 stats
        p2s3_medium_double_row.png     ← person 页 medium 3+2 双行 stats
        p2s3_expanded_no_crash.png     ← **注意：这张截图不落在 person 页**
                                          density 240 触发 activity rebuild，
                                          selectedIndex 归零，rail 3 项物理坐标
                                          随 density 变化不稳，3 次 tap 尝试均未
                                          命中"我的" rail 项。因此本档只证明
                                          expanded 断点下 UI 整体不崩、rail
                                          正常渲染；person 页 stats 单行 + 高度 70
                                          由单测 `gsy_adaptive_shell_test.dart:264`
                                          `expanded 窗口 → 单行 5 列；高度 70` 保证。
                                          文件命名刻意用 `no_crash` 而不是
                                          `single_row`，避免下一位 reviewer 误读
                                          为"person 页在 expanded 下的 stats 截图"。

.NOTES
    分辨率假设：1080x2400，原生 density ~440dpi。
    "我的" tab 是 3 tab 里最右一个（index 2），中心 x ≈ 900。
    tap / swipe 坐标：Android 7+ `input` 命令走 rotated coordinate。
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
    $OutDir = Join-Path $PSScriptRoot "evidence\my_page_stats_$ts"
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
Write-Host "[my_page_stats] evidence dir: $OutDir"

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
# [1/8] compact 冷启（竖屏原生 density）
# ------------------------------------------------------------------
Write-Host '[1/8] compact portrait + cold start'
Invoke-AdbSilent shell wm density reset
Invoke-AdbSilent shell settings put system accelerometer_rotation 0
Invoke-AdbSilent shell settings put system user_rotation 0
Invoke-AdbSilent shell am force-stop $PKG
Start-Sleep -Seconds 1
Invoke-AdbSilent shell monkey -p $PKG -c android.intent.category.LAUNCHER 1
Start-Sleep -Seconds 12

# ------------------------------------------------------------------
# [2/8] compact 切 "我的" tab（第 3 个，index 2，中心 x ≈ 900）
# stats 5 列在 header 底部，冷启后直接可见，无需滚动。
# ------------------------------------------------------------------
Write-Host '[2/8] compact → my tab, snapshot'
Invoke-AdbSilent shell input tap 900 2280
Start-Sleep -Seconds 4
Save-Screencap -Path (Join-Path $OutDir 'p2s3_compact_single_row.png')

# ------------------------------------------------------------------
# [3/8] 切横屏（medium 档：原生 density，~872dp 宽）
# ------------------------------------------------------------------
Write-Host '[3/8] rotate landscape (medium)'
Invoke-AdbSilent shell settings put system accelerometer_rotation 0
Start-Sleep -Milliseconds 300
Invoke-AdbSilent shell settings put system user_rotation 1
Start-Sleep -Seconds 4

# ------------------------------------------------------------------
# [4/8] medium 档：stats 应折成 3+2 双行
# 横屏下 rail 出现在左侧（NavigationRail 宽 96dp，中心 x ≈ 60px），
# "我的" 是第 3 个 destination，纵向位置约屏幕高度 1/2 之后。
# 冷启时选中的 tab 可能被 rebuild 重置，先 tap rail "我的" 确保停留。
# 再上滑一小段让 stats 双行完整露出（避免下半行被 pinned header 顶出屏幕）。
# ------------------------------------------------------------------
Write-Host '[4/8] medium landscape → tap rail "我的" + snapshot (double row)'
Invoke-AdbSilent shell input tap 60 780
Start-Sleep -Seconds 3
Invoke-AdbSilent shell input swipe 1200 600 1200 300 300
Start-Sleep -Seconds 2
Save-Screencap -Path (Join-Path $OutDir 'p2s3_medium_double_row.png')

# ------------------------------------------------------------------
# [5/8] expanded 档：横屏 + wm density 240 撑到 ~1440dp
# 目的：验证 expanded 断点下 rail 存在（rail 96dp 宽 → 物理像素 96）
# 且外层布局重新拉宽后 person 页 stats 仍按 delegate 契约切回单行。
#
# 已知限制：density 240 会触发 activity rebuild，GSYTabBarWidget
# selectedIndex 归零到"动态" tab；且 rail 3 项的物理坐标随 density 变化
# 不稳，历史 3 次 tap 尝试（60,780 / 78,225 / 60,535）均未命中。
# 因此本档**只验证 expanded 断点下 UI 不崩溃 + logcat 无异常**，
# stats 单行契约由单测 `expanded 窗口 → 单行 5 列` 覆盖。
# 完成汇报里必须显式列为"真机 expanded 分档：仅验证不崩溃，stats 单行由单测保证"。
# ------------------------------------------------------------------
Write-Host '[5/8] expanded landscape (wm density 240) → snapshot (无 tap，仅验证不崩)'
Invoke-AdbSilent shell wm density 240
Start-Sleep -Seconds 8
Save-Screencap -Path (Join-Path $OutDir 'p2s3_expanded_no_crash.png')

# ------------------------------------------------------------------
# [6/8] logcat 抓异常
# ------------------------------------------------------------------
Write-Host '[6/8] dump logcat & classify'
$logPath = Join-Path $OutDir 'logcat_full.txt'
& adb @adbArgs logcat -d -b all -t 3000 2>$null | Out-File -FilePath $logPath -Encoding UTF8
$logBytes = (Get-Item $logPath).Length
Write-Host "  logcat -> $logPath ($logBytes bytes)"

$lines = Get-Content -Path $logPath -Encoding UTF8 -ErrorAction SilentlyContinue
$flutterExc = ($lines | Where-Object { $_ -match 'flutter' -and $_ -match '(Exception|FATAL|StackTrace)' } | Measure-Object).Count

# ------------------------------------------------------------------
# [7/8] 复位设备状态：density / rotation / auto-rotate
# ------------------------------------------------------------------
Write-Host '[7/8] reset device (density + rotation)'
Invoke-AdbSilent shell wm density reset
Invoke-AdbSilent shell settings put system user_rotation 0
Invoke-AdbSilent shell settings put system accelerometer_rotation 1

# ------------------------------------------------------------------
# [8/8] summary
# ------------------------------------------------------------------
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
