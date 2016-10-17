Get-SPTrustedSecurityTokenIssuer | ?{$_.RegisteredIssuerName -match "b0b22215-d254-430b-bd86-f689605c7621“} | Remove-SPTrustedSecurityTokenIssuer

Get-SPTrustedRootAuthority | ?{$_.Name -eq "MeetingManager"} | Remove-SPTrustedRootAuthority
