if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) {
    Add-PSSnapin "Microsoft.SharePoint.PowerShell"
}

#Please set the Template Names here if you want to work with another template
$TemplateName = "TestNewScript2.rkcm"
$TemplateNameWithOutRKCM = "TestNewScript2"

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition

#Check if Administrator of local Server
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(` [Security.Principal.WindowsBuiltInRole] “Administrator”))
{
    Write-Warning “You do not have administrator rights to run this script!`nPlease re-run this script as an Administrator!”
    Break
}

function Pause
{
   Read-Host 'Press Enter to continue ' | Out-Null
}

<#
    Function   : PauseForYesNo
    Description: Prompt for user input of "Y" or "N"
    Note       : Will not run from ISE, must run from command prompt
    Parameters :
       -question  : Question text to display to user
    Returns    :     Key pressed ("Y" or "N")
#>
function PauseForYesNo
{
    param(
        [Parameter(Mandatory=$true)][System.String]$question)

        # Setup the question
        write-host -f Yellow ("{0}? " -f $question);
        write-host -f Green "[Y] Yes  [N] No  [?] Help (default is 'Y'): " -nonewline;
        
        # Read key input until "Y" or "N" pressed
        do {
            $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown");
        }
        until (($key.Character -eq "Y") -or ($key.Character -eq "N") -or ($key.Character -eq "y") -or ($key.VirtualKeyCode -eq 13) -or ($key.Character -eq "?") -or ($key.Character -eq "n"))
        
        # Echo the key pressed
        write-host -f White $key.Character;
        
		#check return key
		if ($key.VirtualKeyCode -eq 13){
			return "Y";
			}
		if ($key.Character -eq 'y'){
			return "Y";		
			}
		if ($key.Character -eq '?'){
			write-host "Please contact support@solutions2share.net";
			return "N";
		}
		if ($key.Character -eq 'n'){
			return "N";
			}
        # Return the key pressed
        return $key.Character.ToString();
}

function global:CheckServiceStatus([string]$service)
{
    $status = (Get-Service $service).Status
    $displayname = (Get-Service $service ).DisplayName
 
    if ($status -eq "Running")
    {
        Write-Host $displayname "is " -ForegroundColor White -NoNewline; Write-Host "Running" -ForegroundColor Green
    } 
    Else 
    {
        if ($status -eq "Stopped")
        {
            $answer = Read-Host $displayname "is Stopped. Would you like to start this service? (Y/N)"
            if ($answer -eq 'Y')
            {
                (Get-Service $service).Start()
                CheckServiceStatus  $service
            } 
            else 
            {
                Write-Host "You will need to go to the $servername to start this service manually."
            }
        }
    }
}

function CheckSharePointVersion()
{ 
    $SolutionName = $null
    $ver = (Get-PSSnapin microsoft.sharepoint.powershell).Version.Major
    if ($ver -eq "16" ) 
    { 
        Write-Host "-> SharePoint 2016 is installed"
        $SharePointVersion = "2016"
    } 
    elseif ($ver -eq "15" ) 
    { 
        Write-Host "-> SharePoint 2013 is installed"
        $SharePointVersion = "2013"
    } 
    elseif ($ver -eq "14") 
    { 
        Write-Host "-> SharePoint 2010 is installed"
        $SharePointVersion = "2010"
    } 
    else 
    { 
        Write-Host "Could not determine version of SharePoint" -ForegroundColor red;
        sleep -Seconds 5
        exit
    }
     
    return $SharePointVersion
}

function SelectLicenseWSP($SharePointVersion)
{
	if($SharePointVersion -eq "2016")
    {
        $licenseWSP = "Solutions2Share.LicenseManagement2016.wsp"
    }
    elseif($SharePointVersion -eq "2013")
    {
        $licenseWSP = "Solutions2Share.LicenseManagement2013.wsp"
    }
    elseif($SharePointVersion -eq "2010")
    {
		$licenseWSP = "Solutions2Share.LicenseManagement.wsp"
    } 
       
    return $licenseWSP
}

