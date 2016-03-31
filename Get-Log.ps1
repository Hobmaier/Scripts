Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
Merge-SPLogFile -Path "c:\temp\MergedLog.log" -Overwrite -StartTime "02.02.2016 13:45" -EndTime "02.02.2016 14:00"