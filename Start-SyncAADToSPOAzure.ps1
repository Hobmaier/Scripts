# https://tishenko.com/sync-mobile-phone-aad-spo-cell-phone-azure-automation/
Import-Module MSOnline
Import-Module SharePointPnPPowerShellOnline

# Automation Variables
$tenantName = Get-AutomationVariable -Name "tenantName"
$spoAdminUrl = "https://$tenantName-admin.sharepoint.com"
$overwriteExistingSPOUPAValue = Get-AutomationVariable -Name "overwriteExistingSPOUPAValue"

# Get credentials from Automation Variables
$credential = Get-AutomationPSCredential -Name (Get-AutomationVariable -Name "o365GlobalAdminCredentialName")

Try {
    # Connect to AzureAD
    Connect-MsolService -Credential $credential

    # Connect to SPO using PnP
    $spoPnPConnection = Connect-PnPOnline -Url $spoAdminUrl -Credentials $credential -ReturnConnection

    # Get all AzureAD Users with a populated MobilePhone property
    $AzureADUsers = Get-MsolUser -All | Where-Object {(![string]::IsNullOrWhiteSpace($_.MobilePhone))}

    ForEach ($AzureADUser in $AzureADUsers) {
        # Check to see if SPO UserProfileProperty CellPhone differs from AzureAD User Property MobilePhone
        if((Get-PnPUserProfileProperty -Account $AzureADUser.UserPrincipalName).UserProfileProperties.CellPhone -ne $AzureADUser.MobilePhone){
            # Property differs, update with AzureAD value
            # Check to see if we're to overwrite existing property value
            if ($overwriteExistingSPOUPAValue -eq "True") {
                Write-Output "Update CellPhone for $($AzureADUser.UserPrincipalName)"
                Set-PnPUserProfileProperty -Account $AzureADUser.UserPrincipalName -PropertyName CellPhone -Value $AzureADUser.MobilePhone
            }
            else{
                # Not going to overwrite existing property value
                Write-Output "Target SPO UPA CellPhone is not empty for $($AzureADUser.UserPrincipalName) and we're to preserve existing properties"
            }
        }
    }
}
Catch {
    $exception = $_.Exception.Message
    Write-Output "$($exception)"
}