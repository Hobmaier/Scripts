Add-PSSnapin microsoft.sharepoint.powershell
$CertPath = 'C:\Install\MeetingMAnager\Contoso-Root-CA.cer'
$CertName = 'Contoso Root CA'

# Get the certificate
$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($CertPath)

# Make the certificate a trusted root authority in SharePoint
New-SPTrustedRootAuthority -Name $CertName -Certificate $certificate 