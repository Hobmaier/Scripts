$issuerID = "9a2182d2-2516-4b03-b1c0-ef1a133e49a2“
$tokenIssuer = Get-SPTrustedSecurityTokenIssuer | Where-Object { $_.NameId -match $issuerID }
$tokenIssuer