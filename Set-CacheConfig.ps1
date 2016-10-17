Add-PSSnapin Microsoft.Sharepoint.Powershell

#DistributedLogonTokenCache
$DLTC = Get-SPDistributedCacheClientSetting -ContainerType DistributedLogonTokenCache
$DLTC.MaxConnectionsToServer = 1
$DLTC.requestTimeout = "3000"
$DLTC.channelOpenTimeOut = "3000"
Set-SPDistributedCacheClientSetting -ContainerType DistributedLogonTokenCache $DLTC

#DistributedViewStateCache
$DVSC = Get-SPDistributedCacheClientSetting -ContainerType DistributedViewStateCache
$DVSC.MaxConnectionsToServer = 1
$DVSC.requestTimeout = "3000"
$DVSC.channelOpenTimeOut = "3000"
Set-SPDistributedCacheClientSetting -ContainerType DistributedViewStateCache $DVSC

#DistributedAccessCache
$DAC = Get-SPDistributedCacheClientSetting -ContainerType DistributedAccessCache
$DAC.MaxConnectionsToServer = 1
$DAC.requestTimeout = "3000"
$DAC.channelOpenTimeOut = "3000"
Set-SPDistributedCacheClientSetting -ContainerType DistributedAccessCache $DAC

#DistributedActivityFeedCache
$DAF = Get-SPDistributedCacheClientSetting -ContainerType DistributedActivityFeedCache
$DAF.MaxConnectionsToServer = 1
$DAF.requestTimeout = "3000"
$DAF.channelOpenTimeOut = "3000"
Set-SPDistributedCacheClientSetting -ContainerType DistributedActivityFeedCache $DAF

#DistributedActivityFeedLMTCache
$DAFC = Get-SPDistributedCacheClientSetting -ContainerType DistributedActivityFeedLMTCache
$DAFC.MaxConnectionsToServer = 1
$DAFC.requestTimeout = "3000"
$DAFC.channelOpenTimeOut = "3000"
Set-SPDistributedCacheClientSetting -ContainerType DistributedActivityFeedLMTCache $DAFC

#DistributedBouncerCache
$DBC = Get-SPDistributedCacheClientSetting -ContainerType DistributedBouncerCache
$DBC.MaxConnectionsToServer = 1
$DBC.requestTimeout = "3000"
$DBC.channelOpenTimeOut = "3000"
Set-SPDistributedCacheClientSetting -ContainerType DistributedBouncerCache $DBC

#DistributedDefaultCache
$DDC = Get-SPDistributedCacheClientSetting -ContainerType DistributedDefaultCache
$DDC.MaxConnectionsToServer = 1
$DDC.requestTimeout = "3000"
$DDC.channelOpenTimeOut = "3000"
Set-SPDistributedCacheClientSetting -ContainerType DistributedDefaultCache $DDC

#DistributedSearchCache
$DSC = Get-SPDistributedCacheClientSetting -ContainerType DistributedSearchCache
$DSC.MaxConnectionsToServer = 1
$DSC.requestTimeout = "3000"
$DSC.channelOpenTimeOut = "3000"
Set-SPDistributedCacheClientSetting -ContainerType DistributedSearchCache $DSC

#DistributedSecurityTrimmingCache
$DTC = Get-SPDistributedCacheClientSetting -ContainerType DistributedSecurityTrimmingCache
$DTC.MaxConnectionsToServer = 1
$DTC.requestTimeout = "3000"
$DTC.channelOpenTimeOut = "3000"
Set-SPDistributedCacheClientSetting -ContainerType DistributedSecurityTrimmingCache $DTC

#DistributedServerToAppServerAccessTokenCache
$DSTAC = Get-SPDistributedCacheClientSetting -ContainerType DistributedServerToAppServerAccessTokenCache
$DSTAC.MaxConnectionsToServer = 1
$DSTAC.requestTimeout = "3000"
$DSTAC.channelOpenTimeOut = "3000"
Set-SPDistributedCacheClientSetting -ContainerType DistributedServerToAppServerAccessTokenCache $DSTAC