
<# 
.SYNOPSIS
  Finds all site collections that contain at least one document library with a column named "RevIMBCS".
  Writes the site collection URL to CSV and TXT outputs.

.DESCRIPTION
  Uses PnP.PowerShell to:
    1) Connect to the SharePoint Admin Center.
    2) Enumerate all site collections (optionally excluding OneDrive).
    3) Traverse all webs in each site collection (root + subwebs).
    4) Check all document libraries for a field whose InternalName or Title equals the specified column name.
    5) If found, write the site collection URL once to both CSV and TXT.

.PARAMETER AdminCenterUrl
  The SharePoint Admin Center URL, e.g. https://contoso-admin.sharepoint.com

.PARAMETER ColumnName
  The column (field) name to search for (compares against both InternalName and Title). Default: RevIMBCS

.PARAMETER OutputCsv
  Path to the CSV file (created if not exists). Default: .\Sites_With_<ColumnName>_<timestamp>.csv

.PARAMETER OutputTxt
  Path to the TXT file (created if not exists). Default: same basename as CSV, with .txt extension

.PARAMETER Interactive
  Use interactive auth (recommended; requires PnP Management Shell app consent). If not specified, certificate auth is used.

.PARAMETER TenantName
  Your tenant (e.g., contoso.onmicrosoft.com). Required for app-only auth.

.PARAMETER ClientId
  Azure AD application (client) ID. Required for app-only auth.

.PARAMETER Thumbprint
  Certificate thumbprint in CurrentUser/LocalMachine store (alternative to CertificatePath). App-only.

.PARAMETER CertificatePath
  Path to a .pfx certificate (alternative to Thumbprint). App-only.

.PARAMETER CertificatePassword
  SecureString for the .pfx certificate password (required when using CertificatePath). App-only.

.PARAMETER IncludeOneDrive
  Include OneDrive for Business site collections (off by default).

.NOTES
  Requires: PnP.PowerShell (Install-Module PnP.PowerShell)
  Role: SharePoint Administrator (for tenant enumeration).
  For interactive: use the "PnP Management Shell" app consented in your tenant.
#>

#Requires -Modules PnP.PowerShell

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$AdminCenterUrl,  # e.g. https://contoso-admin.sharepoint.com

    [string]$ColumnName = "RevIMBCS",

    [string]$OutputCsv = (Join-Path -Path (Get-Location) -ChildPath ("Sites_With_{0}_{1}.csv" -f $ColumnName, (Get-Date -Format 'yyyyMMdd_HHmmss'))),
    [string]$OutputTxt = $null,

    [switch]$Interactive,
	[string]$RedirectUri = "http://localhost",

    # Common
    [Parameter(Mandatory = $true)]
    [string]$ClientId,
	
	# App-only parameters (used when -Interactive is NOT specified)
	[Parameter(Mandatory = $false)]
    [string]$TenantName,       # e.g., contoso.onmicrosoft.com
    [string]$Thumbprint,
    [string]$CertificatePath,
    [SecureString]$CertificatePassword,

    [switch]$IncludeOneDrive
)

begin {
    if (-not $OutputTxt) {
        $OutputTxt = [IO.Path]::ChangeExtension($OutputCsv, ".txt")
    }

    # Create/clear output files
    if (Test-Path $OutputCsv) { Remove-Item $OutputCsv -Force }
    if (Test-Path $OutputTxt) { Remove-Item $OutputTxt -Force }
    New-Item -Path $OutputTxt -ItemType File -Force | Out-Null

    Write-Host "Output CSV: $OutputCsv"
    Write-Host "Output TXT: $OutputTxt"

    function Connect-Admin {
        param([string]$Url)

        if ($Interactive) {
			# Public client interactive using YOUR app registration (no certificate)
            return (Connect-PnPOnline -Url $Url -ApplicationId $ClientId -ReturnConnection)

        }
        else {
            if (-not $TenantName -or -not $ClientId -or (-not $Thumbprint -and -not $CertificatePath)) {
                throw "For app-only auth, specify -TenantName, -ClientId and either -Thumbprint or -CertificatePath (+ -CertificatePassword)."
            }
            if ($Thumbprint) {
                return (Connect-PnPOnline -Url $Url -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantName -ReturnConnection)
            }
            else {
                return (Connect-PnPOnline -Url $Url -ClientId $ClientId -CertificatePath $CertificatePath -CertificatePassword $CertificatePassword -Tenant $TenantName -ReturnConnection)
            }
        }
    }

    function Connect-Site {
        param([string]$Url)

        if ($Interactive) {
			return (Connect-PnPOnline -Url $Url -Connection $adminConn)
            #return (Connect-PnPOnline -Url $Url -ApplicationId $ClientId -ReturnConnection)
        }
        else {
            if ($Thumbprint) {
                return (Connect-PnPOnline -Url $Url -ClientId $ClientId -Thumbprint $Thumbprint -Tenant $TenantName -ReturnConnection)
            }
            else {
                return (Connect-PnPOnline -Url $Url -ClientId $ClientId -CertificatePath $CertificatePath -CertificatePassword $CertificatePassword -Tenant $TenantName -ReturnConnection)
            }
        }
    }

    function Is-DocumentLibrary {
        param($List)
        return ($List.BaseType -eq "DocumentLibrary" -or $List.BaseType -eq 1 -or $List.BaseTemplate -eq 101)
    }

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
}

