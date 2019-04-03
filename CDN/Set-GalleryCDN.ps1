#This script will add explicit lists to public CDN
# Requires
# - SPO PowerShell
# - SPO Admin permissions
# - relative URL of all lists you would like to add (these should contain images, js...)


$tenant = 'mustermann' #tenant URL e.g. contoso-admin.sharepoint.com = contoso
#Provide all lists as an array, separated by , and line break with `
$lists = @(
    "/sites/app_picturegallery/list1", `
    "/sites/app_picturegallery/list2"
    )

#Login


import-module microsoft.online.sharepoint.powershell -ErrorAction Stop

Connect-SPOService -Url https://$tenant-admin.sharepoint.com


#Display current CDN config
Write-Host 'Currently CDN status Public: ' (Get-SPOTenantCdnEnabled -CdnType Public).value
Write-Host 'Current CDN Public configuration'
Get-SPOTenantCdnOrigins -CdnType Public

#Set the array to the lists URL relative path

    foreach ($list in $lists)
    {
        Add-SPOTenantCdnOrigin -CdnType Public -OriginUrl $list
    }
Write-Host 'Done'