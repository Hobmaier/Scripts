import-module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
$tenant = Read-Host -Prompt "Please provide tenant name/domain"
Connect-SPOService -url "https://$tenant-admin.sharepoint.com" -ErrorAction Stop
$scadmin = Read-Host -Prompt "Please provide Site Collection Administrator UPN e.g. alans@contoso.com to add to every site collection"
foreach ($site in Get-SPOSite -Limit All)
{
    try {
        Set-SPOUser -site $site -LoginName $scadmin -IsSiteCollectionAdmin $true
    }
    catch {
        if ($Error[0].Exception -like "(503)")
        {
            { 
                # The remote server returned an error: (503) Server Unavailable.
                Write-Output "Try again in 10s"
                Start-Sleep -Seconds 10
                Set-SPOUser -site $site -LoginName $scadmin -IsSiteCollectionAdmin $true
                $error.Clear()
            }
            else {
                Write-Output "Failed: $($Error[0])"
                Write-Output "Try again"
                Start-Sleep -Seconds 5
                Set-SPOUser -site $site -LoginName $scadmin -IsSiteCollectionAdmin $true
            }
        }
    }
    
}
