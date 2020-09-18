[CmdletBinding(DefaultParameterSetName='DeviceName')]
param(
    [Parameter(Mandatory)]
    [string] $IpAddress,
    [Parameter(Mandatory, ParameterSetName='DeviceName' )]
    [string] $DeviceName,
    [Parameter(Mandatory, ParameterSetName='ServiceTag' )]
    [string] $DeviceSVCTag,
    [Parameter(Mandatory)]
    [pscredential] $Credentials
)

if($DeviceName) {
    $device_filter = "DeviceName"
    $filter_text = $DeviceName
} elseif($DeviceSVCTag) {
    $device_filter = "DeviceServiceTag"
    $filter_text = $DeviceSVCTag
}

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
        "$Error[0]`n`nUnable to add type for cert policy";exit
    }

}

Set-CertPolicy

$Session = .\Open-OMESession.ps1 -IPAddress $IPAddress -Credentials $Credentials

$DeviceUrl   = "https://$($IpAddress)/api/DeviceService/Devices?`$filter=$device_filter eq '$($filter_text)'"
$Type        = "application/json"
$Headers     = @{}
$Headers."X-Auth-Token" = $Session.AuthToken

try {
    $DevResp = Invoke-WebRequest -Uri $DeviceUrl -UseBasicParsing -Method Get -Headers $Headers -ContentType $Type
    $PSContent_Devices = ($DevResp | ConvertFrom-Json).Value
} catch { 
    Write-Error "Error: $Error[0]"
}

foreach ($PSContent_Device  in $PSContent_Devices) {
    
    $inventory_link = ($PSContent_Device).'InventoryDetails@odata.navigationLink'
    $DeviceInventoryUrl   = "https://$($IpAddress)/$inventory_link('serverNetworkInterfaces')"

    try {
        $DevResp = Invoke-WebRequest -Uri $DeviceInventoryUrl -UseBasicParsing -Method Get -Headers $Headers -ContentType $Type
        $Network_DeviceMac = (($DevResp.Content | ConvertFrom-Json).InventoryInfo.Ports).Partitions.CurrentMacAddress
    } catch { 
        Write-Error "Error: $Error[0]"
    }

    $PSContent_Device | Select-Object DeviceName,Model, `
        @{N="DnsName";E={$_.DeviceManagement.DnsName}},`
        @{N="iDracAddress";E={$_.DeviceManagement.NetworkAddress}}, `
        @{N="iDracMac";E={$_.DeviceManagement.MacAddress}},  `
        @{N="ServiceTag";E={$_.DeviceServiceTag}},  `
        @{N="ServerMacs";E={$Network_DeviceMac}}

}
.\Close-OMESession.ps1 -IPAddress $IPAddress -SessionId $Session.SessionId -AuthToken $Session.AuthToken
