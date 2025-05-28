<#

.SYNOPSIS
    Collect Azure storage information

.DESCRIPTION
    This script collect information (Id, size, location) about VMs, allocated storage for Managed Disks, SQL and consumed storage for Storage Accounts. It will create a export file Start-DiscoverSubscriptionResources.csv

.EXAMPLE
    .\Start-DiscoverSubscriptionResources.ps1
    This will import Az module, connect and get all subscriptions, vms, disks, sql databases and storage accounts. It will export storage information to CSV.

#> 

import-module az -erroraction stop
#Connect
Connect-AzAccount -ErrorAction Stop

$Logfile = ".\Start-DiscoverSubscriptionResources.csv"
#Header 
Out-File -InputObject "ID;Storage;Location;Size;OS" -FilePath $Logfile 

#Get all subscriptions
foreach ($Subscription in Get-AzSubscription)
{
    Set-AzContext -Subscription $Subscription.Id
    #Get all resource groups
    foreach ($RG in Get-AzResourceGroup)
    {
        #Get all VMs
        foreach ($VM in Get-AzVM -resourcegroup $RG.ResourceGroupName)
        {
            Out-File -InputObject "$($VM.VmId);;$($VM.Location);$($VM.HardwareProfile.VmSize);$($VM.OsType)" -FilePath $Logfile -append
        }
    }

    #Get all Managed disks
    foreach ($Disk in get-azdisk)
    {
        Out-File -InputObject "$($Disk.UniqueID);$($Disk.DiskSizeGB);$($Disk.Location)" $Logfile -Append
    }

    foreach ($SA in Get-AzStorageAccount)
    {
        #Bytes to GB
        [int]$metric = (get-azmetric -ResourceId $SA.Id -MetricName "UsedCapacity" -WarningAction SilentlyContinue).Data.Average /1024 /1024 /1024
        Out-File -InputObject "$($SA.Id);$($metric);$($SA.Location)" -FilePath $Logfile -append
    }


    foreach ($SQL in Get-AzSqlServer)
    {
        foreach ($DB in Get-AzSqlDatabase -ServerName $SQL.ServerName -ResourceGroupName $SQL.ResourceGroupName)
        {
            Out-File -InputObject "$($DB.DatabaseId);$($DB.Capacity)" -FilePath $Logfile -Append
        }
    }
}