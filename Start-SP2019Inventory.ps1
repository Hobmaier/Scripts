Add-PSSnapin Microsoft.SharePoint.PowerShell
import-module sharepointpnppowershell2019 -ErrorAction Stop

$Logfile = "C:\temp\report.csv"
#Header
'URL,Title,Template,Count,StorageUsageCurrent' | Out-File $Logfile

foreach ($site in (Get-SPSite -Limit All))
{
    Write-Output "Connect to $($Site.Url)"
    "$($Site.Url),$($site.Title),$($site.template),$($site.WebsCount),$($site.storageUsageCurrent)" | Out-file $Logfile -Append
    Write-Output "Connect using PnP"
    Connect-pnponline -url $site.url -CurrentCredentials
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