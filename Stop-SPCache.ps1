## Settings you may want to change for your scenario ##
$startTime = Get-Date
$currentTime = $startTime
$elapsedTime = $currentTime - $startTime
$timeOut = 300

try

{

Use-CacheCluster
Get-AFCacheClusterHealth

Write-Host "Shutting down distributed cache host."
$hostInfo = Stop-CacheHost -Graceful -CachePort 22233 -HostName contoso-sp2013.contoso.com

while($elapsedTime.TotalSeconds -le $timeOut-and $hostInfo.Status -ne 'Down')
{
Write-Host "Host Status : [$($hostInfo.Status)]"
Start-Sleep(5)
$currentTime = Get-Date
$elapsedTime = $currentTime - $startTime
#Get-AFCacheClusterHealth
$hostInfo = Get-CacheHost -HostName contoso-sp2013.contoso.com -CachePort 22233
}

Write-Host "Stopping distributed cache host was successful. Updating Service status in SharePoint."
Stop-SPDistributedCacheServiceInstance
Write-Host "To start service, please use Central Administration site."
}
catch [System.Exception]
{
Write-Host "Unable to stop cache host within 5 minutes."
} 