<#
.SYNOPSIS
    从首页进入当前登录用户的个人页和仓库列表，并保存 issue #943 的真机证据。

.DESCRIPTION
    2026-08-04 / #943：验证“我的”个人页会打开当前 token 对应的 owner 仓库列表。
    脚本只读取既有 GitHub 数据，不创建仓库或修改远端状态；结束时恢复设备原有旋转设置。

.PARAMETER OutDir
    证据目录。默认写入 tool/ai/smoke/evidence/<当前时间>_issue_943/。

.PARAMETER Device
    传给 adb -s 的设备 id。多设备时必须显式传入。

.PARAMETER KeepAttach
    保留 flutter run attach，不 force-stop；代价是无法保证导航栈从首页开始。

.PARAMETER ExpectedFirstRepository
    可选。断言仓库列表第一项是指定仓库，并继续验证其动态、详情、ISSUE、文件四个 tab。
    适合传入刚刚 push、按 pushed 排序位于首项的私有 fixture。

.NOTES
    坐标已在 1080x2400 / Android 33 真机校准：底部“我的” (785, 2260)，
    个人页“仓库”计数入口 (110, 1000)。禁止用 flutter install，装机请用 adb install -r。
#>
[CmdletBinding()]
param(
    [Alias('Out')]
    [string]$OutDir,
    [string]$Device,
    [switch]$KeepAttach,
    [string]$ExpectedFirstRepository
)

$ErrorActionPreference = 'Stop'
$packageName = 'com.shuyu.gsygithub.gsygithubappflutter'
$adbPrefix = @()
if ($Device) { $adbPrefix = @('-s', $Device) }

if (-not $OutDir) {
    $timestamp = (Get-Date).ToString('yyyyMMdd_HHmm')
    $OutDir = Join-Path $PSScriptRoot "evidence\${timestamp}_issue_943"
}
$OutDir = [IO.Path]::GetFullPath($OutDir)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Invoke-Adb {
    & adb ($adbPrefix + $args)
}

function Save-AdbBinary {
    param([string]$Path, [string[]]$AdbCmd)
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = 'adb'
    $processInfo.RedirectStandardOutput = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    foreach ($argument in $adbPrefix) {
        $processInfo.ArgumentList.Add($argument)
    }
    foreach ($argument in $AdbCmd) {
        $processInfo.ArgumentList.Add($argument)
    }
    $process = [System.Diagnostics.Process]::Start($processInfo)
    $memory = New-Object System.IO.MemoryStream
    $process.StandardOutput.BaseStream.CopyTo($memory)
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) {
        throw "adb command failed ($($process.ExitCode)): $($AdbCmd -join ' ')"
    }
    [IO.File]::WriteAllBytes($Path, $memory.ToArray())
}

function Save-UiState {
    param([string]$Stem)
    Save-AdbBinary -Path (Join-Path $OutDir "$Stem.png") -AdbCmd @('exec-out', 'screencap', '-p')
    $remoteXml = "/sdcard/gsy_943_$Stem.xml"
    Invoke-Adb shell uiautomator dump $remoteXml | Out-Null
    Invoke-Adb pull $remoteXml (Join-Path $OutDir "$Stem.xml") | Out-Null
}

$devicesRaw = & adb ($adbPrefix + @('devices')) 2>&1
$onlineDevices = @($devicesRaw | Where-Object { $_ -match '^\S+\s+device$' })
if ($onlineDevices.Count -eq 0) {
    throw 'adb 未检测到在线设备，请先运行 adb devices'
}
$resolvedDevice = if ($Device) {
    $Device
} else {
    ($onlineDevices[0] -split '\s+')[0]
}

$originalAccelerometerRotation = (Invoke-Adb shell settings get system accelerometer_rotation | Out-String).Trim()
$originalUserRotation = (Invoke-Adb shell settings get system user_rotation | Out-String).Trim()