function SelectCMWSP($SharePointVersion)
{
	if($SharePointVersion -eq "2016")
    {
        $SolutionName = "Solutions2Share.Solutions.CollaborationManager2016.wsp"
    }
    elseif($SharePointVersion -eq "2013")
    {
        $SolutionName = "Solutions2Share.Solutions.CollaborationManager2013.wsp"
    }
    elseif($SharePointVersion -eq "2010")
    {
        $SolutionName = "Solutions2Share.Solutions.CollaborationManager.wsp"
    }

    return $SolutionName
}

function AddLicenseManagement([string]$licenseWSP)
{
    $solution = Get-SPSolution -Identity $licenseWSP -ErrorAction SilentlyContinue
    if(-not $solution)
    {
        Write-Host "`n-> Adding License Management Solution"
        Add-SPSolution -LiteralPath $scriptPath\$licenseWSP | Out-Null
    }
    else
    {     
        Write-Host "-> License Management Solution is already added"
    }
}

function AddCMSolution([string]$SolutionName)
{
    $solution = Get-SPSolution -Identity $SolutionName -ErrorAction SilentlyContinue
    if(-not $solution)
    {
        Write-Host "`n-> Adding Collaboration Manager Solution"
        Add-SPSolution -LiteralPath $scriptPath\$SolutionName | Out-Null
    }
    else
    {     
        Write-Host "-> Collaboration Manager Solution is already added"
    }
}

function CheckWebApplicationURL
{
    Write-Host "`n`nAll available WebApplications"  -ForegroundColor Cyan
    Write-Host "-------------------------------`n"
    $WebApplicationURL = $null
    [string[]]$WebApplicationArray = Get-SPWebApplication | foreach {$_.URL}

    for ($i=0; $i -lt $WebApplicationArray.length; $i++)
    {

        Write-Host $WebApplicationArray[$i] "ID: "$i  
    }

    return $WebApplicationArray
}

function SelectWebApplication([array]$a_WebApplicationsURL)
{
    $webAppInvalid=$true;
    
    [string]$urlOfselectedWebApplication = ""
    
    while($webAppInvalid)
    {
		[int]$WebApplicationArrayID = Read-Host "`nPlease insert the ID of the specific WebApplication where the Collaboration Manager should be deployed"
		if($WebApplicationArrayID -ge 0)
		{     
			$urlOfselectedWebApplication = $a_WebApplicationsURL[$WebApplicationArrayID];			
			$result = PauseForYesNo -question "The selected WebApplication is $urlOfselectedWebApplication. Is this correct?";

			if ($result -eq "Y") { $webAppInvalid = $false; }
			else {
				Write-Host "Please choose another WebApplication:" -ForegroundColor Red;
				for ($i=0; $i -lt $a_WebApplicationsURL.length; $i++)
				{
					Write-Host $a_WebApplicationsURL[$i] "ID: "$i  
				}
			}			
		} 
    } 

    return $a_WebApplicationsURL[$WebApplicationArrayID];
}

function InstallSolutions([string]$SolutionName, [string]$licenseWSP, $selectedWebApplication)
{
    $CAurl = Get-SPWebApplication -includecentraladministration | where {$_.IsAdministrationWebApplication} | Select-Object -ExpandProperty Url

    Write-Host "`n-> Installing LicenseManagement to the selected WebApplication"
    #Installing LM to WebApplication
    if((CheckSolutionIsInstalled $licenseWSP $selectedWebApplication) -eq $false)
    {
        Install-SPSolution -Identity $licenseWSP -GACDeployment -WebApplication $selectedWebApplication
        CheckCorrectInstallation $licenseWSP -eq $false
    }
    Write-Host "`n-> Installing LicenseManagement to the Central Administration"    
    #Installing LM to CA
    if((CheckSolutionIsInstalled $licenseWSP $CAurl) -eq $false)                    
    {
        Install-SPSolution -Identity $licenseWSP -GACDeployment -WebApplication $CAurl
        CheckCorrectInstallation $licenseWSP -eq $false
    }
    Write-Host "`n-> Installing Collaboration Manager to the selected WebApplication"
    #Installing CM to WebApplication
    if((CheckSolutionIsInstalled $SolutionName $selectedWebApplication) -eq $false)
    {
        Install-SPSolution -Identity $SolutionName -GACDeployment -WebApplication $selectedWebApplication
        CheckCorrectInstallation $SolutionName -eq $false
    }
    Write-Host "`n-> Installing Collaboration Manager to the Central Administration"
    #Installating CM to CA
    if((CheckSolutionIsInstalled $SolutionName $CAurl) -eq $false)
    {
        Install-SPSolution -Identity $SolutionName -GACDeployment -WebApplication $CAurl
        CheckCorrectInstallation $SolutionName -eq $false
    }                                              
        

}

