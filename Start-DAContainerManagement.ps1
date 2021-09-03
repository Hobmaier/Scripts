<#
.SYNOPSIS
    Script is used to rebalance Site Collections across multiple DocAve containers
.DESCRIPTION
    This script will be used to check the total amount of Site Collections within a container.
    In large environments we recommend to not put in more than 15.000 Site Collections into 
    one container to avoid performance problems.
.EXAMPLE
    $cred = get-Credential
    Start-DAContainerManagement -SourceContainerNameToCheck "Container to balance" -ContainerPrefix "SPO" -AppProfile "SPOProfile" -ControlHost "DocAveServer" -Username $cred.username -Password $cred.password
.COMPONENT
    AvePoint Cloud Records
#>
[CmdletBinding(DefaultParameterSetName='Parameter Set 1',
            SupportsShouldProcess=$true,
            PositionalBinding=$false,
            HelpUri = 'http://www.avepoint.com.com/',
            ConfirmImpact='Medium')]
param (
    # Provide Source container name to check against
    [Parameter(Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $SourceContainerNameToCheck,
    
    #Define Container pre fix name. Date will be added to it when creating containers
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $ContainerPreFix,

    # App Profile to use to connect to SharePoint Site
    [Parameter(Mandatory=$true)]
    [string]
    $AppProfile,

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

    # Optional - DocAve Agent Group to use, otherwise default group
    [Parameter(Mandatory=$false)]
    [string]
    $AgentGroup = 'DEFAULT_SHAREPOINT_SITES_AGENT_GROUP', 

    #Define maximum number of Site Collections in container
    [Parameter(Mandatory=$false)]
    [int]
    $ContainerSize = 15000
)
$currentTime=Get-Date -Format 'yyyy-MM-dd_HH-mm-ss';
$LogDir="Logs";
$logName=$LogDir+"\Start-DAContainerManagement"+$currentTime+".log";
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
                $SourceContainer = Get-DASPOnlineSitesGroup -Name  $SourceContainerNameToCheck
                OutputToHostAndLog "Source Site Collection count:  [$($SourceContainer.Sites.Count)] in Container [$($SourceContainerNameToCheck)]"
            }
            catch {
                OutputToHostAndLog "No DocAve Source Container with name [$($SourceContainer.Sites.Count)] found"
                break
            }


            If ($SourceContainer.Sites.Count -ge 1)
            {
                OutputToHostAndLog 'More than one Site Collection found in source container.'
                #Try to move into existing containers
                
                foreach ($Site in $SourceContainer.Sites)
                {
                    OutputToHostAndLog 'Load containers'
                    #Performance might be better if running next line outside of this loop
                    #But needs to determine amount of sites available within container to stay within the limits of 15.000
                    $Containers = Get-DASPOnlineSitesGroup
                    OutputToHostAndLog "Containers count: $($Containers.count)"                    
                    #Rebalance into new Container
                    #Find a container with remaining capacity
                    $ContainerFound = $false
                    foreach ($Container in $Containers) {
                        If(($Container.Sites.Count -le $ContainerSize) -and ($Container.Name -ne $SourceContainer.Name) -and ($Container.GroupType -eq $SourceContainer.GroupType) -and ($ContainerFound -eq $false) -and ($Container.Name -like "$ContainerPreFix*" ))
                        {
                            #Determine size of container
                            #$i = $Container.Count - $ContainerSize

                            #Add Site Collections
                            Remove-DASiteFromContainer -ContainerName $SourceContainer.Name -SiteCollectionURL $Site.URL
                            Add-DASiteToContainer -ContainerName $Container.Name -SiteCollectionURL $Site.URL -AppManagementProfile $AppProfile
                            $ContainerFound = $true
                        }
    
                    }   
                    If ($ContainerFound -eq $false) {
                        #CreateContainer and put Site Collection into it
                        $TodaysDate = Get-Date -Format 'yyyy-MM-dd hh:mm'


                        $NewContainerName = "$($ContainerPreFix)_$($TodaysDate)"
                        OutputToHostAndLog "Create container [$($NewContainerName)]"
                        $CreatedContainer = New-DAContainer -ContainerName $NewContainerName -GroupType $SourceContainer.GroupType

                        #Add Site Collections
                        Remove-DASiteFromContainer -ContainerName $SourceContainer.Name -SiteCollectionURL $Site.URL
                        Add-DASiteToContainer -ContainerName $CreatedContainer.Name -SiteCollectionURL $Site.URL -AppManagementProfile $AppProfile 
                        
                    }
                }
            }
        }
    }
    
    end {
        OutputToHostAndLog "---- End script ----"
    }
}

function New-DAContainer {
    param (
        $ContainerName,
        $GroupType
    )
    $NewContainer = Get-DABlankSPOnlineSitesGroup
    $NewContainer.Name = $ContainerName
    $NewContainer.Description = "Dynamic Container to hold not more than $($ContainerSize) Site Collections"
    $NewContainer.AgentGroupName = $AgentGroup
    $NewContainer.GroupType = $GroupType

    OutputToHostAndLog "Create new container [$($NewContainer)] [$($NewContainer.AgentGroupName)] [$($NewContainer.GroupType = $GroupType)]"
    try {
        New-DASPOnlineSitesGroup -SitesGroup $NewContainer
    }
    catch {
        Write-Host ("An error occurred. [$($NewContainer)]`n" + "$($_.Exception.Message)");
		OutputToLog ("An error occurred. [$($NewContainer)]`n" + "$($_.Exception.ToString())`n$($_.ScriptStackTrace)")
    }
    
    return $NewContainer

}

function Add-DASiteToContainer {
    param (
        $ContainerName,
        $SiteCollectionURL,
        $AppManagementProfile
    )
    #Add Site Collection
    $DocAveContainer = Get-DASPOnlineSitesGroup -Name $ContainerName
    $site = $DocAveContainer.GetBlankSiteCollectionConfiguration()
    $site.Url = $SiteCollectionURL
    $site.SetAppManagementProfile($AppManagementProfile)
    OutputToHostAndLog "Add Site Collection to Container [$($site.url)] [$($DocAveContainer.Name)]"
    try {
        $DocAveContainer.AddSiteCollection($site)    
    }
    catch {
        Write-Host ("An error occurred. [$($site.Url)]`n" + "$($_.Exception.Message)");
		OutputToLog ("An error occurred. [$($site.Url)]`n" + "$($_.Exception.ToString())`n$($_.ScriptStackTrace)")
    }
    
}
function Remove-DASiteFromContainer {
    param (
        $ContainerName,
        $SiteCollectionURL
    )
    #Add Site Collection
    $DocAveContainer = Get-DASPOnlineSitesGroup -Name $ContainerName
    OutputToHostAndLog "Remove Site Collection from Container [$($SiteCollectionURL)] [$($DocAveContainer.Name)]"
    try {
        $DocAveContainer.DeleteSiteCollection($SiteCollectionURL)
    }
    catch {
        Write-Host ("An error occurred. [$($SiteCollectionURL)]`n" + "$($_.Exception.Message)");
		OutputToLog ("An error occurred. [$($SiteCollectionURL)]`n" + "$($_.Exception.ToString())`n$($_.ScriptStackTrace)")
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