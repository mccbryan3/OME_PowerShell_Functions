
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $IpAddress,
    [Parameter(Mandatory)]
    [string] $SessionId,
    [Parameter(Mandatory)]
    [string] $AuthToken
)

$Headers = @{}
$Headers."X-Auth-Token" = $AuthToken
try {
    $SessionUrl  = "https://$($IpAddress)/api/SessionService/Sessions"
    $SessClose = Invoke-WebRequest -Uri "$SessionUrl`(`'$SessionId`'`)" -Method Delete -Headers $Headers -ContentType $Type
} catch {
    "Error: $_"
}