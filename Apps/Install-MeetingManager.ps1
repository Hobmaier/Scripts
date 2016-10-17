$publicCertPath = "C:\inetpub\wwwroot\MeetingManager\MeetingManager.cer"
$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($publicCertPath)
New-SPTrustedRootAuthority -Name "MeetingManager" -Certificate $certificate
$Friendlyname = 'MeetingManager'
$realm = Get-SPAuthenticationRealm
$specificIssuerId = "2cab2030-d5fd-4cf2-90ca-abbc6b8e1667"
$fullIssuerIdentifier = $specificIssuerId + '@' + $realm 
New-SPTrustedSecurityTokenIssuer -Name "MeetingManager" -Certificate $certificate -RegisteredIssuerName $fullIssuerIdentifier –IsTrustBroker
#iisreset 

$capath = "C:\inetpub\wwwroot\MeetingManager\Contoso-Root-CA.cer"
$cacertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($capath)
New-SPTrustedRootAuthority -Name "Contoso Internal Root CA" -Certificate $cacertificate