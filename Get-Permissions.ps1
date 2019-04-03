#Read more: http://www.sharepointdiary.com/2018/09/sharepoint-online-site-collection-permission-report-using-powershell.html#ixzz5QKI2K1oX

#Load SharePoint CSOM Assemblies
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
  
#To call a non-generic method Load
Function Invoke-LoadMethod() {
    param(
            [Microsoft.SharePoint.Client.ClientObject]$Object = $(throw "Please provide a Client Object"),
            [string]$PropertyName
        ) 
   $ctx = $Object.Context
   $load = [Microsoft.SharePoint.Client.ClientContext].GetMethod("Load") 
   $type = $Object.GetType()
   $clientLoad = $load.MakeGenericMethod($type)
  
   $Parameter = [System.Linq.Expressions.Expression]::Parameter(($type), $type.Name)
   $Expression = [System.Linq.Expressions.Expression]::Lambda([System.Linq.Expressions.Expression]::Convert([System.Linq.Expressions.Expression]::PropertyOrField($Parameter,$PropertyName),[System.Object] ), $($Parameter))
   $ExpressionArray = [System.Array]::CreateInstance($Expression.GetType(), 1)
   $ExpressionArray.SetValue($Expression, 0)
   $clientLoad.Invoke($ctx,@($Object,$ExpressionArray))
}
 
#Function to Get Permissions Applied on a particular Object, such as: Web, List or Item
Function Get-Permissions([Microsoft.SharePoint.Client.SecurableObject]$Object)
{
    #Determine the type of the object
    Switch($Object.TypedObject.ToString())
    {
        "Microsoft.SharePoint.Client.Web"  { $ObjectType = "Site" ; $ObjectURL = $Object.URL }
        "Microsoft.SharePoint.Client.ListItem"
        { 
            $ObjectType = "List Item"
            #Get the URL of the List Item
            Invoke-LoadMethod -Object $Object.ParentList -PropertyName "DefaultDisplayFormUrl"
            $Ctx.ExecuteQuery()
            $DefaultDisplayFormUrl = $Object.ParentList.DefaultDisplayFormUrl
            $ObjectURL = $("{0}{1}?ID={2}" -f $Ctx.Web.Url.Replace($Ctx.Web.ServerRelativeUrl,''), $DefaultDisplayFormUrl,$Object.ID)
        }
        Default 
        { 
            $ObjectType = "List/Library"
            #Get the URL of the List or Library
            $Ctx.Load($Object.RootFolder)
            $Ctx.ExecuteQuery()            
            $ObjectURL = $("{0}{1}" -f $Ctx.Web.Url.Replace($Ctx.Web.ServerRelativeUrl,''), $Object.RootFolder.ServerRelativeUrl)
        }
    }
 
    #Get permissions assigned to the object
    $Ctx.Load($Object.RoleAssignments)
    $Ctx.ExecuteQuery()
 
    Foreach($RoleAssignment in $Object.RoleAssignments)
    { 
                $Ctx.Load($RoleAssignment.Member)
                $Ctx.executeQuery()
                 
                #Get the Permissions on the given object
                $Permissions=@()
                $Ctx.Load($RoleAssignment.RoleDefinitionBindings)
                $Ctx.ExecuteQuery()
                Foreach ($RoleDefinition in $RoleAssignment.RoleDefinitionBindings)
                {
                    $Permissions += $RoleDefinition.Name +";"
                }
 
                #Check direct permissions
                if($RoleAssignment.Member.PrincipalType -eq "User")
                {
                        #Send the Data to Report file
                        "$($ObjectURL) `t $($ObjectType) `t $($Object.Title)`t $($RoleAssignment.Member.LoginName) `t User `t $($Permissions)" | Out-File $ReportFile -Append
                }
                 
                ElseIf($RoleAssignment.Member.PrincipalType -eq "SharePointGroup")
                {        
                        #Send the Data to Report file
                        "$($ObjectURL) `t $($ObjectType) `t $($Object.Title)`t $($RoleAssignment.Member.LoginName) `t SharePoint Group `t $($Permissions)" | Out-File $ReportFile -Append
                }
                ElseIf($RoleAssignment.Member.PrincipalType -eq "SecurityGroup")
                {
                    #Send the Data to Report file
                    "$($ObjectURL) `t $($ObjectType) `t $($Object.Title)`t $($RoleAssignment.Member.Title)`t $($Permissions) `t Security Group" | Out-File $ReportFile -Append
                }
    }
}
 
