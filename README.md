# OME_PowerShell_Functions

Credentials should be provided to get and set scripts as Powershell credential objects.

These can be gathered by using Get-Credentials with a prompt prior to execution or by providing them from outside with something similar to the process linked below.

[providing encrypted powershell credentials to job scripts](https://gist.github.com/mccbryan3/cf7464fbb476cf81973a8202292e0a17)

## Open-OMESession.ps1

This script function opens an api session with OME to keep for the life of the get and set scripts.

This allows multiple api calls in the same script without resubmitting credentials.

## Close-OMESession.ps1

This script function safely closes an api session with OME and should run at the end of every get or set function script.

## Get and Set Function scripts

```
NAME

Get-OMEDevice.ps1

SYNOPSIS

This function will retrieve device details from the OME API based on DeviceName or DeviceServiceTag

DeviceName is the default parameter set and will be prompted if not provided. You may also provide the service tag to the function which will negate the need for the default parameter set.

SYNTAX

Get-OMEDevice.ps1 [-IPAddress] <String> [-DeviceName] <String> [-DeviceSVCTag] <String> [-Credentials] <PSCredentials>

PARAMETERS

    -IpAddress 
    
    <String> Mandatory - IP or resolvable name of the OME Server
        
    -DeviceName
    
    <String> Mandatory - Must be provided if no DeviceSVCTag is proivided and is the default parameter between the two. This can also be partial name which may return multiple devices.
    
    -DeviceSVCTag
    
    <String> Mandatory - Must be provided if no DeviceSVCTag is proivided and is the default parameter between the two.
    
    -Credentials
    
    <PSCredentials> Mandatory
    
EXAMPLES

Example with -DeviceName paramater 

.\Get-OMEDevice.ps1 -IpAddress ome.lab.loc -DeviceName <full or partial devicename attribute> -Credentials $(Get-Credential)

Example with -DeviceSVCTag paramater 

.\Get-OMEDevice.ps1 -IpAddress ome.lab.loc -DeviceSVCTag <servicetag> -Credentials $(Get-Credential)

RETURN

DeviceName   : 
Model        : 
DnsName      : 
iDracAddress : 
iDracMac     : 
ServiceTag   : 
ServerMacs   : 

```
