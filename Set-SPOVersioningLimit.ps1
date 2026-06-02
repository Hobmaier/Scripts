#Requires -Version 7.0
#Requires -Modules PnP.PowerShell

<#
.SYNOPSIS
    Updates Document Library versioning settings across a large SharePoint Online tenant.
.DESCRIPTION
    Evaluates all non-hidden Document Libraries in all SharePoint Site Collections (excluding OneDrive).
    Uses explicit connection objects (-ReturnConnection) to ensure stability and proper memory cleanup 
    across 50,000+ sites. Uses REST API for automatic versioning to ensure module compatibility.
#>

[CmdletBinding()]
param (
    # The URL of your SharePoint Admin Center (e.g., "https://contoso-admin.sharepoint.com")
    [Parameter(Mandatory = $true, HelpMessage = "The URL of the SharePoint Admin Center.")]
    [string]$AdminCenterUrl,

    # The Azure AD Tenant ID (GUID or primary domain)
    [Parameter(Mandatory = $true, HelpMessage = "The Azure Active Directory Tenant ID.")]
    [string]$TenantId,

    # The Client ID (App ID) of the Azure AD app registration used for authentication
    [Parameter(Mandatory = $true, HelpMessage = "The Client ID of the Azure AD App Registration.")]
    [string]$ClientId,

    # The thumbprint of the local certificate associated with the Azure AD app
    [Parameter(Mandatory = $true, HelpMessage = "The thumbprint of the certificate used for app-only authentication.")]
    [string]$Thumbprint,

    # Determines the versioning behavior to enforce: 'Automatic' (SharePoint managed) or 'MajorLimit' (fixed count)
    [Parameter(Mandatory = $true, HelpMessage = "Defines which versioning setting to apply.")]
    [ValidateSet('Automatic', 'MajorLimit')]
    [string]$SettingToApply,

    # The specific number of major versions to retain. Only applies if SettingToApply is 'MajorLimit'. Default is 100.
    [Parameter(Mandatory = $false, HelpMessage = "The number of major versions to retain if using MajorLimit.")]
    [int]$NewMajorVersionLimit = 100,

    # NEU: Optionaler Parameter für den Verfall von Versionen in Tagen
    [Parameter(Mandatory = $false, HelpMessage = "Optional: Days after which versions should expire. Only applies to 'MajorLimit'.")]
    [int]$ExpireVersionsAfterDays,    

    # Runs the script in read-only mode, logging the actions it would take to the console and CSV without saving changes
    [Parameter(Mandatory = $false, HelpMessage = "Simulates the run without making actual changes.")]
    [switch]$Simulate,
	
	[Parameter(Mandatory = $false, HelpMessage = "List of library titles to explicitly ignore.")]
    [string[]]$ExcludedLibraries = @("Form Templates", "Site Assets", "Style Library", "Site Pages", "Preservation Hold Library")	
)

$ErrorActionPreference = "Stop"

# --- Dynamic Pathing & Log File Setup ---
$scriptPath = if ($PSCommandPath) { $PSCommandPath } else { "$PWD\Update-LibraryVersioning.ps1" }
$scriptDir = Split-Path $scriptPath -Parent
$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($scriptPath)
$timestampStr = Get-Date -Format "yyyyMMdd_HHmmss"

$LogFilePath = Join-Path $scriptDir "${scriptName}_Log_${timestampStr}.txt"
$CsvOutputPath = Join-Path $scriptDir "${scriptName}_Report_${timestampStr}.csv"

# --- Custom Logging Function ---
function Write-Log {
    param(
        [string]$Message,
        [ConsoleColor]$ForegroundColor = 'White'
    )
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timeStamp] $Message"
    
    Write-Host $logEntry -ForegroundColor $ForegroundColor
    Add-Content -Path $LogFilePath -Value $logEntry -Encoding UTF8
}

Write-Log "Initializing script..." 'Cyan'
Write-Log "Log file established at: $LogFilePath" 'DarkGray'
Write-Log "CSV report will be saved to: $CsvOutputPath" 'DarkGray'

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

Write-Log "Connecting to SharePoint Admin Center..." 'Cyan'
try {
    $adminConn = Connect-PnPOnline -Url $AdminCenterUrl -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId -ReturnConnection
} catch {
    Write-Log "CRITICAL: Failed to connect to Admin Center: $_" 'Red'
    exit
}

Write-Log "Retrieving all Site Collections (excluding OneDrive)... This may take a while for large tenants." 'Cyan'
$sites = Get-PnPTenantSite -Connection $adminConn | Where-Object { $_.Template -notlike "SPSPERS*" }

Write-Log "Found $($sites.Count) sites to process." 'Green'

