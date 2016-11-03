# Dennis Hobmaier
# Version 1.0
# 30.12.2014


# Loading Microsoft.SharePoint.PowerShell 
$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.Powershell'}
if ($snapin -eq $null) {
Write-Host "Loading SharePoint Powershell Snapin"
Add-PSSnapin "Microsoft.SharePoint.Powershell"
}

#Variable Section
$themeName = "Red" #Theme Name which should be applied
$themeRelativeURL = "_catalogs/theme/15/palette022.spcolor"
#$FontRelativeURL = "_catalogs/theme/15/fontscheme004.spfont" #optional, if needed uncomment
#List of all WebApplications where Theme should be changed
$WebApps = @()#Declare array
$WebApps = 'http://intranet', 'http://extranet'


#Don't change beyond this line


#Loop through each Web Application
foreach ($WebApp in $WebApps)
{
    $WebApp = Get-SPWebApplication $WebApp
    Write-Host "Working on WebApp" $WebApp.Url
    #Loop through each Site Collection
    foreach ($SC in $WebApp.Sites)
    {
        Write-Host "Working on Site Collection" $SC.Url
        # Loop through each Web (Subsite), this includes Root Web as well
        foreach ($SPWeb in $SC.AllWebs) 
        {
            Write-Host 'Working on Site' $SPWeb
      
            #Optional - define Font Scheme
            If ($FontRelativeURL -ne $null) { $fontSchemeUrl = [Microsoft.SharePoint.Utilities.SPUrlUtility]::CombineUrl($SC.ServerRelativeUrl, $FontRelativeURL) }
            #Build Site Collection specific Theme URL
            $themeUrl = [Microsoft.SharePoint.Utilities.SPUrlUtility]::CombineUrl($SC.ServerRelativeUrl, $themeRelativeURL)
            # Use Image URL from Site Collection
            $imageUrl = ""

            $SPWeb.allowunsafeupdates = $true
            $SPWeb = Get-SPWeb $SPWeb.Url
            #Now apply Theme
            $SPWeb.ApplyTheme($themeUrl, $fontSchemeUrl, $imageUrl, $true);
            Write-Host "Set" $themeName "at :" $SPWeb.Title "(" $SPWeb.Url ")" 
            #Commit changes
            $SPWeb.Update()
            $SPWeb.allowunsafeupdates = $false

            #Cleanup
            $SPWeb.Dispose()
        }  
    #Cleanup
    $SC.Dispose()
    }
}