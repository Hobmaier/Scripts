# Note https://w3c.github.io/web-performance/specs/HAR/Overview.html


$files = gci -Path c:\Temp\Log\Performance_08.04.2024\ -Filter *.har -Recurse
$CSV = "C:\temp\log\Performance.csv"
"Filename;StartedDateTime;Title;OnContentLoaded;OnLoad;TransferSize;Total Time;Connection stalled;DNS;SSL;Connecting;Send;Waiting for Server;Download;Queueing;Proxy;MultipleNavigation" | Out-File -Append -filepath $CSV -Encoding utf8;


foreach ($file in $files) {
    write-host $file.fullname

    $fc = get-content $file.fullname -ErrorAction stop | convertfrom-json

    $fc.log.pages.startedDateTime
    $fc.log.pages.title
<#

    Decription pageTimings

This object describes timings for various events (states) fired during the page load. All times are specified in milliseconds. If a time info is not available appropriate field is set to -1.

"pageTimings": {
    "onContentLoad": 1720,
    "onLoad": 2500,
    "comment": ""
}
onContentLoad [number, optional] - Content of the page loaded. Number of milliseconds since page load started (page.startedDateTime). Use -1 if the timing does not apply to the current request.
onLoad [number,optional] - Page is loaded (onLoad event fired). Number of milliseconds since page load started (page.startedDateTime). Use -1 if the timing does not apply to the current request.
comment [string, optional] (new in 1.2) - A comment provided by the user or the application.
Depeding on the browser, onContentLoad property represents DOMContentLoad event or document.readyState == interactive.
#>

    #$fc.log.pages.pageTimings.OnContentLoad 
    #$fc.log.pages.pageTimings.onLoad
    #Export-Csv -path $CSV -Delimiter ";" -InputObject "$($fc.log.pages.startedDateTime);$($fc.log.pages.title);$($fc.log.pages.pageTimings.OnContentLoad);$($fc.log.pages.pageTimings.onLoad)" -Append

    [int]$_transferSize = 0
    [int]$time =0
    [int]$timingsblocked = 0
    [int]$dns = 0
    [int]$ssl = 0
    [int]$connect = 0
    [int]$send = 0
    [int]$wait = 0
    [int]$receive = 0
    [int]$queueing = 0
    [int]$proxy = 0      

    foreach ($entry in $fc.log.entries) {
        #blocked [number, optional] - Time spent in a queue waiting for a network connection. Use -1 if the timing does not apply to the current request.
        #dns [number, optional] - DNS resolution time. The time required to resolve a host name. Use -1 if the timing does not apply to the current request.
        #connect [number, optional] - Time required to create TCP connection. Use -1 if the timing does not apply to the current request.
        #send [number] - Time required to send HTTP request to the server.
        #wait [number] - Waiting for a response from the server.
        #receive [number] - Time required to read entire response from the server (or cache).
        #ssl [number, optional] (new in 1.2) - Time required for SSL/TLS negotiation. If this field is defined then the time is also included in the connect field (to ensure backward compatibility with HAR 1.1). Use -1 if the timing does not apply to the current request.
        #comment [string, optional] (new in 1.2) - A comment provided by the user or the application.        
        $csventry = [PSCustomObject]@{
            _transferSize = $entry.response._transferSize
            time = $entry.time #total time
            timingsblocked = $entry.timings.blocked #Connection start - stalled
            dns = $entry.timings.dns #
            ssl = $entry.timings.ssl
            connect = $entry.timings.connect
            send = $entry.timings.send #Request sent
            wait = $entry.timings.wait #Waiting for server response
            receive = $entry.timings.receive #Content Download
            queueing = $entry.timings._blocked_queueing
            proxy = $entry.timings._blocked_proxy #Connection start - Proxy negotiation            
        }

        #$csventry._transferSize
        If($_transferSize -ne -1)
            {$_transferSize = $_transferSize + [int]$entry.response._transferSize}
        If ($time -ne -1){
            $time = $time + [int]$entry.time #total time
        }
        If ($timingsblocked -ne -1) {
            $timingsblocked = $timingsblocked + [int]$entry.timings.blocked #Connection start - stalled
        }
        If ($dns -ne -1){
            $dns = $dns + [int]$entry.timings.dns #
        }
        If ($ssl -ne -1) {
            $ssl = $ssl + [int]$entry.timings.ssl 
        }
        If ($connect -ne -1) {
            $connect = $connect + [int]$entry.timings.connect 
        }
        $send = $send + [int]$entry.timings.send #Request sent
        $wait = $wait + [int]$entry.timings.wait #Waiting for server response
        $receive = $receive + [int]$entry.timings.receive #Content Download
        $queueing = $queueing + [int]$entry.timings._blocked_queueing
        $proxy = $proxy + [int]$entry.timings._blocked_proxy #Connection start - Proxy negotiation          

        #Export-Csv -path $CSV -Delimiter ";" -InputObject $csventry -Append

    }
    #If there's an array like multiple navigation in one har, use the first navigation for starttime, title, onContentLoad and onLoad. Mark it as MultipleNavigation 1 in CSV then.
    If (($fc.log.pages).count -le 1)
    {
        $Message = "$($file.fullname);$($fc.log.pages.startedDateTime);$($fc.log.pages.title);$([int]$fc.log.pages.pageTimings.OnContentLoad);$([int]$fc.log.pages.pageTimings.onLoad);$($_transferSize);$($time);$($timingsblocked);$($dns);$($ssl);$($connect);$($send);$($wait);$($receive);$($queueing);$($proxy);0"
    } else {
        #Write-Host "First Title $($fc.log.pages.title[0])"
        $Message = "$($file.fullname);$($fc.log.pages.startedDateTime[0]);$($fc.log.pages.title[0]);$([int]$fc.log.pages.pageTimings.OnContentLoad[0]);$([int]$fc.log.pages.pageTimings.onLoad[0]);$($_transferSize);$($time);$($timingsblocked);$($dns);$($ssl);$($connect);$($send);$($wait);$($receive);$($queueing);$($proxy);1"
    }
    $Message | Out-File -Append -filepath $CSV -Encoding utf8;    
}