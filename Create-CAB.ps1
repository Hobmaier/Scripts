Param(
  $filepath = "C:\fso", 
  $path = "C:\fso1\cabfiles",
  [switch]$debug
  )
# Source: https://technet.microsoft.com/en-us/library/2009.04.heyscriptingguy.aspx
Function New-DDF($path,$filePath)
{
 $ddfFile = Join-Path -path $filePath -childpath temp.ddf
 Write-Debug "DDF file path is $ddfFile"
 $ddfHeader =@"
;*** MakeCAB Directive file
;
.OPTION EXPLICIT      
.Set CabinetNameTemplate=Cab.*.cab
.set DiskDirectory1=C:\fso1\Cabfiles
.Set MaxDiskSize=CDROM
.Set Cabinet=on
.Set Compress=on
"@
 Write-Debug "Writing ddf file header to $ddfFile" 
 $ddfHeader | Out-File -filepath $ddfFile -force -encoding ASCII
 Write-Debug "Generating collection of files from $filePath"
 Get-ChildItem -path $filePath | 
 Where-Object { !$_.psiscontainer } |
 ForEach-Object `
 { 
 '"' + $_.fullname.tostring() + '"' | 
 Out-File -filepath $ddfFile -encoding ASCII -append
 }
 Write-Debug "ddf file is created. Calling New-Cab function"
 New-Cab($ddfFile)
} #end New-DDF

Function New-Cab($ddfFile)
{
 Write-Debug "Entering the New-Cab function. The DDF File is $ddfFile"
 if($debug)
 { makecab /f $ddfFile /V3 }
 Else
 { makecab /f $ddfFile }
} #end New-Cab

# *** entry point to script ***
if($debug) {$DebugPreference = "continue"}
New-DDF -path $path -filepath $filepath