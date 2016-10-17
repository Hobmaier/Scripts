Add-PSSnapin Microsoft.SharePoint.PowerShell


$CertPath = "C:\inetpub\wwwroot\MeetingManager\MeetingManager.cer"
$CertName ="MeetingManager"
$TokenIssuerFriendlyName = "MeetingManager (IsTrustBroker)"

# Stop if there's an error
$ErrorActionPreference = "Stop"

# Ensure friendly name is short enough
if ($TokenIssuerFriendlyName.Length -gt 50)
{
    throw "-TokenIssuerFriendlyName must be unique name of no more than 50 characters."
} 

# Get the certificate
$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath)

# Make the certificate a trusted root authority in SharePoint
New-SPTrustedRootAuthority -Name $CertName -Certificate $certificate 

# Get the GUID of the authentication realm
$realm = Get-SPAuthenticationRealm

# Generate a unique specific issuer ID
$specificIssuerId = [System.Guid]::NewGuid().ToString()

# Create full issuer ID in the required format
$fullIssuerIdentifier = $specificIssuerId + '@' + $realm 

# Create issuer name
if ($TokenIssuerFriendlyName.Length -ne 0)
{
    $tokenIssuerName = $TokenIssuerFriendlyName
}
else
{
    $tokenIssuerName = "Hi-Trust Apps " + $specificIssuerId 
}

# Register the token issuer (ohne IsTrustBroker)
New-SPTrustedSecurityTokenIssuer -Name $tokenIssuerName -Certificate $certificate -RegisteredIssuerName $fullIssuerIdentifier -IsTrustBroker

# Register the token issuer (mit IsTrustBroker)
#New-SPTrustedSecurityTokenIssuer -Name $tokenIssuerName -Certificate $certificate -RegisteredIssuerName $fullIssuerIdentifier –IsTrustBroker

# Output the specific issuer ID to a file in the same folder as this script. The file should be given to the developer of the high-trust app for SharePoint.
$file = "SecureTokenIssuerID_"+$CertName+".txt"
$specificIssuerId | Out-File -FilePath $file


