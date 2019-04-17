#Import the right module to talk with AAD
import-module MSOnline -ErrorAction Stop


#Let's get us an admin cred!
Import-Module Microsoft.Exchange.Management.ExoPowershellModule -ErrorAction Stop
# If needed run: Install-Module Microsoft.Exchange.Management.ExoPowershellModule

#This connects to Azure Active Directory
Connect-MsolService
$userUPN = Read-Host -Prompt "Please provide UserPrincipalName"
$ExoSession = New-EXOPSSession -UserPrincipalName $userUPN
Import-Pssession $ExoSession

$allUsers = @()
$AllUsers = Get-MsolUser -All -EnabledFilter EnabledOnly | select ObjectID, UserPrincipalName, FirstName, LastName, StrongAuthenticationRequirements, StsRefreshTokensValidFrom, StrongPasswordRequired, LastPasswordChangeTimestamp | Where-Object {($_.UserPrincipalName -notlike "*#EXT#*")}

$UserInboxRules = @()
$UserDelegates = @()

foreach ($User in $allUsers)
{
    Write-Host "Checking inbox rules and delegates for user: " $User.UserPrincipalName;
    $UserInboxRules += Get-InboxRule -Mailbox $User.UserPrincipalname | Select Name, Description, Enabled, Priority, ForwardTo, ForwardAsAttachmentTo, RedirectTo, DeleteMessage | Where-Object {($_.ForwardTo -ne $null) -or ($_.ForwardAsAttachmentTo -ne $null) -or ($_.RedirectsTo -ne $null)}
    $UserDelegates += Get-MailboxPermission -Identity $User.UserPrincipalName | Where-Object {($_.IsInherited -ne "True") -and ($_.User -notlike "*SELF*")}
}

$SMTPForwarding = Get-Mailbox -ResultSize Unlimited | select DisplayName,ForwardingAddress,ForwardingSMTPAddress,DeliverToMailboxandForward | where {$_.ForwardingSMTPAddress -ne $null}

$UserInboxRules | Export-Csv MailForwardingRulesToExternalDomains.csv
$UserDelegates | Export-Csv MailboxDelegatePermissions.csv
$SMTPForwarding | Export-Csv Mailboxsmtpforwarding.csv

# Cleanup
Get-PSSession | Remove-PSSession