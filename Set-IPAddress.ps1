
function SetNWAdapter {
    $NWAdapter = $Args[0]
    $IPAddress = $Args[1]
    $SubNet = $Args[2]
    $DefaultGW = $Args[3]
    $DNS = $Args[4]

    #Clear adapter settings
    $nethelp = Get-NetIPConfiguration -InterfaceAlias $NWAdapter
    $DefaultGWold = $nethelp.IPv4DefaultGateway.NextHop
    if ($DefaultGWold) {
        Remove-NetIPAddress -InterfaceAlias $NWAdapter -IpAddress * -DefaultGateway $DefaultGWold -Confirm:$false -ErrorAction SilentlyContinue
    }
    else {
    Remove-NetIPAddress -InterfaceAlias $NWAdapter -IpAddress * -Confirm:$false
    }
    Set-DnsClientServerAddress -InterfaceAlias $NWAdapter -ResetServerAddresses

    #Write new adapter settings
    if ($DefaultGW){
        New-NetIPAddress -InterfaceAlias $NWAdapter -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway $DefaultGW
    }
    else {
        New-NetIPAddress -InterfaceAlias $NWAdapter -IPAddress $IPAddress -PrefixLength 24
    }
    if ($DNS) {
        Set-DnsClientServerAddress -InterfaceAlias $NWAdapter -ServerAddresses $DNS
    }
}


# Main

Start-Sleep -Seconds 60

SetNWAdapter 'Ethernet' '178.63.97.11' '255.255.255.192' '178.63.97.1' '213.133.98.98'
#DNSServer            : 213.133.98.98
                       #213.133.99.99
                       #213.133.100.100

Start-Sleep -Seconds 300

$adapters = Get-NetIPConfiguration
foreach ($adapter in $adapters)
{
    SetNWAdapter $adapter.InterfaceAlias '178.63.97.11' '255.255.255.192' '178.63.97.1' '213.133.98.98'
    Start-Sleep -Seconds 500
}