#Check if Solution is already installed
function CheckSolutionIsInstalled($SolutionName, $selectedWebApplication)
{
    $returnVal= $false;
    $farm = Get-SPFarm
    $solutions = $farm.Solutions
    $solutioncheck = $false
    $sol = $farm.Solutions | Where {$_.Name -eq $SolutionName}
    if ($sol -ne $null)
    {
        $installed = $sol.DeployedWebApplications | Where {$_.Url -eq $selectedWebApplication}
        if ($installed -ne $null -or $installed -eq $false)
        {
             $returnVal= $true;
             Write-Host "-> Solution is already installed" -ForegroundColor Cyan
        }
    }
    return $returnVal;
}

#Check correct installation of CM
function CheckCorrectInstallation($SolutionName)
{
    $Solution = Get-SPSolution -Identity:$SolutionName
    while ($Solution.JobExists -eq $true) 
    {
        Write-Host '.' -NoNewline
        sleep -Seconds 1
        $Solution = Get-SPSolution -Identity:$SolutionName
    }
        $lastOperationResult = $Solution.LastOperationResult  
        if ($lastOperationResult -ne [Microsoft.SharePoint.Administration.SPSolutionOperationResult]::DeploymentSucceeded -and $lastOperationResult -ne [Microsoft.SharePoint.Administration.SPSolutionOperationResult]::NoOperationPerformed)
        {
            Write-Host "`nFehler beim installieren der WSP. Bitte lösen Sie das Problem manuell und starten Sei das Script erneut." -ForegroundColor R -ErrorAction SilentlyContinue
            throw [System.IO.FileNotFoundException] "$SolutionName could not be installed successfully."
        }
        else
        {
            Write-Host "`nSolution successfully installed" -ForegroundColor Green 
        }
}


