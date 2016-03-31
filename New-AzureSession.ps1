#Load Azure
import-module Azure
Login-AzureRmAccount
# Get all subscriptions
# Get-AzureRmSubscription

#Set default subscription for current session
Get-AzureRmSubscription -SubscriptionName 'Visual Studio Ultimate with MSDN' | Select-AzureRmSubscription

