<#
.SYNOPSIS
    Send one JSON-RPC request to a Dart VM Service via WebSocket.

.PARAMETER Uri
    ws:// URI (VM Service http URI -> replace scheme + append 'ws').

.PARAMETER Method
    JSON-RPC method (e.g. getVM, evaluate).

.PARAMETER Params
    Hashtable of params.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Uri,
    [Parameter(Mandatory)][string]$Method,
    [hashtable]$Params = @{}
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http

$ws = New-Object System.Net.WebSockets.ClientWebSocket
$cts = New-Object System.Threading.CancellationTokenSource
$cts.CancelAfter([TimeSpan]::FromSeconds(30))

$ws.ConnectAsync([Uri]$Uri, $cts.Token).GetAwaiter().GetResult() | Out-Null

$payload = @{
    jsonrpc = '2.0'
    id      = 1
    method  = $Method
    params  = $Params
} | ConvertTo-Json -Depth 8 -Compress

$sendBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
$sendSeg = [System.ArraySegment[byte]]::new($sendBytes)
$ws.SendAsync($sendSeg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).GetAwaiter().GetResult() | Out-Null

$buffer = New-Object byte[] 65536
$sb = [System.Text.StringBuilder]::new()
do {
    $seg = [System.ArraySegment[byte]]::new($buffer)
    $result = $ws.ReceiveAsync($seg, $cts.Token).GetAwaiter().GetResult()
    [void]$sb.Append([System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count))
} while (-not $result.EndOfMessage)

$ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, 'done', $cts.Token).GetAwaiter().GetResult() | Out-Null

Write-Output $sb.ToString()