#Create Secure Store Service
function CreateSecureStoreService([string]$selectedWebApplication)
{
    $repeat = $true
    while($repeat)
    {    
        $farmAccount = (Get-SPFarm).DefaultserviceAccount.Name
        $farmPassword = Read-Host -assecurestring "Please enter the password for the account $farmAccount"
		$result = PauseForYesNo -question "Are you sure your password is correct?";
		
		if ($result -eq "Y") {
			$repeat = $false;
			if (Get-SPServiceApplication | Where {$_.typename -eq 'Secure Store Service Application'}) 
			{ 
				Write-Host "`n-> Secure Store Service Service Application already exists"
			} 
			else 
			{
				# Start the Secure Store Service
				$secureStoreService = Get-SPServiceInstance | Where {$_.TypeName -eq "Secure Store Service"}
	
				if ($secureStoreService.Status -eq "Disabled")
				{
				Start-SPServiceInstance -Identity $secureStoreService.Id 
				# Wait for the service to start
				Start-Sleep -s 30
				}

				#Get SecureStoreService Application Pol
				Write-Host "-> Checking for existing Application Pool for the Secure Store Service`n"
				$secureStoreServiceAppPool = "SecureStoreServiceAppPool" 
				$appPool = Get-SPServiceApplicationPool | Where {$_.name -eq $secureStoreServiceAppPool}

				#Check if apppool is active or create an apppool for the Secure Store Service 
				if (!$appPool)
				{
					Write-Host "-> Creating Application Pool for the Secure Store Service"
					$appPool = New-SPServiceApplicationPool -Name $secureStoreServiceAppPool -Account $farmAccount
				}
				else
				{
					Write-Host "-> Application Pool for the Secure Store Service already exists`n"
				}
	 
				Write-Host "-> Creating Application for Secure Store Service" 
				$sssApp = New-SPSecureStoreServiceApplication -Name "Secure Store Service Application" -ApplicationPool $appPool -AuditingEnabled:$false  
				# Wait for the timerjobs to run				
				Start-Sleep -s 10
				Write-Host "-> Creating Application Proxy for Secure Store Service" 

				$sssAppProxy = New-SPSecureStoreServiceApplicationProxy -Name "Secure Store Service Application Proxy" -ServiceApplication $sssApp -DefaultProxyGroup
				 
				# Wait for the timerjobs to run
				Start-Sleep -s 10
				Update-SPSecureStoreMasterKey -ServiceApplicationProxy $sssAppProxy -Passphrase "P@ssw0rd"
				Write-Host "-> New Secure Store Master Key is set to P@ssw0rd`n" -ForegroundColor Cyan
			}
			
			$serviceCntx = Get-SPServiceContext -Site $selectedWebApplication
			$sssProvider = New-Object Microsoft.Office.SecureStoreService.Server.SecureStoreProvider
            $sssProvider.Context = $serviceCntx
			$marshal = [System.Runtime.InteropServices.Marshal]          
            $applicationlications = $sssProvider.GetTargetApplications()
			$cmAppExists = $false;
            foreach($application in $applicationlications) 
			{
				if($application.Name -eq "Collaboration Manager") {
					$cmAppExists = $true;
				}
			} 
			Write-Host "SecureStore TargetApplication >Collaboration Manager< found: $cmAppExists"
			if (!$cmAppExists){
				$sssAppProxy = Get-SPServiceApplicationProxy | Where {$_.TypeName -eq "Secure Store Service Application Proxy"} 
				Write-Host "-> Configure the Secure Store Service entry for Collaboration Manager`n"
				#Setting variables for the new Secure Store Service Application
				$UserNameField = New-SPSecureStoreApplicationField -name "Windows User Name" -type WindowsUserName -masked:$false
				$PasswordField = New-SPSecureStoreApplicationField -name "Windows Password" -type WindowsPassword -masked:$true 
				$fields = $UserNameField, $PasswordField
				$targetApp = New-SPSecureStoreTargetApplication -Name "Collaboration Manager" -FriendlyName "Collaboration Manager" -ContactEmail "admin@domain.com" -ApplicationType Group
				$targetAppAdminAccount = New-SPClaimsPrincipal -Identity $farmAccount -IdentityType WindowsSamAccountName
				$targetGroupAccount = New-SPClaimsPrincipal -EncodedClaim "c:0(.s|true"
				$defaultServiceContext = Get-SPServiceContext $selectedWebApplication
				#Creating new Secure Store Service Application
				$ssApp = New-SPSecureStoreApplication -ServiceContext $defaultServiceContext -TargetApplication $targetApp -Administrator $targetAppAdminAccount -Fields $fields -CredentialsOwnerGroup $targetGroupAccount
				# Convert values to secure strings
				$secureUserName = ConvertTo-SecureString $farmAccount -asplaintext -force
				#$securePassword = ConvertTo-SecureString $farmPassword -asplaintext -force
				$credentialValues = $secureUserName, $farmPassword
				# Fill in the values for the fields in the target application
				Update-SPSecureStoreGroupCredentialMapping -Identity $ssApp -Values $credentialValues  
			}          
		}		     
    }
}

function StartCMService
{
	$serviceInstance = Get-SPServiceInstance | where {$_.TypeName -eq "Collaboration Manager Service"}
	if ($serviceInstance -and $serviceInstance.Status -eq "Disabled"){
		$serviceInstance.Provision();
		$serviceInstance.Update();
	}
}

