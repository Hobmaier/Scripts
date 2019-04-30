#Purpose Point to Site Certificate
# https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-certificates-point-to-site
Write-Host "Create Root CA certificate"
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject "CN=HobiIssueingRootCA" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

Write-Host "Create Client certificate"
New-SelfSignedCertificate -Type Custom -DnsName P2SClientCert -KeySpec Signature `
-Subject "CN=P2SClientCert" -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")