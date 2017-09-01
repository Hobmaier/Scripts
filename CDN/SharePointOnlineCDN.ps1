#Change this line to your tenant URL prefix, e.g. in case abc.sharepoint.com it will be abc
$tenant = 'mustermann'

import-module microsoft.online.sharepoint.powershell
get-command -Module Microsoft.Online.SharePoint.PowerShell

Connect-SPOService -Url https://$tenant-admin.sharepoint.com

#Check current status (off by default)
Get-SPOTenantCdnEnabled -CdnType Public
Get-SPOTenantCdnEnabled -CdnType Private


#Enable CDN (public and private - see Blog for explanation)

Set-SPOTenantCdnEnabled -CdnType Public
#Public CDN enabled locations:
#*/MASTERPAGE (configuration pending)
#*/STYLE LIBRARY (configuration pending)

Set-SPOTenantCdnEnabled -CdnType Private
#Private CDN enabled locations:
#*/USERPHOTO.ASPX (configuration pending)
#*/SITEASSETS (configuration pending)

#(configuration pending) = up to 15 minutes until it will be active

# Add new CDN origin, so a list, library, folder which should be cached within the CDN
# * wildcard can be used in front, if not list, library, folder must exist
Add-SPOTenantCdnOrigin -CdnType Public -OriginUrl */Publishingimages
Add-SPOTenantCdnOrigin -CdnType Private -OriginUrl /sites/Publishing297/SalesDashboard #specific Library in specific Site Collection

#Display CDN origins
Get-SPOTenantCdnOrigins -CdnType Public
Get-SPOTenantCdnOrigins -CdnType Private

#Remove CDN origin
Remove-SPOTenantCdnOrigin -CdnType Public -OriginUrl */Publishingimages
remove-SPOTenantCdnOrigin -CdnType Private -OriginUrl /sites/Publishing297/SalesDashboard

#Disable CDN in the tenant
Set-SPOTenantCdnEnabled -CdnType Public -Enable $false #up to 24h until cache expires
Set-SPOTenantCdnEnabled -CdnType Private -Enable $false #up to 1h until cache expires

#Get default configuration of your public CDN settings
Get-SPOTenantCdnPolicies -CdnType Public
Get-SPOTenantCdnPolicies -CdnType Private
<#
#Public - default configuration
                                 Key Value
                                 --- -----
               IncludeFileExtensions CSS,EOT,GIF,ICO,JPEG,JPG,JS,MAP,PNG,SVG,TTF,WOFF
ExcludeRestrictedSiteClassifications
           ExcludeIfNoScriptDisabled False

 #Private - default configuration
                                  Key Value
                                 --- -----
               IncludeFileExtensions GIF,ICO,JPEG,JPG,JS,PNG
ExcludeRestrictedSiteClassifications
           ExcludeIfNoScriptDisabled False
#>
