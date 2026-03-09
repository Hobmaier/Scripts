#requires -Version 7.0
#requires -Modules PnP.PowerShell

<#
.SYNOPSIS
Sets the current UTC datetime into a read-only DateTime field (RevIMDeclareTime) for a specific document.

.PARAMETER SiteUrl
SharePoint site URL, e.g. https://contoso.sharepoint.com/sites/RecordsBundle15

.PARAMETER LibraryTitle
Document library title, e.g. "Shared Documents"

.PARAMETER ServerRelativeFileUrl
Server-relative URL to the file, e.g. "/sites/RecordsBundle15/Shared Documents/Test.docx"

.PARAMETER FieldInternalName
Internal name of the field to update. Default: RevIMDeclareTime

.PARAMETER UseUtc
If set, stores UTC time (recommended for consistency with search/crawled properties).
If not set, stores local time.

.NOTES
- First tries Set-PnPListItem (fast path).
- If that fails (common for ReadOnly fields), falls back to ValidateUpdateListItem via Invoke-PnPSPRestMethod.
#>

param(
    [Parameter(Mandatory)]
    [string]$SiteUrl,

    [Parameter(Mandatory)]
    [string]$LibraryTitle,

    [Parameter(Mandatory)]
    [string]$ServerRelativeFileUrl,

    [Parameter(Mandatory)]
    [guid]$ClientID,

    [Parameter(Mandatory)]
    [string]$Thumbprint,

    [Parameter(Mandatory)]
    [guid]$TenantID,

    [string]$FieldInternalName = "RevIMDeclareTime",

    [switch]$UseUtc
)

$ErrorActionPreference = "Stop"

# 1) Connect
$Connection = Connect-PnPOnline -Url $SiteUrl -ApplicationId $ClientID -Thumbprint $Thumbprint -Tenant $TenantID

# 2) Resolve the list item for the file
$file = Get-PnPFile -Url $ServerRelativeFileUrl -AsListItem
if (-not $file) {
    throw "File not found at ServerRelativeFileUrl: $ServerRelativeFileUrl"
}

$itemId = $file.Id
Write-Host "Resolved list item ID: $itemId" -ForegroundColor Cyan

# 3) Prepare timestamp (ISO 8601 is safe for REST; SharePoint accepts it well)
$now = if ($UseUtc) { [DateTime]::UtcNow } else { Get-Date }
# Use round-trip ("o") format: 2026-03-09T08:53:25.1234567Z
$timestamp = $now.ToString("o")

Write-Host "Setting $FieldInternalName to: $timestamp" -ForegroundColor Cyan

# 4) Fast path: try Set-PnPListItem (may fail for ReadOnly fields)
try {
    # UpdateOverwriteVersion: "Sets field values and does not create a new version" (per cmdlet docs). [7](https://pnp.github.io/powershell/cmdlets/Set-PnPListItem.html)
    Set-PnPListItem -List $LibraryTitle -Identity $itemId -Values @{ $FieldInternalName = $timestamp } -UpdateType UpdateOverwriteVersion
    Write-Host "Updated via Set-PnPListItem (UpdateOverwriteVersion)." -ForegroundColor Green
}
catch {
    Write-Warning "Set-PnPListItem failed (likely due to ReadOnlyField). Falling back to ValidateUpdateListItem. Error: $($_.Exception.Message)"

    # 5) Fallback: ValidateUpdateListItem REST call
    # Endpoint: /_api/web/lists/getByTitle('<LIB>')/items(<ID>)/ValidateUpdateListItem
    # Body includes formValues + bNewDocumentUpdate (true ~= overwrite version semantics). [5](https://nadirkamdar.blogspot.com/2025/06/using-sharepoints-validateupdatelistite.html)[6](https://techcommunity.microsoft.com/blog/spblog/update-file-metadata-with-rest-api-using-validateupdatelistitem-in-sharepoint-on/1365682)
    $encodedListTitle = $LibraryTitle.Replace("'", "''") # escape single quotes for OData
    $endpoint = "/_api/web/lists/getByTitle('$encodedListTitle')/items($itemId)/ValidateUpdateListItem"

    $body = @{
        formValues = @(
            @{
                FieldName  = $FieldInternalName
                FieldValue = $timestamp
            }
        )
        bNewDocumentUpdate = $true
    } | ConvertTo-Json -Depth 10

    Invoke-PnPSPRestMethod -Method Post -Url $endpoint -ContentType "application/json;odata=verbose" -Body $body | Out-Null

    Write-Host "Updated via ValidateUpdateListItem." -ForegroundColor Green
}

# 6) (Optional) read-back to verify
$updated = Get-PnPListItem -List $LibraryTitle -Id $itemId -Fields $FieldInternalName
Write-Host "Read-back value: $($updated[$FieldInternalName])" -ForegroundColor Yellow

$Connection = $null