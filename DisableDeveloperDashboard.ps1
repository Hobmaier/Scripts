$ContentService = [Microsoft.SharePoint.Administration.SPWebService]::ContentService
$DevBoard = $ContentService.DeveloperDashboardSettings
$DevBoard.DisplayLevel = "Off"
$DevBoard.Update()