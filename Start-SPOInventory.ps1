import-module Microsoft.Online.SharePoint.PowerShell -ErrorAction stop
import-module sharepointpnppowershellonline
$tenant = Read-Host -Prompt "Please provide tenant name/domain"
Connect-SPOService -url "https://$tenant-admin.sharepoint.com" -ErrorAction Stop
Connect-pnponline -url "https://$tenant-admin.sharepoint.com" -UseWebLogin -ErrorAction Stop
$Logfile = "C:\temp\report.csv"
#Header
'URL,Title,Template,Count,StorageUsageCurrent' | Out-File $Logfile

foreach ($site in (Get-SPOSite -Limit All))
{
    Write-Output "Connect to $($Site.Url)"
    "$($Site.Url),$($site.Title),$($site.template),$($site.WebsCount),$($site.storageUsageCurrent)" | Out-file $Logfile -Append
    Write-Output "Connect using PnP"
    Connect-pnponline -url $site.url -UseWebLogin
    try {
        if (Get-PnPSite)
        {
            foreach ($list in (Get-PnPList))
            {
                "$($list.ParentWebUrl),$($list.Title),LIST,$($list.itemcount)" |out-file $logfile -append
            }
        }
    }
    catch {
        Write-Output "...Error"
        "$($site.Url),$($site.Title),ERROR" | out-file $logfile -Append
    }
}