foreach ($site in $sites) {
    Write-Log "Processing Site Collection: $($site.Url)" 'Yellow'

    try {
        # Connect to the specific Site Collection
        $siteConn = Connect-PnPOnline -Url $site.Url -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId -ReturnConnection
        
        # Get all subwebs including the root web using the site connection
        $webs = Get-PnPSubWeb -Connection $siteConn -Recurse -IncludeRootWeb
        
        foreach ($web in $webs) {
            Write-Log "  -> Checking Web: $($web.Url)" 'DarkGray'
            
            try {
                # Connect explicitly to the subweb
                $webConn = Connect-PnPOnline -Url $web.Url -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantId -ReturnConnection
                
                # Fetch document libraries using the explicit web connection							 
				$libraries = Get-PnPList -Connection $webConn -Includes BaseType, Hidden, Title, EnableVersioning, EnableMinorVersions, MajorVersionLimit, Id | 
					Where-Object { $_.BaseType -eq [Microsoft.SharePoint.Client.BaseType]::DocumentLibrary -and $_.Hidden -eq $false -and $_.Title -notin $ExcludedLibraries }

                foreach ($lib in $libraries) {
					try{
                    
						$conditionA = $lib.EnableVersioning -eq $true
						$conditionB = $lib.EnableMinorVersions -eq $false
						$conditionC = ($lib.MajorVersionLimit -eq 0 -or $lib.MajorVersionLimit -eq 500)

						if ($conditionA -and $conditionB -and $conditionC) {
							
							$previousSetting = if ($lib.MajorVersionLimit -eq 0) { "No Limit" } else { "Limit: $($lib.MajorVersionLimit)" }
							
							if ($SettingToApply -eq 'Automatic') {
								$targetSettingString = "Automatic"
								if ($Simulate) {
									$newSetting = "Simulate $targetSettingString"
								} else {
									
									# Use REST API to bypass CSOM property limitations
									<#
									$restUrl = "/_api/web/lists(guid'$($lib.Id)')"
									$payload = @{
										"__metadata" = @{ "type" = "SP.List" }
										"EnableAutoExpirationVersion" = $true
									} | ConvertTo-Json -Depth 5
									
									#Invoke-PnPSPRestMethod -Connection $webConn -Method Post -Url $restUrl -Content $payload -ContentType "application/json;odata=verbose" -AdditionalHeaders @{ "X-HTTP-Method" = "MERGE"; "IF-MATCH" = "*" } | Out-Null
									#>
									
									Set-PnPList -Connection $webConn -Identity $lib.Id -EnableAutoExpirationVersionTrim $true
									
									$newSetting = $targetSettingString
								}
                            } else {
                            # Basis-String für das Logging
                            $targetSettingString = "Major Limit: $NewMajorVersionLimit"
                            
                            # Splatting-Hashtable für Set-PnPList vorbereiten
                            $listParams = @{
                                Connection    = $webConn
                                Identity      = $lib.Id
                                MajorVersions = $NewMajorVersionLimit
                            }

                            # Nur hinzufügen, wenn der Parameter beim Skriptaufruf explizit mitgegeben wurde
                            if ($PSBoundParameters.ContainsKey('ExpireVersionsAfterDays')) {
                                $listParams.Add('ExpireVersionsAfterDays', $ExpireVersionsAfterDays)
                                $targetSettingString += " (Expire: $($ExpireVersionsAfterDays)d)"
                            }

                            if ($Simulate) {
                                $newSetting = "Simulate $targetSettingString"
                            } else {
                                # Aufruf mit der dynamischen Hashtable (@listParams statt -listParams)
                                Set-PnPList @listParams
                                $newSetting = $targetSettingString
                            }
                        }

							Write-Log "      [MATCH] Library '$($lib.Title)' - Prev: $previousSetting - New: $newSetting" 'Green'

							$results.Add([PSCustomObject]@{
								'Site Collection'  = $site.Url
								'Site'             = $web.Url
								'Library'          = $lib.Title
								'Previous setting' = $previousSetting
								'New setting'      = $newSetting
							})

						} else {
							Write-Log "      [SKIP] Library '$($lib.Title)' does not meet criteria." 'DarkGray'
						}
					} catch {
                        # Nested Catch: Logs the specific failing library and allows the web loop to continue
                        Write-Log "      [ERROR] Failed processing library '$($lib.Title)' (ID: $($lib.Id)). Error: $_" 'Red'
                    }					
                }
            } catch {
                Write-Log "      [ERROR] Failed processing web $($web.Url). Error: $_" 'Red'
            } finally {
                # Clean up the web connection
                $webConn = $null
            }
        }
    } catch {
        Write-Log "      [ERROR] Failed to process site $($site.Url). Error: $_" 'Red'
    } finally {
        # Clean up the site collection connection
        $siteConn = $null
    }
}

# Clean up admin connection
$adminConn = $null

# Export Results
if ($results.Count -gt 0) {
    Write-Log "Exporting $($results.Count) records to $CsvOutputPath..." 'Cyan'
    $results | Export-Csv -Path $CsvOutputPath -NoTypeInformation -Encoding UTF8
    Write-Log "Execution complete!" 'Green'
} else {
    Write-Log "No document libraries matched the criteria. CSV will not be generated." 'Yellow'
}