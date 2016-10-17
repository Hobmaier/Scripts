$ContentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
$DevBoard = $ContentService.DeveloperDashboardSettings
$DevBoard.DisplayLevel = "On"
$DevBoard.Update()