#Create Collaboration Manager Service Application
function CreateCMServiceApplication
{
    Remove-PSSnapin Microsoft.SharePoint.Powershell
    Add-PSSnapin Microsoft.SharePoint.Powershell
    
    if (Get-SPServiceApplication | Where {$_.typename -eq 'Collaboration Manager Service Application'}) 
        { 
                Write-Host "`n-> Collaboration Manager Service Application already exists"
        }
        else
        {
            Write-Host "-> Creating Collaboration Manager Service Application"
            $farmAccount = (Get-SPFarm).DefaultserviceAccount.Name
            #Creating Collaboration Mananger Application Pool
            $appPool = Get-SPServiceApplicationPool | Where {$_.name -eq "Collaboration Manager Pool"}

                #Check if apppool is active or create an apppool for the Collaboration Manager
                if (!$appPool)
                {
                    Write-Host "-> Creating Application Pool for the Collaboration Manager"
                    $appPool = New-SPServiceApplicationPool -Name "Collaboration Manager Pool" -Account $farmAccount
                }
                else
                {
                    Write-Host "-> Application Pool for the Collaboration Manager already exists`n"
                }

            #Creating Service Application
            $serviceApp = New-CollaborationManagerServiceApplication -Name "CM Service Application" -ApplicationPool $appPool -ErrorAction Stop
            #Creating Service Application Proxy
            $serviceAppProxy = New-CollaborationManagerServiceApplicationProxy -ServiceApplication $serviceApp –DefaultProxyGroup -Name "CM Service Application Proxy" -ErrorAction Stop
            Write-Host "Collaboration Manager Service Application successfully created" -ForegroundColor Green
            Write-Host "-------------------------------`n"
        }

    
}

