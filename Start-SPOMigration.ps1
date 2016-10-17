$creds = Get-Credential "dennis@hobmaier.net" 
$sourcefilepath =   “\\knecht\test”
$packageoutputpath = “\\knecht\Package”
$packageoutputpathout = “\\knecht\OutputPackage”
$targetweburl = “https://dns4ever.sharepoint.com/sites/Projekte”
#$targetdoclib = "CenterTools"
$targetdoclib = "IconsCT"
$filecontainername = "payload"
$packagecontainername = "migrationpackage"
$azurequeuename = “spomigration”
$azureaccountname = "<azurestorageaccountname>"
$azurestoragekey ="<azurestoragekey>"
#$targetsubfolder = "Office365Konferenz"
Import-Module Microsoft.Online.SharePoint.PowerShell -ErrorAction SilentlyContinue

write-host 'New Package'
$pkg = New-SPOMigrationPackage -SourceFilesPath $sourcefilepath -OutputPackagePath $packageoutputpath -TargetWebUrl $targetweburl -TargetDocumentLibraryPath $targetdoclib –NoADLookup -ErrorAction Stop
write-host 'Convert Package'
$tpkg = ConvertTo-SPOMigrationTargetedPackage -SourceFilesPath $sourcefilepath -SourcePackagePath $packageoutputpath -OutputPackagePath $packageoutputpathout -TargetWebUrl $targetweburl -TargetDocumentLibraryPath $targetdoclib -Credentials $creds -ErrorAction stop
write-host 'Upload package'
$uploadresult = Set-SPOMigrationPackageAzureSource –SourceFilesPath $sourcefilepath –SourcepackagePath $packageoutputpathout –FileContainerName $filecontainername –PackageContainerName $packagecontainername –AzureQueueName $azurequeuename –AccountName $azureaccountname -AccountKey $azurestoragekey -ErrorAction Stop
write-host 'FileContainerUri' $uploadresult.FileContainerUri
write-host 'FileContainerUploadUri' $uploadresult.FileContainerUploadUri
write-host 'Start Migration'
$jobresult = Submit-SPOMigrationJob –TargetwebUrl $targetweburl –MigrationPackageAzureLocations $uploadresult –Credentials $creds -ErrorAction Stop
write-host $jobresult
Write-host 'Done'