param(
    [string]$BaseRef = "HEAD",
    [string]$OutFile = "build/ai/review-bundle.md"
)

$ErrorActionPreference = "Stop"

function Require-GitRepository {
    git rev-parse --show-toplevel *> $null
    if ($LASTEXITCODE -ne 0) {
        throw "Current directory is not a git repository."
    }
}

function Get-ChangedFiles {
    $files = git diff --name-only $BaseRef
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to get changed files from git diff."
    }
    return @($files | Where-Object { $_ -and $_.Trim().Length -gt 0 })
}

function Ensure-ParentDirectory([string]$Path) {
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}

function Format-BulletList([string[]]$Items, [string]$Fallback) {
    if (-not $Items -or $Items.Count -eq 0) {
        return "- $Fallback"
    }

    return (($Items | ForEach-Object { "- " + $_ }) -join ([Environment]::NewLine))
}

Require-GitRepository

$changedFiles = Get-ChangedFiles
$diffStat = git diff --stat $BaseRef | Out-String
$diffText = git diff --unified=3 $BaseRef | Out-String
$shortHead = (git rev-parse --short HEAD).Trim()

$featureHints = @()
foreach ($file in $changedFiles) {
    switch -Regex ($file) {
        '^lib/page/repos/' { $featureHints += 'repos'; break }
        '^lib/page/trend/' { $featureHints += 'trend'; break }
        '^lib/page/notify/' { $featureHints += 'notify'; break }
        '^lib/page/issue/' { $featureHints += 'issue'; break }
        '^lib/page/search/' { $featureHints += 'search'; break }
        '^lib/page/user/' { $featureHints += 'user'; break }
        '^lib/page/home/' { $featureHints += 'home'; break }
        '^lib/page/dynamic/' { $featureHints += 'dynamic'; break }
        '^lib/page/release/' { $featureHints += 'release'; break }
        '^lib/page/push/' { $featureHints += 'push'; break }
        '^lib/page/debug/' { $featureHints += 'debug'; break }
        '^lib/common/net/' { $featureHints += 'common-net'; break }
        '^lib/redux/' { $featureHints += 'redux'; break }
        '^lib/provider/' { $featureHints += 'provider'; break }
    }
}

$featureHints = $featureHints | Sort-Object -Unique
$changedFilesText = Format-BulletList -Items $changedFiles -Fallback "(none)"
$featureHintsText = Format-BulletList -Items $featureHints -Fallback "general"

$lines = @(
    "# Review Bundle",
    "",
    "- Head: $shortHead",
    "- Base ref: $BaseRef",
    "- Reviewer prompt: docs/05-ai/prompts/reviewer-system.md",
    "- Review harness: docs/05-ai/review-harness.md",
    "",
    "## Changed Files",
    "",
    $changedFilesText,
    "",
    "## Feature Hints",
    "",
    $featureHintsText,
    "",
    "## Recommended Docs",
    "",
    "- AGENTS.md",
    "- docs/CONTRIBUTING_AI.md",
    "- docs/04-quality/smoke-matrix.md",
    "- docs/05-ai/task-playbooks/fix-bug.md",
    "",
    "## Diff Stat",
    "",
    '```text',
    $diffStat.TrimEnd(),
    '```',
    "",
    "## Diff",
    "",
    '```diff',
    $diffText.TrimEnd(),
    '```'
)

$bundle = ($lines -join ([Environment]::NewLine))

Ensure-ParentDirectory $OutFile
Set-Content -Path $OutFile -Value $bundle -Encoding UTF8

Write-Output ('Review bundle written to ' + $OutFile)
