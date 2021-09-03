Import-Module SharePointPnPPowerShellOnline -ErrorAction Stop
$SiteCollectionURL = "https://m365x017349.sharepoint.com/sites/MassEditingTest"
$SourceFile = "C:\Temp\Contract.docx"
$NewFileName = "File"
$NewFileNameExtenstion = ".docx"

Connect-PnPOnline -Url $SiteCollectionURL -UseWebLogin -ErrorAction Stop

for ($i = 0; $i -lt 16000; $i++)
{
    Add-PnPFile -Path $SourceFile -Folder "Shared Documents" -NewFileName ($NewFileName + $i + $NewFileNameExtenstion) -ErrorAction Stop
}