[CmdletBinding()]
param (
    [Parameter(
        Mandatory=$true
    )]
    [ValidateNotNullOrEmpty()]
    [guid]
    $ClientId,

    [Parameter(
        Mandatory=$true
    )]
    [ValidateNotNullOrEmpty()]
    [string]    
    $Thumbprint,

    [Parameter(
        Mandatory=$true
    )]
    [ValidateNotNullOrEmpty()]
    [guid]    
    $TenantID,

    #Tenant URL in the format https://tenant-admin.sharepoint.com
    [Parameter(
        Mandatory=$false
    )]
    [string]       
    $TenantURL
)

#import-module Microsoft.Online.SharePoint.PowerShell -ErrorAction stop
import-module PnP.PowerShell -ErrorAction Stop
If(!$TenantURL)
{
    $tenant = Read-Host -Prompt "Please provide tenant name/domain"
    #Connect-SPOService -url "https://$tenant-admin.sharepoint.com" -ErrorAction Stop
    Connect-pnponline -url "https://$tenant-admin.sharepoint.com" -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantID -ErrorAction Stop
} else {
    #Connect-SPOService -url $TenantURL -ErrorAction Stop
    Connect-pnponline -url $TenantURL -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantID -ErrorAction Stop
}
$Logfile = ".\InventorySharingForNonOwnersOfSite.csv"
#Header
'URL,Title,PnPSharingForNonOwnersOfSite,SharingCapability,SiteDefinedSharingCapability' | Out-File $Logfile

foreach ($site in (Get-PnPTenantSite -IncludeOneDriveSites))
{
    Write-Output "Connect to $($Site.Url)"
    
    Write-Output "Connect using PnP"
    #Use Azure App Registration, Client certifcate using the thumbprint needs to be installed locally
    Connect-pnponline -url $site.url -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantID
    
    #Alternative useWebLogin but may hang from time to time and user needs dedicated permissions (Site Collection Admin)
    #Connect-pnponline -url $site.url -UseWebLogin
    try {
        if (Get-PnPSite)
        {
            $TenantSite = Get-PnPTenantSite -Identity $site.Url
            "$($Site.Url),$($site.Title),$(Get-PnPSharingForNonOwnersOfSite),$($TenantSite.SharingCapability),$($TenantSite.SiteDefinedSharingCapability)" | Out-file $Logfile -Append
            foreach ($Subweb in Get-PnPSubWeb -Recurse)
            {
                "$($Subweb.ServerRelativeUrl),$($Subweb.Title),$(Get-PnPSharingForNonOwnersOfSite)" |out-file $logfile -append
            }
        }
    }
    catch {
        Write-Output "...Error"
        "$($site.Url),$($site.Title),ERROR" | out-file $logfile -Append
    }
}

Disconnect-PnPOnline