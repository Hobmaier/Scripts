$group = Get-AzureADGroup -All $True | Where-Object {$_.DisplayName -eq “ENTER GROUP DISPLAY NAME HERE WHO WILL HAVE ACCESS TO CREATE GROUPS”} 
$settings = Get-AzureADDirectorySetting | where-object {$_.displayname -eq “Group.Unified”}
$settings["ClassificationDescriptions"] = "Confidential:High business impact. Normally accessible only to specified members,Restricted:Normally accessible only to specified and/or relevant members,Internal Use:Normally accessible to all employees,Public:Accessible to all members of the public"
$settings["DefaultClassification"] = "Internal Use"
$settings["PrefixSuffixNamingRequirement"] = "ogrp-" 
$settings["AllowGuestsToBeGroupOwner"] = "false"
$settings["AllowGuestsToAccessGroups"] = "true" 
$settings["GuestUsageGuidelinesUrl"] = "https://domain.sharepoint.com/sites/intranet/Pages/Groups-Guest-Usage-Guidelines.aspx"
$settings["GroupCreationAllowedGroupId"] = $group.ObjectId 
$settings["AllowToAddGuests"] = "true"
$settings["UsageGuidelinesUrl"] = "https://domain.sharepoint.com/sites/intranet/Pages/Groups-Usage-Guidelines.aspx" 
$settings["ClassificationList"] = "Confidential,Restricted,Internal Use,Public"
$settings["EnableGroupCreation"] = "true"
Set-AzureADDirectorySetting -Id $settings.Id -DirectorySetting $settings