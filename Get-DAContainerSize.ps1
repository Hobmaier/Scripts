<#
.SYNOPSIS
    Script is used to report on the number of Sites per DocAve container
.DESCRIPTION
    This script will be used to check the total amount of Site Collections within a container.
    In large environments we recommend to not put in more than 15.000 Site Collections into 
    one container to avoid performance problems.
.EXAMPLE
    $cred = get-Credential
    Get-DAContainerSize -ControlHost "DocAveServer" -Username $cred.username -Password $cred.password
.COMPONENT
    AvePoint Cloud Records
#>
[CmdletBinding(DefaultParameterSetName='Parameter Set 1',
            SupportsShouldProcess=$true,
            PositionalBinding=$false,
            HelpUri = 'http://www.avepoint.com/',
            ConfirmImpact='Medium')]
param (

    #DocAve Control Host Server hostname
    [Parameter(Mandatory=$true)]
    [string]
    $ControlHost,
    
    #DocAve Server username with administrative permissions
    [Parameter(Mandatory=$true)]
    [string]
    $UserName,
    
    #DocAve Server password with administrative permissions
    [Parameter(Mandatory=$true)]
    [SecureString]
    $Password,

    #DocAve Control Server Port
    [Parameter(Mandatory=$false)]
    [string]
    $ControlPort = "14000",    

    #Define maximum number of Site Collections in container
    [Parameter(Mandatory=$false)]
    [int]
    $ContainerSize = 15000,

    # Optional - Log Directory
    [Parameter(Mandatory=$false)]
    [string]
    $LogDir = 'Logs'    
)

# V 1.0     06/22/2021  Initial Release

$currentTime=Get-Date -Format 'yyyy-MM-dd_HH-mm-ss';
$LogFileName = "Get-DAContainerSize"+$currentTime+".log";
$logName = Join-Path -Path $LogDir -ChildPath $LogFileName;
# Requires DocAve PowerShell to be installed on the systems running this script
# Import DocAve Module / PowerShell
import-module DocAveModule -ErrorAction Stop


function Main {
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1',
                SupportsShouldProcess=$true,
                PositionalBinding=$false,
                HelpUri = 'http://www.avepoint.com.com/',
                ConfirmImpact='Medium')]
    Param ()
    
    begin {
        CreateLogPath;
        OutputToHostAndLog "---- Start script ----"
    }
    
    process {
        if ($pscmdlet.ShouldProcess("Target", "Operation")) {
            ### Login to the control service
            try {
                Login-DAManager -ControlHost $ControlHost -ControlPort $ControlPort -Username $UserName -Password $Password
            }
            catch {
                OutputToHostAndLog "Login to DocAve failed $($Error[0])"
                break
            }
            

            try {
                
                $Containers = Get-DASPOnlineSitesGroup
                OutputToHostAndLog 'Load containers'
                OutputToHostAndLog "Container count:  [$($Containers.Count)] "

                foreach ($Container in $Containers) {
                    If($Container.Sites.Count -le $ContainerSize) 
                    {
                        OutputToHostAndLog "Container OK: $($Container.Name) has $($Container.Sites.Count)"
                    } else {
                        OutputToHostAndLog "Container FAIL: $($Container.Name) has $($Container.Sites.Count)"
                    }

                }                

            }
            catch {
                OutputToHostAndLog "Could not get containers"
                break
            }
        }
    }
    
    end {
        OutputToHostAndLog "---- End script ----"
    }
}

function CreateLogPath()
{
	if(!(Test-Path $script:LogDir))
	{
		mkdir $script:LogDir | Out-Null
	}
}

function OutputToHostAndLog($str)
{
	Write-Host $str;
	OutputToLog $str;
}

function OutputToLog($str)
{
    $dateTime=Get-Date -Format 'yyyy-MM-dd HH:mm:ss';
	$message=$dateTime+" "+$str;
    $message | Out-File -Append -filepath $logName;
}



Main