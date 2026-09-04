<#
Convenience wrapper: evaluate a Dart expression through Dart VM Service.
Usage:
    vm_eval.ps1 -Uri ws://... -IsolateId ... -TargetId ... -Expression "gsySmokeGoReposDetail(\"CarGuo\",\"gsy_github_app_flutter\")"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Uri,
    [Parameter(Mandatory)][string]$IsolateId,
    [Parameter(Mandatory)][string]$TargetId,
    [Parameter(Mandatory)][string]$Expression
)

$scriptDir = Split-Path -Parent $PSCommandPath
$rpc = Join-Path $scriptDir 'vm_rpc.ps1'

& $rpc -Uri $Uri -Method evaluate -Params @{
    isolateId  = $IsolateId
    targetId   = $TargetId
    expression = $Expression
}
