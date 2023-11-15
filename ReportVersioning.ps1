#Version 1.0, 19.02.2015
#Dennis Hobmaier, AvePoint


# Loading Microsoft.SharePoint.PowerShell 
$snapin = Get-PSSnapin | Where-Object {$_.Name -eq 'Microsoft.SharePoint.Powershell'}
if ($snapin -eq $null) {
Write-Host "Loading SharePoint Powershell Snapin"
Add-PSSnapin "Microsoft.SharePoint.Powershell"
}

# variable section
If ($PSScriptRoot -eq $null)
{
    $PSScriptRoot = '.'
}
$csvfile = "$PSScriptRoot\ReportVersioning.csv"
#List of all WebApplications
$WebApps = @()#Declare array
$WebApps = 'http://intranet', 'http://extranet'
 $SystemLists =@("Pages", "Converted Forms", "Master Page Gallery", "Customized Reports", "Documents", `    "Form Templates", "Images", "List Template Gallery", "Theme Gallery", "Reporting Templates", `    "Site Collection Documents", "Site Collection Images", "Site Pages", "Solution Gallery", `    "Style Library", "Web Part Gallery","Site Assets", "wfpub")

  


# Don't change beyond this line


#Write CSV Header
add-content -path $csvfile -Encoding UTF8 -Value ('ListURL,ListName,IsTemplateDocumentLibrary,MajorVersioningEnabled,MajorVersion,MinorVersionEnabled,MinorVersion')


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
            Write-Host 'Working on Site' $SPWeb.Url
      
            #Get all Lists
            foreach ($list in $spWeb.Lists)
            {
                write-host "Get Versioning for List: " $list.Title

                if (($list.EnableVersioning) -and ($list.Hidden -eq $false) -and ($SystemLists -notcontains $list.Title))
                {
                    #Define Limit for Major Versions
                    $list.MajorVersionLimit
                    #Enable Minor Versions
                    

                    if ($list.BaseTemplate -eq 'DocumentLibrary')
                    {
                        $IsDocumentLib = $true
                        # Document Library have more versioning settings                        
                        #Enable Versioning
                        $libMinorVersions = $list.EnableMinorVersions
                        #Define Limit for Minor Versions
                        $libMinorVersionsLimit = $list.MajorWithMinorVersionsLimit
                        
                    
                    } else { $IsDocumentLib = $false}             
                    #Header 'ListURL,ListName,IsTemplateDocumentLibrary,MajorVersioningEnabled,MajorVersion,MinorVersionEnabled,MinorVersion'
                    $ListUrl = $spweb.Url + '/' + $list.RootFolder.url
                    Write-Host 'Versioning enabled ' $list.Title $list.Url -ForegroundColor Green
                    write-host `t 'Major Versioning' $list.EnableVersioning
                    write-host `t 'MajorVersionLimit' $list.MajorVersionLimit
                    write-host `t 'Minor Versioning' $libMinorVersions
                    write-host `t 'Minor Versioning Limit' $libMinorVersionsLimit
                    Add-content -Path $csvfile -Encoding UTF8 -Value ($ListUrl + ',' + $list.Title + ',' + $IsDocumentLib + ',' + $list.EnableVersioning + ',' + $list.MajorVersionLimit + ',' + $libMinorVersions + ',' + $libMinorVersionsLimit)
                    
                    $IsDocumentLib = $null
                }
            }
        $spweb.Dispose()
        }  
    #Cleanup
    $SC.Dispose()
    }

}
Write-host 'Export finshed:' $csvfile -ForegroundColor green