Function Generate-SPOSitePermissionRpt($SiteURL,$ReportFile)
{
    Try {
        #Get Credentials to connect
        $Cred= Get-Credential
        $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
  
        #Setup the context
        $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
        $Ctx.Credentials = $Credentials
 
        #Get the Web
        $Web = $Ctx.Web
        $Ctx.Load($Web)
        $Ctx.ExecuteQuery()
 
        #Get the User object
        $SearchUser = $Web.EnsureUser($UserAccount)
        $Ctx.Load($SearchUser)
        $Ctx.ExecuteQuery()
 
        #Write CSV- TAB Separated File) Header
        "URL `t Object `t Title `t Account `t PermissionType `t Permissions" | out-file $ReportFile
 
        Write-host -f Yellow "Getting Site Collection Administrators..."
        #Get Site Collection Administrators
        $SiteUsers= $Ctx.Web.SiteUsers 
        $Ctx.Load($SiteUsers)
        $Ctx.ExecuteQuery()
        $SiteAdmins = $SiteUsers | Where { $_.IsSiteAdmin -eq $true}
 
        ForEach($Admin in $SiteAdmins)
        {
            #Send the Data to report file
            "$($Web.URL) `t Site Collection `t $($Web.Title)`t $($Admin.Title) `t Site Collection Administrator `t  Site Collection Administrator" | Out-File $ReportFile -Append
        }
 
        #Function to Get Permissions of All List Items of a given List
        Function Get-SPOListItemsPermission([Microsoft.SharePoint.Client.List]$List)
        {
            Write-host -f Yellow "`t `t Getting Permissions of List Items in the List:"$List.Title
            $ListItems = $List.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
            $Ctx.Load($ListItems)
            $Ctx.ExecuteQuery()
 
            foreach($ListItem in $ListItems)
            {
                Invoke-LoadMethod -Object $ListItem -PropertyName "HasUniqueRoleAssignments"
                $Ctx.ExecuteQuery()
                if ($ListItem.HasUniqueRoleAssignments -eq $true)
                {
                    #Call the function to generate Permission report
                    Get-Permissions -Object $ListItem
                }
            }
        }
 
        #Function to Get Permissions of all lists from the web
        Function Get-SPOListPermission([Microsoft.SharePoint.Client.Web]$Web)
        {
            #Get All Lists from the web
            $Lists = $Web.Lists
            $Ctx.Load($Lists)
            $Ctx.ExecuteQuery()
 
            #Get all lists from the web   
            ForEach($List in $Lists)
            {
                #Exclude System Lists
                If($List.Hidden -eq $False)
                {
                    #Get List Items Permissions
                    Get-SPOListItemsPermission $List
 
                    #Get the Lists with Unique permission
                    Invoke-LoadMethod -Object $List -PropertyName "HasUniqueRoleAssignments"
                    $Ctx.ExecuteQuery()
 
                    If( $List.HasUniqueRoleAssignments -eq $True)
                    {
                        #Call the function to check permissions
                        Get-Permissions -Object $List
                    }
                }
            }
        }
 
        #Function to Get Webs's Permissions from given URL
        Function Get-SPOWebPermission([Microsoft.SharePoint.Client.Web]$Web) 
        {
            #Get all immediate subsites of the site
            $Ctx.Load($web.Webs)  
            $Ctx.executeQuery()
  
            #Call the function to Get Lists of the web
            Write-host -f Yellow "Getting the Permissions of Web "$Web.URL"..."
 
            #Check if the Web has unique permissions
            Invoke-LoadMethod -Object $Web -PropertyName "HasUniqueRoleAssignments"
            $Ctx.ExecuteQuery()
 
            #Get the Web's Permissions
            If($web.HasUniqueRoleAssignments -eq $true) 
            { 
                Get-Permissions -Object $Web
            }
 
            #Scan Lists with Unique Permissions
            Write-host -f Yellow "`t Getting the Permissions of Lists and Libraries in "$Web.URL"..."
            Get-SPOListPermission($Web)
  
            #Iterate through each subsite in the current web
            Foreach ($Subweb in $web.Webs)
            {
                 #Call the function recursively                            
                 Get-SPOWebPermission($SubWeb)
            }
        }
 
        #Call the function with RootWeb to get site collection permissions
        Get-SPOWebPermission $Web
 
        Write-host -f Green "Site Permission Report Generated Successfully!"
     }
    Catch {
        write-host -f Red "Error Generating Site Permission Report!" $_.Exception.Message
   }
}
 
#Set parameter values
$SiteURL="https://crescent.sharepoint.com/sites/Ops"
$ReportFile="C:\Temp\SitePermissionRpt.csv"
 
#Call the function
Generate-SPOSitePermissionRpt -SiteURL $SiteURL -ReportFile $ReportFile
