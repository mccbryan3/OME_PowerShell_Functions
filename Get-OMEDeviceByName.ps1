[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $IpAddress,
    [Parameter(Mandatory)]
    [string] $Name,
    [Parameter(Mandatory)]
    [pscredential] $Credentials
)

function Set-CertPolicy() {
## Trust all certs - for sample usage only
Try {
add-type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    Catch {
        # Write-Error "Unable to add type for cert policy"
    }

}

Set-CertPolicy

$Session = .\Open-OMESession.ps1 -IPAddress $IPAddress -Credentials $Credentials

$DeviceUrl   = "https://$($IpAddress)/api/DeviceService/Devices?`$filter=DeviceName eq '$($Name)'"
$Type        = "application/json"
$Headers     = @{}
$Headers."X-Auth-Token" = $Session.AuthToken

try {
    $DevResp = Invoke-WebRequest -Uri $DeviceUrl -UseBasicParsing -Method Get -Headers $Headers -ContentType $Type
    $PSContent_Device = ($DevResp | ConvertFrom-Json).Value
} catch { 
    Write-Error "Error: $_"
}

$inventory_link = ($PSContent_Device).'InventoryDetails@odata.navigationLink'
$DeviceInventoryUrl   = "https://$($IpAddress)/$inventory_link('serverNetworkInterfaces')"

try {
    $DevResp = Invoke-WebRequest -Uri $DeviceInventoryUrl -UseBasicParsing -Method Get -Headers $Headers -ContentType $Type
    $Network_DeviceMac = (($DevResp.Content | ConvertFrom-Json).InventoryInfo.Ports | Select -First 1).Partitions.CurrentMacAddress
} catch { 
    Write-Error "Error: $_"
}

$Network_DeviceMac

$PSContent_Device | Select DeviceName,Model,@{N="DnsName";E={$_.DeviceManagement.DnsName}},`
    @{N="NetworkAddress";E={$_.DeviceManagement.NetworkAddress}}, `
    @{N="iDracMac";E={$_.DeviceManagement.MacAddress}},  `
    @{N="ServerFirstMac";E={$Network_DeviceMac}}

.\Close-OMESession.ps1 -IPAddress $IPAddress -SessionId $Session.SessionId -AuthToken $Session.AuthToken
