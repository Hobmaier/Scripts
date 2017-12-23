Write-Host 'Import Modules SPO and PnP'
import-module sharepointpnppowershellonline -ErrorAction Stop
import-module Microsoft.Online.SharePoint.PowerShell -ErrorAction Stop
$cred = Get-Credential -Message "SharePoint Admin"
Connect-SPOService -Url https://s2sshowcase-admin.sharepoint.com -Credential $cred -ErrorAction Stop
$LocalDirectory = "D:\Temp\Masterpages_extracted\Masterpages_extracted\_catalogs\masterpage"

#$Sites = Get-SPOSite
$Sites = Get-SPOSite "https://s2sshowcase.sharepoint.com/sites/IntranetTemplate2471"

function UploadDocuments()
{
    Param(
            [ValidateScript({If(Test-Path $_){$true}else{Throw "Invalid path given: $_"}})] 
            $LocalFolderLocation,
            [String] 
            $siteUrl,
            [String]
            $documentLibraryName
    )
    Process{
            $path = $LocalFolderLocation.TrimEnd('\')
    
            Write-Host "Provided Site :"$siteUrl -ForegroundColor Green
            Write-Host "Provided Path :"$path -ForegroundColor Green
            Write-Host "Provided Document Library name :"$documentLibraryName -ForegroundColor Green
    
              try{
                    $credentials = $cred
      
                    Connect-PnPOnline -Url $siteUrl -CreateDrive -Credentials $credentials
    
                    $file = Get-ChildItem -Path $LocalFolderLocation -Recurse
                    $i = 0;
                    Write-Host "Uploading documents to Site.." -ForegroundColor Cyan
                    (Get-ChildItem $path -Recurse) | ForEach-Object{
                        try{
                            $i++
                            if($_.GetType().Name -eq "FileInfo"){
                              $SPFolderName =  $documentLibraryName + $_.DirectoryName.Substring($path.Length);
                              $status = "Uploading Files :'" + $_.Name + "' to Location :" + $SPFolderName
                              Write-Progress -activity "Uploading Documents.." -status $status -PercentComplete (($i / $file.length)  * 100)
                              $te = Add-PnPFile -Path $_.FullName -Folder $SPFolderName
                              Set-PnPFileCheckedOut -Url $te.ServerRelativeUrl
                              Set-PnPFileCheckedIn -Url $te.ServerRelativeUrl -CheckinType MajorCheckIn -Comment "Script: Publish Design Files"
                             }          
                            }
                        catch{
                        }
                     }
                }
                catch{
                 Write-Host $_.Exception.Message -ForegroundColor Red
                }
    
      }
    }
    
    

foreach ($Site in $Sites)
{
    #Apply theme in whole tenant

    Connect-PnPOnline -Url $Site.url -Credentials $cred

    UploadDocuments -LocalFolderLocation $LocalDirectory -siteUrl $Site.url -documentLibraryName "_catalogs/masterpage"
    
    $relativeurl = $sites.url.IndexOf("sharepoint.com/")
    $relativeurl = $site.url.Substring($relativeurl +14)
    Write-Host 'Apply Masterpage at Site Collection' $site.url
    Set-PnPMasterPage -MasterPageServerRelativeUrl $relativeurl/_catalogs/masterpage/iozIntranet.master `
    -CustomMasterPageServerRelativeUrl $relativeurl/_catalogs/masterpage/iozIntranet.master
    $webs = get-pnpsubwebs -Recurse
    foreach ($web in $webs)
    {
        if ($web.webtemplate -ne 'APP')
        {
            Write-Host 'Apply Masterpage at Web' $web.url
            Connect-PnPOnline -Url $web.url -Credentials $cred
            Set-PnPMasterPage -MasterPageServerRelativeUrl $relativeurl/_catalogs/masterpage/iozIntranet.master `
            -CustomMasterPageServerRelativeUrl $relativeurl/_catalogs/masterpage/iozIntranet.master        
        }
    }
}