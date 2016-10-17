#Cleans temp files, empties event logs

#Remove Users Temp folder
write-host 'Clear ' $env:temp -ForegroundColor green
Remove-Item $env:temp\* -Recurse -Force -ErrorAction SilentlyContinue

#Remove Windows Temp folder
write-host 'Clear ' $env:SystemRoot\temp\ -ForegroundColor Green
Remove-Item $env:SystemRoot\temp\* -Recurse -Force -ErrorAction SilentlyContinue

#Clear all eventlogs
write-host 'Clear Eventlogs' -ForegroundColor Green
$logs = get-eventlog -computername $env:COMPUTERNAME -list | foreach {$_.Log} 
$logs | foreach {clear-eventlog -comp $env:COMPUTERNAME -log $_ }
get-eventlog -computername $env:COMPUTERNAME -list


#Remove IIS Log

Import-Module WebAdministration -ErrorAction SilentlyContinue
If (Get-Module WebAdministration)
{
    $IISLogs = (Get-WebConfigurationProperty "/system.applicationHost/sites/siteDefaults" -name logfile.directory).Value
    write-host 'Clear IIS Logs' $IISLogs -ForegroundColor Green
    Remove-Item $IISLogs -Filter "*.log" -Recurse -Force -ErrorAction SilentlyContinue
}

#Remove SharePoint Log
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
If (Get-Pssnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue)
{
    $SPSLog = Get-SPDiagnosticConfig
    Write-host 'Clear SharePoint Logs' $SPSLog.LogLocation -ForegroundColor Green
    Remove-Item $SPSLog.LogLocation -Filter "*.log" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $SPSLog.LogLocation -Filter "*.usage" -Recurse -Force -ErrorAction SilentlyContinue
}

#Remove Logs
$LogFolders = @(`    'C:\Temp\CM'
)
foreach ($LogFolder in $LogFolders)
{
    If (get-item $LogFolder -ErrorAction SilentlyContinue)
    {
        Write-Host 'Clear Log Folder' $LogFolder -ForegroundColor Green
        Remove-Item $LogFolder\* -Recurse -Force -ErrorAction SilentlyContinue
    }
}