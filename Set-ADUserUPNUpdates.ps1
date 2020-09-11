# Used for bulk change of Domain Suffix 
# In preparation for Azure AD Connect
# Run on local DC
Import-Module ActiveDirectory -ErrorAction Stop

#Import CSV, remove header line
$csv = Import-Csv -Path ".\AD_UserUpdates.csv" -Delimiter ";" -Header 'givenName','sn','initials','sAMAccountName','mail','streetAddress','l','st','postalCode','co','title','manager','company','department','physicalDeliveryOfficeName','telephoneNumber','facsimileTelephoneNumber','mobile','newMail','wWWHomePage'

foreach ($user in $csv) {
    try {
        Write-Host "Working on user: $($user.samAccountName)"
        #Add properties which you would like to compare against
        $ADUser = Get-ADUser -identity $user.sAMAccountName -Properties proxyAddresses,telephoneNumber,manager,givenName,sn,initials,streetAddress,l,st,postalCode,co,title,manager,company,department,physicalDeliveryOfficeName,facsimileTelephoneNumber,mobile,wWWHomePage -erroraction stop
        Set-ADUser -Identity $ADUser.ObjectGUID `
            -Add @{proxyAddresses="SMTP:$($user.newMail)","SIP:$($user.newMail)","smtp:$($user.mail)"} `
            -Remove @{proxyAddresses="SMTP:$($user.mail)","SIP:$($user.mail)"} `
            -EmailAddress $user.newMail `
            -UserPrincipalName $user.newMail  `
            -erroraction stop
        Write-Host "  UPN updated"
        #Now do optional things
        #Phone
        If(($ADUser.telephoneNumber -ne $user.telephoneNumber) -and ($user.telephoneNumber.Length -gt 0))
        {
            Write-Host "  Update telephoneNumber to: $($user.telephoneNumber)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{telephoneNumber=$user.telephoneNumber}
        }

        If(($ADUser.givenName -ne $user.givenName) -and ($user.givenName.Length -gt 0))
        {
            Write-Host "  Update givenName to: $($user.givenName)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{givenName=$user.givenName}
        }

        If(($ADUser.sn -ne $user.sn) -and ($user.sn.Length -gt 0))
        {
            Write-Host "  Update sn to: $($user.sn)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{sn=$user.sn}
        }

        If(($ADUser.initials -ne $user.initials) -and ($user.initials.Length -gt 0))
        {
            Write-Host "  Update initials to: $($user.initials)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{initials=$user.initials}
        }

        If(($ADUser.streetAddress -ne $user.streetAddress) -and ($user.streetAddress.Length -gt 0))
        {
            Write-Host "  Update streetAddress to: $($user.streetAddress)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{streetAddress=$user.streetAddress}
        }

        If(($ADUser.l -ne $user.l) -and ($user.l.Length -gt 0))
        {
            Write-Host "  Update l to: $($user.l)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{l=$user.l}
        }

        If(($ADUser.st -ne $user.st) -and ($user.st.Length -gt 0))
        {
            Write-Host "  Update st to: $($user.st)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{st=$user.st}
        }

        If(($ADUser.postalCode -ne $user.postalCode) -and ($user.postalCode.Length -gt 0))
        {
            Write-Host "  Update postalCode to: $($user.postalCode)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{postalCode=$user.postalCode}
        }

        If(($ADUser.co -ne $user.co) -and ($user.co.Length -gt 0))
        {
            Write-Host "  Update co to: $($user.co)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{co=$user.co}
        }

        If(($ADUser.title -ne $user.title) -and ($user.title.Length -gt 0))
        {
            Write-Host "  Update title to: $($user.title)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{title=$user.title}
        }

        If(($ADUser.company -ne $user.company) -and ($user.company.Length -gt 0))
        {
            Write-Host "  Update company to: $($user.company)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{company=$user.company}
        }

        If(($ADUser.department -ne $user.department) -and ($user.department.Length -gt 0))
        {
            Write-Host "  Update department to: $($user.department)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{department=$user.department}
        }

        If(($ADUser.physicalDeliveryOfficeName -ne $user.physicalDeliveryOfficeName) -and ($user.physicalDeliveryOfficeName.Length -gt 0))
        {
            Write-Host "  Update physicalDeliveryOfficeName to: $($user.physicalDeliveryOfficeName)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{physicalDeliveryOfficeName=$user.physicalDeliveryOfficeName}
        }

        If(($ADUser.facsimileTelephoneNumber -ne $user.facsimileTelephoneNumber) -and ($user.facsimileTelephoneNumber.Length -gt 0))
        {
            Write-Host "  Update facsimileTelephoneNumber to: $($user.facsimileTelephoneNumber)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{facsimileTelephoneNumber=$user.facsimileTelephoneNumber}
        }

        If(($ADUser.mobile -ne $user.mobile) -and ($user.mobile.Length -gt 0))
        {
            Write-Host "  Update mobile to: $($user.mobile)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{mobile=$user.mobile}
        }

        If(($ADUser.wWWHomePage -ne $user.wWWHomePage) -and ($user.wWWHomePage.Length -gt 0))
        {
            Write-Host "  Update wWWHomePage to: $($user.wWWHomePage)"
            Set-ADUser -Identity $ADUser.ObjectGUID -Replace @{wWWHomePage=$user.wWWHomePage}
        }

        
        #Manager
        If(!$user.manager.startswith("DN="))
        {
            #Search for user by name and samaccountname
            $usermanagersource = $user.manager
            $ADUserManager = get-aduser -Filter '(Name -eq $usermanagersource) -or (SamAccountName -eq $usermanagersource)'
        } else {
            #or if it starts with DN= use the path directly
            $ADUserManager = get-aduser -Identity "$($user.manager)"
        }
        #Verify something is in the variable
        If($ADUserManager)
        {
            If($ADUser.Manager -ne $ADUserManager.DistinguishedName)
            {
                Write-Host "  Update Manager"
                Set-ADUser -Identity $ADUser.ObjectGUID -Manager $ADUserManager.DistinguishedName
            }
        } else {
            Write-Host "  Manager update failed"
        }
        
    }
    catch {
        Write-Host "User not found or failed: $($user.sAMAccountName)"
    }
 
}

Write-Host "Now run sync on AzureAD Connect"