process {
    Write-Host "Connecting to Admin Center: $AdminCenterUrl ..."
    $adminConn = $null
    try {
        $adminConn = Connect-Admin -Url $AdminCenterUrl
    }
    catch {
        Write-Error "Failed to connect to Admin Center. $_"
        break
    }

    try {
        Write-Host "Retrieving tenant site collections..."
        $sites = Get-PnPTenantSite -Connection $adminConn -IncludeOneDriveSites:$IncludeOneDrive -ErrorAction Stop

        if (-not $IncludeOneDrive) {
            $sites = $sites | Where-Object { $_.Url -notmatch '-my\.sharepoint\.com' }
        }

        $total = $sites.Count
        Write-Host "Sites to scan (root web only): $total"
        $index = 0

        foreach ($site in $sites) {
            $index++
            Write-Progress -Activity "Scanning tenant (root webs)" -Status "[$index/$total] $($site.Url)" -PercentComplete (($index / $total) * 100)

            if ($site.LockState -and $site.LockState -ne "Unlock") {
                Write-Verbose "Skipping locked site: $($site.Url) [$($site.LockState)]"
                continue
            }

            $siteConn = $null
            $siteHasColumn = $false

            try {
                $siteConn = Connect-Site -Url $site.Url

                # --- ROOT WEB ONLY ---
                # Get lists from the root web (no subwebs)
                $rootLists = Get-PnPList -Connection $siteConn -Includes BaseType, BaseTemplate, RootFolder -ErrorAction Stop
                $docLibs = $rootLists | Where-Object { Is-DocumentLibrary $_ }

                foreach ($lib in $docLibs) {
                    $field = Get-PnPField -Connection $siteConn -List $lib -ErrorAction SilentlyContinue |
                        Where-Object { $_.InternalName -ieq $ColumnName -or $_.Title -ieq $ColumnName } |
                        Select-Object -First 1

                    if ($null -ne $field) {
                        $siteHasColumn = $true
                        break
                    }
                }

                if ($siteHasColumn) {
                    [PSCustomObject]@{
                        SiteUrl = $site.Url
                    } | Export-Csv -Path $OutputCsv -Append -NoTypeInformation -Encoding UTF8

                    Add-Content -Path $OutputTxt -Value $site.Url
                    Write-Host "[FOUND @ Root] $($site.Url)" -ForegroundColor Green
                }
                else {
                    Write-Host "[NO MATCH @ Root] $($site.Url)" -ForegroundColor DarkGray
                }
            }
            catch {
                Write-Warning "Error scanning site $($site.Url): $($_.Exception.Message)"
            }
            finally {
                if ($siteConn) { $siteConn = $null }
            }

            Start-Sleep -Milliseconds 100
        }

        Write-Host "Done. Results saved to:"
        Write-Host "  CSV: $OutputCsv"
        Write-Host "  TXT: $OutputTxt"
    }
    catch {
        Write-Error "Failed during tenant enumeration or scanning. $_"
    }
    finally {
        if ($adminConn) { Disconnect-PnPOnline -ErrorAction SilentlyContinue }
        $sw.Stop()
        Write-Host ("Elapsed: {0:c}" -f $sw.Elapsed)
    }
}