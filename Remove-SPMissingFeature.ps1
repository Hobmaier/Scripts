[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint") > 0
 # Loading Microsoft.SharePoint.PowerShell 
 $snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.Powershell'}
 if ($snapin -eq $null) {
 Write-Host "Loading SharePoint Powershell Snapin"
Add-PSSnapin "Microsoft.SharePoint.Powershell"}

# Run Get-SQLMissingFeature before

# This will remove Site Feature (assuming web ID is 00000...)

$site = Get-SPSite -Limit All | ? { $_.Id -eq "2FA6DECD-CB80-4AF3-A596-B01AED452B3E" }
$siteFeature = $site.Features["b87a461b-3c29-47c4-97dd-40ee561da740"]
$site.Features.Remove($siteFeature.DefinitionId, $true)


# This will remove 
$site = Get-SPSite -Limit all | where { $_.Id -eq “A0DBD1E3-C516-42BC-B5F9-EA49A89748C2” }  
$web = $site | Get-SPWeb -Limit all | where { $_.Id -eq "6581EFF5-35F1-4973-8304-E3FC48014CE8"  }
$webFeature = $web.Features["51592816-393C-4C9F-B6A3-EEFBA9A65173"]
$web.Features.Remove($webFeature.DefinitionId, $true)


# Maybe another option, but from my expirience it leaves a stale entry in DB
stsadm -o uninstallfeature -id b87a461b-3c29-47c4-97dd-40ee561da740 -force 