try {
    Write-Host "[open_my_repositories] evidence: $OutDir"
    Invoke-Adb shell settings put system accelerometer_rotation 0 | Out-Null
    Invoke-Adb shell settings put system user_rotation 0 | Out-Null
    Invoke-Adb shell wm user-rotation lock 0 | Out-Null

    if (-not $KeepAttach) {
        Invoke-Adb shell am force-stop $packageName | Out-Null
        Start-Sleep -Seconds 1
    }
    Invoke-Adb shell monkey -p $packageName -c android.intent.category.LAUNCHER 1 2>&1 | Out-Null
    Start-Sleep -Seconds 12
    Save-AdbBinary -Path (Join-Path $OutDir '01_home.png') -AdbCmd @('exec-out', 'screencap', '-p')

    Invoke-Adb logcat -c | Out-Null
    Invoke-Adb shell input tap 785 2260 | Out-Null
    Start-Sleep -Seconds 6
    Save-UiState '02_my_profile'

    Invoke-Adb shell input tap 110 1000 | Out-Null
    Start-Sleep -Seconds 10
    Save-UiState '03_authenticated_repositories'

    $firstRepository = ''
    [xml]$repositoryTree = Get-Content (Join-Path $OutDir '03_authenticated_repositories.xml') -Raw
    $repositoryButtons = $repositoryTree.SelectNodes('//node[@class="android.widget.Button"]')
    foreach ($button in $repositoryButtons) {
        $parts = $button.GetAttribute('content-desc') -split "`n"
        if ($parts.Count -ge 5 -and $parts[0] -ne '返回') {
            $firstRepository = $parts[0]
            break
        }
    }

    if ($ExpectedFirstRepository) {
        if ($firstRepository -ne $ExpectedFirstRepository) {
            throw "仓库首项不是 '$ExpectedFirstRepository'，实际为 '$firstRepository'；请先确认 pushed 排序或重新校准脚本"
        }

        Invoke-Adb shell input tap 500 430 | Out-Null
        Start-Sleep -Seconds 12
        Save-UiState '07_private_repository_detail'

        Invoke-Adb shell input tap 405 320 | Out-Null
        Start-Sleep -Seconds 10
        Save-UiState '08_private_repository_info'

        Invoke-Adb shell input tap 675 320 | Out-Null
        Start-Sleep -Seconds 10
        Save-UiState '09_private_repository_issues'

        Invoke-Adb shell input tap 945 320 | Out-Null
        Start-Sleep -Seconds 10
        Save-UiState '10_private_repository_files'
    }

    $appPid = (Invoke-Adb shell pidof $packageName | Out-String).Trim()
    $logArgs = @('exec-out', 'logcat', '-d', '-v', 'threadtime')
    if ($appPid) { $logArgs += "--pid=$appPid" }
    $logPath = Join-Path $OutDir '04_app_logcat.txt'
    Save-AdbBinary -Path $logPath -AdbCmd $logArgs

    $appErrors = Get-Content $logPath -Encoding UTF8 |
        Where-Object { $_ -match '(FATAL EXCEPTION|Dart Error|Unhandled Exception|E/flutter|FlutterError)' }
    $summary = @(
        "device=$resolvedDevice"
        "package=$packageName"
        "app_pid=$appPid"
        "runtime_error_count=$($appErrors.Count)"
        "first_repository=$firstRepository"
        "read_paths_repository=$ExpectedFirstRepository"
        "rotation_before_accelerometer=$originalAccelerometerRotation"
        "rotation_before_user=$originalUserRotation"
    )
    $summary | Set-Content (Join-Path $OutDir '05_summary.txt') -Encoding UTF8

    Get-ChildItem $OutDir | Format-Table Name, Length -AutoSize
    if ($appErrors.Count -gt 0) {
        throw "检测到 $($appErrors.Count) 条 app runtime error，请检查 04_app_logcat.txt"
    }
} finally {
    if ($originalAccelerometerRotation -match '^\d+$') {
        Invoke-Adb shell settings put system accelerometer_rotation $originalAccelerometerRotation | Out-Null
    }
    if ($originalUserRotation -match '^\d+$') {
        Invoke-Adb shell settings put system user_rotation $originalUserRotation | Out-Null
    }
    if ($originalAccelerometerRotation -eq '1') {
        Invoke-Adb shell wm user-rotation free | Out-Null
    }
}
