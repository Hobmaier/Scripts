<#
=====================================
 This PowerShell Script help you setting up App Management Service in SharePoint.
 It will start the service instances and create Serivce Applications.

 Version 1.1
 25.01.2016
 Dennis Hobmaier
 --------------------
 History
 1.1, 25.01.2016 
 More variables to change service accounts and database names
 Comments added

 1.0, 28.11.2015 
 Intial Version
=====================================
#>

# Please adjust the account which exist in your environment. 
# If you prefer to run into a separate account use the next line New-SPManagedAccount
# New-SPManagedAccount -Credential (Get-Credential)
$SPServiceAccount= 'CONTOSO\sp_apps'  #INPUT required
$SPAppMngmtDBName = 'T_SP_AppMngmt'
$SPSubscriptionDBName = 'T_SP_SettingsService'
$SPAppDomain = 'contosoapps.com'
$SPAppPrefix = 'app'

#Needs to run on SharePoint Server
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

#Start the service instance on the current server (min 1 per farm)
Get-SPServiceInstance | where{$_.GetType().Name -eq "AppManagementServiceInstance" -or $_.GetType().Name -eq "SPSubscriptionSettingsServiceInstance"} | Start-SPServiceInstance

#You may check all available accounts running Get-SPManagedAccount
$account = Get-SPManagedAccount $SPServiceAccount -ErrorAction Stop

$appPoolAppSvc = New-SPServiceApplicationPool -Name AppServiceAppPool -Account $account
$appAppSvc = New-SPAppManagementServiceApplication -ApplicationPool $appPoolAppSvc -Name AppServiceApp -DatabaseName $SPAppMngmtDBName
$proxyAppSvc = New-SPAppManagementServiceApplicationProxy -ServiceApplication 	$appAppSvc

$AppPool = New-SPServiceApplicationPool -Name SettingsServiceAppPool -Account $account
$App = New-SPSubscriptionSettingsServiceApplication -ApplicationPool $appPool -Name SettingsServiceApp -DatabaseName $SPSubscriptionDBName
$proxy = New-SPSubscriptionSettingsServiceApplicationProxy -ServiceApplication $App

# Configure App Settings
Set-SPAppDomain $SPAppDomain
Set-SPAppSiteSubscriptionName -Name $SPAppPrefix -Confirm:$false