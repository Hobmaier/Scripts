Import-Module MSOnline -erroracction stop

Connect-MsolService -ErrorAction Stop

#Import CSV, remove header line
$csv = Import-Csv -Path ".\MT_plus.csv" -Delimiter ";" -Header 'givenName','sn','initials','sAMAccountName','mail','streetAddress','l','st','postalCode','co','title','manager','company','department','physicalDeliveryOfficeName','telephoneNumber','facsimileTelephoneNumber','mobile','newMail','wWWHomePage'

foreach ($user in $csv) {
    try {
        Write-Host "Working on user $($user.sAMAccountName)"
        Get-MsolUser -UserPrincipalName $user.mail | Set-MsolUserPrincipalName -NewUserPrincipalName $user.NewMail
        #Set-MsolUserPrincipalName -UserPrincipalName $user.mail -NewUserPrincipalName $user.newMail
    }
    catch {
        Write-Host "Failed for user $($user.mail)"
    }
}