#Setting configuration for Collaboration Manager
function SetCMSettings($selectedWebApplication)
{
    [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Practices.SharePoint.Common") | Out-Null
    $farm = Get-SPFarm
    $propertyBagStore = $farm.GetObject("_pnpFarmConfig_", $farm.Id, [Microsoft.Practices.SharePoint.Common.Configuration.FarmSettingStore])
    $webApplication = Get-SPWebapplication $selectedWebApplication
    $SiteCollectionExists = $true

    while($SiteCollectionExists)
    {
        $selectedSiteCollection = Read-Host "`nPlease insert the URL where the Collaboration Manager should be activated i.e. https://portal/sites/collabmanager" 
        $confirmSiteCollection = (Get-SPWeb $selectedSiteCollection -ErrorAction SilentlyContinue) -ne $null
        if ($confirmSiteCollection)
        {
            $SiteCollectionExists = $false
            if ($propertyBagStore.Settings -eq $null)
            {
				$propertyBagStore.Settings = @{};				
            }
			$propertyBagStore.Settings["PnP.Config.Key." +  $webApplication.Id.ToString() + "CollaborationManagerURL"] = $selectedSiteCollection
			$propertyBagStore.Settings["PnP.Config.Key." +  $webApplication.Id.ToString() + "RKCM_MaxGB"] = 100
			$propertyBagStore.Settings["PnP.Config.Key." +  $webApplication.Id.ToString() + "CM_ManagedPathActivaed"] = $true
			$propertyBagStore.Settings["PnP.Config.Key." +  $webApplication.Id.ToString() + "ContentDBCreationActivated"] = $false
			$propertyBagStore.Settings["PnP.Config.Key." +  $webApplication.Id.ToString() + "ContentDBCreationManually"] = $false
			$propertyBagStore.Update()
        }
        else
        {
            Write-Host "The choosen SiteCollection doesn't exist!" -ForegroundColor Red;
        } 
    }	
	if ((Get-SPFeature -Identity "f7ebcf34-47f2-4d6d-a052-a5c5ab3ee314" -ErrorAction SilentlyContinue  -WebApplication "https://portal2016.contoso.com/") -eq $null){
		Enable-SPFeature -Identity "f7ebcf34-47f2-4d6d-a052-a5c5ab3ee314" -Url $selectedSiteCollection
	}
}

function UploadTemplate($selectedSiteCollection)
{
    $web = Get-SPWeb $selectedSiteCollection
    $file = Get-Item -Path $scriptPath\$TemplateName
    $fileStream=([System.IO.FileInfo](Get-Item $file.FullName)).OpenRead()
    $folder=$web.GetFolder(“Templates”)
    $spFile=$folder.Files.Add($folder.Url + “/” + $file.Name, [System.IO.Stream]$fileStream, $true)
    $fileStream.Close()
    $spFileTitle = $spFile.Item
    $spFileTitle["Title"] = "TestScript"
    $spFileTitle.Update();
}

function CreateWorkspace($selectedSiteCollection)
{
    $web = Get-SPWeb $selectedSiteCollection
    $listName = "Workspaces"
    $list = $web.Lists[$listName]
    $newItem = $list.Items.Add()
    $newItem["Title"] = "MyFirstWorkspace2"
    $TemplateURLField = $newItem.Fields.GetFieldbyInternalName("CM_Workspace_LookupVersion_Temp")
    $newItem[$TemplateURLField.ID] = ";#/Templates/Forms/DispForm.aspx?ID=1;#$TemplateNameWithOutRKCM;#Templates/$TemplateName;#Templates/$TemplateName;#;#;#"
    $ContenTypeField = $newItem.Fields.GetFieldbyInternalName("ContentType")
    $newItem[$ContenTypeField.ID] = $TemplateNameWithOutRKCM
    $newItem.Update()
}


cls
Write-Host "=========================================================================================================`n"
Write-Host " Quickinstallation Script to install the Collaboration Manager Solution for SharePoint 2010, 2013 & 2016"
Write-Host "                                             by Mario Präger       "
Write-Host "                                               Version 0.1`n                  "
Write-Host "                               Support: http://support.solution2share.net"
Write-Host "                               Documentation: http://help.solution2share.net"
Write-Host "                               Website: http://www.solution2share.net`n"
Write-Host "=========================================================================================================`n"
Pause
cls


Write-Host ""
Write-Host "Checking all service status on Server" -ForegroundColor Cyan
Write-Host "-------------------------------`n"
#Check if Services are running
CheckServiceStatus "AppFabricCachingService"
CheckServiceStatus "IISADMIN"
CheckServiceStatus "SPAdminV4"
CheckServiceStatus "SPTraceV4"
CheckServiceStatus "W3SVC"
CheckServiceStatus "SPTimerV4"


Write-Host "`nChecking SharePoint Version" -ForegroundColor Cyan
Write-Host "-------------------------------`n"     
$SharePointVersion = CheckSharePointVersion
$SolutionName = SelectCMWSP $SharePointVersion
$licenseWSP = SelectLicenseWSP $SharePointVersion
AddLicenseManagement $licenseWSP
AddCMSolution $SolutionName
$a_WebApplicationsURL = CheckWebApplicationURL
[string]$selectedWebApplication = ""
$selectedWebApplication = SelectWebApplication $a_WebApplicationsURL
InstallSolutions $SolutionName $licenseWSP $selectedWebApplication

Write-Host "-------------------------------`n"
Write-Host "`nPerforming IIS Reset" -ForegroundColor Cyan
Write-Host "-------------------------------`n"
& {iisreset /noforce}    
Write-Host "`nPerforming a restart of SPTimerV4" -ForegroundColor Cyan
Write-Host "-------------------------------`n"
& {net stop sptimerv4}
& {net start sptimerv4}
CheckServiceStatus "IISADMIN"
CheckServiceStatus "SPTimerV4"

Write-Host "`n"
Write-Host "Configure Secure Store Service" -ForegroundColor Cyan  
Write-Host "-------------------------------`n"
CreateSecureStoreService $selectedWebApplication

Write-Host "`n"
Write-Host "Configure CM Service Application" -ForegroundColor Cyan 
Write-Host "-------------------------------`n"
CreateCMServiceApplication
StartCMService
SetCMSettings $selectedWebApplication

#Write-Host "`n-> Uploading Template to Template Library"
#UploadTemplate $selectedSiteCollection
#sleep -Seconds 300

#Write-Host "`n-> Creating Workspace from Template"
#CreateWorkspace $selectedSiteCollection
#sleep -Seconds 10

#Start-Process ($selectedSiteCollection + "/" + "_layouts/15/start.aspx#/Lists/Workspaces/AllItems.aspx")


Write-Host "_____________________________________________________________________________________________" -ForegroundColor Green
write-host ""
Write-Host "Installation completed successfully. You can start using the Collaboration Manager. Have fun!" -ForegroundColor Green
Write-Host "_____________________________________________________________________________________________" -ForegroundColor Green

