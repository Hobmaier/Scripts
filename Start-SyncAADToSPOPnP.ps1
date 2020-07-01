# original based on this but with modifications to run locally without Azure and MFA capable https://tishenko.com/sync-mobile-phone-aad-spo-cell-phone-azure-automation/
Import-Module MSOnline -ErrorAction Stop
Import-Module SharePointPnPPowerShellOnline -ErrorAction Stop

# Automation Variables
$tenantName = Read-Host -Prompt "Please provide tenant domain"
$spoAdminUrl = "https://$tenantName-admin.sharepoint.com"
$overwriteExistingSPOUPAValue = $true

Try {
    # Connect to AzureAD
    Connect-MsolService

    # Connect to SPO using PnP
    $spoPnPConnection = Connect-PnPOnline -Url $spoAdminUrl -UseWebLogin -ReturnConnection

    # Get all AzureAD Users
    $AzureADUsers = Get-MsolUser -All

    ForEach ($AzureADUser in $AzureADUsers) {
        Write-Output "Working on user: $($AzureADUser.UserPrincipalName)"
        if (!([string]::IsNullOrEmpty($AzureADUser.MobilePhone))) 
        {
            # Check to see if SPO UserProfileProperty CellPhone differs from AzureAD User Property MobilePhone
            if((Get-PnPUserProfileProperty -Account $AzureADUser.UserPrincipalName).UserProfileProperties.CellPhone -ne $AzureADUser.MobilePhone){
                # Property differs, update with AzureAD value
                # Check to see if we're to overwrite existing property value
                if ($overwriteExistingSPOUPAValue -eq "True") {
                    Write-Output "Update CellPhone for $($AzureADUser.UserPrincipalName) using $($AzureADUser.MobilePhone)"
                    Set-PnPUserProfileProperty -Account $AzureADUser.UserPrincipalName -PropertyName CellPhone -Value $AzureADUser.MobilePhone
                }
                else{
                    # Not going to overwrite existing property value
                    Write-Output "Target SPO UPA CellPhone is not empty for $($AzureADUser.UserPrincipalName) and we're to preserve existing properties"
                }
            } else {
                Write-Output "CellPhone no change"
            }
        }
    }
}
Catch {
    $exception = $_.Exception.Message
    Write-Output "$($exception)"
}