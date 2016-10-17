$issuerID = "2cab2030-d5fd-4cf2-90ca-abbc6b8e1667”
$publicCertPath = "C:\inetpub\wwwroot\MeetingManager\MeetingManager.cer"
$siteUrl = "https://portal.contoso.com/sites/meetings”
$web = Get-SPWeb $siteUrl
$certificate = Get-PfxCertificate $publicCertPath
$realm = Get-SPAuthenticationRealm -ServiceContext $web.Site
$fullAppIdentifier = $issuerId + '@' + $realm
New-SPTrustedRootAuthority -Name "MeetingManager" -Certificate $certificate
New-SPTrustedSecurityTokenIssuer -Name "MeetingManager" -Certificate $certificate -RegisteredIssuerName $fullAppIdentifier
Register-SPAppPrincipal -NameIdentifier $fullAppIdentifier -Site $web -DisplayName "Meeting Manager"
#iisreset