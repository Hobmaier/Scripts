<#

.SYNOPSIS
Collect System Information

.DESCRIPTION
Use this script to collect system information about OS, installed Software and SharePoint

.EXAMPLE
Get-SystemInformation.ps1 -Logfile C:\Temp\Webserver.txt

.NOTES
All examples based on SharePoint with dependency on AD, SQL, SharePoint, Mailserver, Office Online...

#>

# Specifies a path to one or more locations. Unlike the Path parameter, the value of the Logfile parameter is
# used exactly as it is typed. No characters are interpreted as wildcards. If the path includes escape characters,
# enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any
# characters as escape sequences.
param(
    [Parameter(Mandatory=$true,
            Position=0,
            ParameterSetName="Logfile",
            ValueFromPipelineByPropertyName=$true,
            HelpMessage="Logfile path to one locations.")]
    [Alias("PSPath")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Logfile
)

### Don't change beyond this line
Function Get-SharePointInfo
{
    $farm = Get-SPFarm -ErrorAction SilentlyContinue
    If ($farm)
    {
        $farm.buildversion | Out-File $Logfile -Append
        $farm.solutions  | Out-File $Logfile -Append
        $farm.NeedsUpgrade  | Out-File $Logfile -Append
        $farm.servers | Out-File $Logfile -Append
        Get-SPContentDatabase | ForEach-Object -Process {
            $_.DisplayName | Out-File $Logfile -Append
            $_.DiskSizeRequired | Out-File $Logfile -Append
            $_.RemoteBlobStorageSettings | Out-File $Logfile -Append
        }
    }
}

Get-CimInstance Win32_OperatingSystem | Select-Object  Caption, InstallDate, ServicePackMajorVersion, OSArchitecture, BootDevice,  BuildNumber, CSName | Out-File $Logfile
Get-CimInstance CIM_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory | Out-File $Logfile -Append
Get-CimInstance CIM_BIOSElement | Select-Object SerialNumber | Out-File $Logfile -Append
Get-CimInstance CIM_Processor | Select-Object Name | Out-File $Logfile -Append
Get-CimInstance Win32_LogicalDisk | Select-Object DeviceID, DriveType, VolumeName, Size, FreeSpace, ProviderName | Out-File $Logfile -Append
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion, Publisher, InstallDate | Out-File $Logfile -Append

if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
    #Verify if on SharePoint
    if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -Registered -ErrorAction SilentlyContinue))
    { 
        Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue
        Get-SharePointInfo
    }
} else {
    #Already loaded
    Get-SharePointInfo
}

