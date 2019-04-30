# Used for bulk change of Domain Suffix 
# In preparation for Azure AD Connect
# Run on local DC
Import-Module ActiveDirectory

$oldSuffix = "contoso.local"
$newSuffix = "test.com"
$ou = "OU=Contoso,DC=contoso,DC=local"

Get-ADUser -SearchBase $ou -filter * | ForEach-Object {
    Write-Host "Working on" $_.UserPrincipalName
    $newUpn = $_.UserPrincipalName.Replace($oldSuffix,$newSuffix)
    $_ | Set-ADUser -UserPrincipalName $newUpn
}