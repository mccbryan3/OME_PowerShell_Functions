    param(
    [Parameter(Mandatory)]
    [string] $IpAddress,
    [Parameter(Mandatory)]
    [pscredential] $Credentials
)

$SessionUrl  = "https://$($IpAddress)/api/SessionService/Sessions"
$Type        = "application/json"
$UserName    = $Credentials.username
$Password    = $Credentials.GetNetworkCredential().password
$UserDetails = @{"UserName"=$UserName;"Password"=$Password;"SessionType"="API"} | ConvertTo-Json
$Headers     = @{}
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

try {
    
    $SessResponse = Invoke-WebRequest -Uri $SessionUrl -Method Post -Body $UserDetails -ContentType $Type
    if ($SessResponse.StatusCode -eq 200 -or $SessResponse.StatusCode -eq 201) {
        $Headers = 
        $obj = New-Object PSObject -Property @{
            SessionId = ($SessResponse | convertfrom-json).Id
            AuthToken = $SessResponse.Headers["X-Auth-Token"]
        }

        $obj
        
    } else {
        Write-Error "Error: Opening Session to ($IpAddress)"
    }

} catch {
    Write-Error "Error Debug: $_"
}