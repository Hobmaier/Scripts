Add-PSSnapin Microsoft.Sharepoint.Powershell

#DistributedLogonTokenCache
$DLTC = Get-SPDistributedCacheClientSetting -ContainerType DistributedLogonTokenCache
Write-Host  'DLTC'
Write-Host $DLTC.MaxConnectionsToServer
Write-Host $DLTC.requestTimeout
Write-Host $DLTC.channelOpenTimeOut

#DistributedViewStateCache
$DVSC = Get-SPDistributedCacheClientSetting -ContainerType DistributedViewStateCache
Write-Host 'DVSC'
Write-Host $DVSC.MaxConnectionsToServer
Write-Host $DVSC.requestTimeout
Write-Host $DVSC.channelOpenTimeOut

#DistributedAccessCache
$DAC = Get-SPDistributedCacheClientSetting -ContainerType DistributedAccessCache
Write-Host 'DAC'
Write-Host $DAC.MaxConnectionsToServer
Write-Host $DAC.requestTimeout
Write-Host $DAC.channelOpenTimeOut

#DistributedActivityFeedCache
$DAF = Get-SPDistributedCacheClientSetting -ContainerType DistributedActivityFeedCache
Write-Host 'DAF'
Write-Host $DAF.MaxConnectionsToServer
Write-Host $DAF.requestTimeout
Write-Host $DAF.channelOpenTimeOut

#DistributedActivityFeedLMTCache
$DAFC = Get-SPDistributedCacheClientSetting -ContainerType DistributedActivityFeedLMTCache
Write-Host 'DAFC'
Write-Host $DAFC.MaxConnectionsToServer
Write-Host $DAFC.requestTimeout
Write-Host $DAFC.channelOpenTimeOut

#DistributedBouncerCache
$DBC = Get-SPDistributedCacheClientSetting -ContainerType DistributedBouncerCache
Write-Host 'DBC'
Write-Host $DBC.MaxConnectionsToServer
Write-Host $DBC.requestTimeout
Write-Host $DBC.channelOpenTimeOut

#DistributedDefaultCache
$DDC = Get-SPDistributedCacheClientSetting -ContainerType DistributedDefaultCache
Write-Host 'DDC'
Write-Host $DDC.MaxConnectionsToServer
Write-Host $DDC.requestTimeout
Write-Host $DDC.channelOpenTimeOut

#DistributedSearchCache
$DSC = Get-SPDistributedCacheClientSetting -ContainerType DistributedSearchCache
Write-Host 'DSC'
Write-Host $DSC.MaxConnectionsToServer
Write-Host $DSC.requestTimeout
Write-Host $DSC.channelOpenTimeOut

#DistributedSecurityTrimmingCache
$DTC = Get-SPDistributedCacheClientSetting -ContainerType DistributedSecurityTrimmingCache
Write-Host 'DTC'
Write-Host $DTC.MaxConnectionsToServer
Write-Host $DTC.requestTimeout
Write-Host $DTC.channelOpenTimeOut

#DistributedServerToAppServerAccessTokenCache
$DSTAC = Get-SPDistributedCacheClientSetting -ContainerType DistributedServerToAppServerAccessTokenCache
Write-Host 'DSTAC'
Write-Host $DSTAC.MaxConnectionsToServer
Write-Host $DSTAC.requestTimeout
Write-Host $DSTAC.channelOpenTimeOut