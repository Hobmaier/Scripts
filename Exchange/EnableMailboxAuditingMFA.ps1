#This script will enable non-owner mailbox access auditing on every mailbox in your tenancy
#First, let's get us a cred!

#https://docs.microsoft.com/en-us/powershell/exchange/exchange-online/connect-to-exchange-online-powershell/mfa-connect-to-exchange-online-powershell?view=exchange-ps
Import-Module Microsoft.Exchange.Management.ExoPowershellModule -ErrorAction Stop
# If needed run: Install-Module Microsoft.Exchange.Management.ExoPowershellModule
$userUPN = Read-Host -Prompt "Please provide UserPrincipalName"
$ExoSession = New-EXOPSSession -UserPrincipalName $userUPN
Import-Pssession $ExoSession

#legacy way without MFA
<#
$userCredential = Get-Credential
#This gets us connected to an Exchange remote powershell service
$ExoSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $userCredential -Authentication Basic -AllowRedirection
Import-PSSession $ExoSession
#>

#Enable global audit logging
Get-Mailbox -ResultSize Unlimited -Filter {RecipientTypeDetails -eq "UserMailbox" -or RecipientTypeDetails -eq "SharedMailbox" -or RecipientTypeDetails -eq "RoomMailbox" -or RecipientTypeDetails -eq "DiscoveryMailbox"} | Set-Mailbox -AuditEnabled $true -AuditLogAgeLimit 180 -AuditAdmin Update, MoveToDeletedItems, SoftDelete, HardDelete, SendAs, SendOnBehalf, Create, UpdateFolderPermission -AuditDelegate Update, SoftDelete, HardDelete, SendAs, Create, UpdateFolderPermissions, MoveToDeletedItems, SendOnBehalf -AuditOwner UpdateFolderPermission, MailboxLogin, Create, SoftDelete, HardDelete, Update, MoveToDeletedItems 

#Double-Check It!
Get-Mailbox -ResultSize Unlimited | Select Name, AuditEnabled, AuditLogAgeLimit | Out-Gridview

# Cleanup
Get-PSSession | Remove-PSSession