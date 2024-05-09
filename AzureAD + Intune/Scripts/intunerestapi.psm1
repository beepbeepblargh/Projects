Function Get-IntuneApplication(){

    <#
    .SYNOPSIS
    This function is used to get applications from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any applications added
    .EXAMPLE
    Get-IntuneApplication
    Returns any applications configured in Intune
    .NOTES
    NAME: Get-IntuneApplication
    #>
    
    [cmdletbinding()]
    
    param
    (
        $Name
    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceAppManagement/mobileApps"
    
        try {

            # Lists all apps including Mobile apps
            # if($Name) {
            # $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?$filter=&$orderby=displayName&$search=$Name"
            # (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
            # }
            # else {
            #     $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps"
            #     (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
            # }

            # Lists only PC Apps not Mobile apps
            if($Name){
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") -and (!($_.'@odata.type').Contains("managed")) -and (!($_.'@odata.type').Contains("#microsoft.graph.iosVppApp")) }
    
            }
            else {
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { (!($_.'@odata.type').Contains("managed")) -and (!($_.'@odata.type').Contains("#microsoft.graph.iosVppApp")) }
    
            }
    
        }
    
        catch {
    
        $ex = $_.Exception
        Write-Host "Request to $Uri failed with HTTP Status $([int]$ex.Response.StatusCode) $($ex.Response.StatusDescription)" -f Red
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
        }
    
    }


Function Get-ApplicationAssignment(){

    <#
    .SYNOPSIS
    This function is used to get an application assignment from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets an application assignment
    .EXAMPLE
    Get-ApplicationAssignment
    Returns an Application Assignment configured in Intune
    .NOTES
    NAME: Get-ApplicationAssignment
    #>
    
    [cmdletbinding()]
    
    param
    (
        $ApplicationId
    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceAppManagement/mobileApps/$ApplicationId/?`$expand=categories,assignments"
        
        try {
            
            if(!$ApplicationId){
    
            write-host "No Application Id specified, specify a valid Application Id" -f Red
            break
    
            }
    
            else {
            
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
            
            }
        
        }
        
        catch {
    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
        }
    
    } 


Function AppManagementInstallScripts(){
    
    <#
    .SYNOPSIS
    This function is used to update the install and uninstall commands for an app in intune
    .DESCRIPTION
    The function connects to the Graph API Interface and updates the install and uninstall commands
    .EXAMPLE
    AppManagementInstallScript
    Returns an Application Assignment configured in Intune
    .NOTES
    NAME: AppManagementInstallScript
    #>
    
    [cmdletbinding()]
    
    param
    (
        $ApplicationId,
        $installCommand,
        $uninstallCommand
    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceAppManagement/mobileApps/$ApplicationId"

    try {
        if ($installCommand -and $uninstallCommand) {
            $JSON = @"
    {
        "@odata.type": "#microsoft.graph.win32LobApp",
        "installCommandLine": "$installCommand",
        "uninstallCommandLine": "$uninstallCommand"
    }
"@
    }elseif ($installCommand) {
        $JSON = @"
        {
            "@odata.type": "#microsoft.graph.win32LobApp",
            "installCommandLine": "$installCommand"
        }
"@
    }elseif ($uninstallCommand) {
        $JSON = @"
        {
            "@odata.type": "#microsoft.graph.win32LobApp",
            "uninstallCommandLine": "$uninstallCommand"
        }
"@
    }

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $JSON -ContentType "application/json"

        
    }
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    }

   
}




Function AppManagementDescription(){
    
    <#
    .SYNOPSIS
    This function is used to update the description of the app in intune
    .DESCRIPTION
    The function connects to the Graph API Interface and updates the description
    .EXAMPLE
    AppManagementDescription -ApplicationId -Description
    Returns an Application Assignment configured in Intune
    .NOTES
    NAME: Get-ApplicationAssignment
    #>
    
    [cmdletbinding()]
    
    param
    (
        $ApplicationId,
        $Description
    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceAppManagement/mobileApps/$ApplicationId"

    try {
            $JSON = @"
    {
        "@odata.type": "#microsoft.graph.win32LobApp",
        "description": "$description"
    }
"@
 
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Patch -Body $JSON -ContentType "application/json"

        
    }
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    }

   
}



Function Add-ApplicationAssignment(){

<#
.SYNOPSIS
This function is used to add an application assignment using the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and adds a application assignment
.EXAMPLE
Add-ApplicationAssignment -ApplicationId $ApplicationId -TargetGroupId $TargetGroupId -InstallIntent $InstallIntent
Adds an application assignment in Intune
.NOTES
NAME: Add-ApplicationAssignment
#>

[cmdletbinding()]

param
(
$ApplicationId,
$TargetGroupId,
[ValidateSet("available", "required")]
$InstallIntent
)

$graphApiVersion = "Beta"
$Resource = "deviceAppManagement/mobileApps/$ApplicationId/assign"

try {

    if(!$ApplicationId){

    write-host "No Application Id specified, specify a valid Application Id" -f Red
    break

    }

    if(!$TargetGroupId){

    write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red
    break

    }

    
    if(!$InstallIntent){

    write-host "No Install Intent specified, specify a valid Install Intent - available, notApplicable, required, uninstall, availableWithoutEnrollment" -f Red
    break

    }

$AssignedGroups = (Get-ApplicationAssignment -ApplicationId $ApplicationId).assignments

if($AssignedGroups){

$App_Count = @($AssignedGroups).count
$i = 1

if($AssignedGroups.target.GroupId -contains $TargetGroupId){

    Write-Host "'$AADGroup' is already targetted to this application, can't add an AAD Group already assigned..." -f Red

}

else {

# Creating header of JSON File
$JSON = @"

{
"mobileAppAssignments": [
{
    "@odata.type": "#microsoft.graph.mobileAppAssignment",
    "target": {
    "@odata.type": "#microsoft.graph.groupAssignmentTarget",
    "groupId": "$TargetGroupId"
    },
    "intent": "$InstallIntent"
},
"@

# Looping through all existing assignments and adding them to the JSON object
foreach($Assignment in $AssignedGroups){

$ExistingTargetGroupId = $Assignment.target.GroupId
$ExistingInstallIntent = $Assignment.intent

$JSON += @"

{
    "@odata.type": "#microsoft.graph.mobileAppAssignment",
    "target": {
    "@odata.type": "#microsoft.graph.groupAssignmentTarget",
    "groupId": "$ExistingTargetGroupId"
    },
    "intent": "$ExistingInstallIntent"
"@

if($i -ne $App_Count){

$JSON += @"

},

"@

}

else {

$JSON += @"

}

"@

}

$i++

}

# Adding close of JSON object
$JSON += @"

]
}

"@

$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

}

}

else {

$JSON = @"

{
"mobileAppAssignments": [
{
    "@odata.type": "#microsoft.graph.mobileAppAssignment",
    "target": {
    "@odata.type": "#microsoft.graph.groupAssignmentTarget",
    "groupId": "$TargetGroupId"
    },
    "intent": "$InstallIntent"
}
]
}

"@

$uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

}

}

catch {

$ex = $_.Exception
$errorResponse = $ex.Response.GetResponseStream()
$reader = New-Object System.IO.StreamReader($errorResponse)
$reader.BaseStream.Position = 0
$reader.DiscardBufferedData()
$responseBody = $reader.ReadToEnd();
Write-Host "Response content:`n$responseBody" -f Red
Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
write-host
break

}

}


Function Remove-ApplicationAssignment(){

    <#
    .SYNOPSIS
    This function is used to add remove application assignments using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a application assignment
    .EXAMPLE
    Remove-ApplicationAssignment -ApplicationId $ApplicationId
    Removes an applications assignments in Intune
    .NOTES
    NAME: Remove-ApplicationAssignment
    #>
    
    [cmdletbinding()]
    
    param
    (
        $ApplicationId
    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceAppManagement/mobileApps"
    
    $assignments = (Get-ApplicationAssignment -ApplicationId $ApplicationId).assignments
    
    if($assignments){
        foreach($assignment in $assignments){
            $assignmentid = $assignment.id
            try {
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/$ApplicationId/assignments/$assignmentid"
                Invoke-RestMethod -Uri $uri -Headers $authToken -Method Delete
            }
            catch {
            $ex = $_.Exception
            Write-Host "Request to $Uri failed with HTTP Status $([int]$ex.Response.StatusCode) $($ex.Response.StatusDescription)" -f Red
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host "Response content:`n$responseBody" -f Red
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
            write-host
            break
            }
        }
        
    }
    return $true
    }
    

Function Get-AADGroup(){

    <#
    .SYNOPSIS
    This function is used to get AAD Groups from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any Groups registered with AAD
    .EXAMPLE
    Get-AADGroup
    Returns all users registered with Azure AD
    .NOTES
    NAME: Get-AADGroup
    #>
    
    [cmdletbinding()]
    
    param
    (
        $GroupName,
        $id,
        [switch]$Members
    )
    
    # Defining Variables
    $graphApiVersion = "v1.0"
    #$graphApiVersion = "beta"
    $Group_resource = "groups"
        
        try {

    
            if($id){
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=id eq '$id'"
            #(Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).Value
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
            }
            
            elseif($GroupName -eq "" -or $GroupName -eq $null){
            
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)"
            #(Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).Value
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
            
            }
    
            else {
                
                if(!$Members){
                #Write-Host $authToken
                
    
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
                #(Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).Value
                
                #Write-Host $uri
                #Write-Host $authToken
                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
               
                
                }
                
                elseif($Members){
               
                
                $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)?`$filter=displayname eq '$GroupName'"
                #$Group = (Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).Value
                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
                    if($Group){
                        $GID = $Group.id
                    #$Group.displayName
                    #write-host
    
                    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Group_resource)/$GID/Members"
                    #(Invoke-RestMethod -Uri $uri –Headers $authToken –Method Get).Value
                    (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
                    }
    
                }
            
            }
    
        }
    
        catch {
    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host $ex
        break
    
        }
    
    }


Function Remove-Dependencies(){
       <#
    .SYNOPSIS
    This function is used to remove all dependencies from an app in the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and removes app relationships
    .EXAMPLE
    Remove-Dependencies -AppID $AppID
    Returns all users registered with Azure AD
    .NOTES
    NAME: Remove-Dependencies
    #>
    
    [cmdletbinding()]
    
    param
    (
        $AppID
    )

    

    try {

        $body = "{`"relationships`":[]}"
        $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$AppID/updateRelationships"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $body  -ContentType "application/json"
        
    }
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host $ex
        break
    }


}


Function mobileAppDependencies(){
    <#
 .SYNOPSIS
 This function is used to get all dependencies for an app in the Graph API REST interface
 .DESCRIPTION
 The function connects to the Graph API Interface and removes app relationships
 .EXAMPLE
 Remove-Dependencies -AppID $AppID
 Returns all users registered with Azure AD
 .NOTES
 NAME: Remove-Dependencies
 #>
 
 [cmdletbinding()]
 
 param
 (
     $AppID
 )

 

 try {
     $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$AppID/relationships"
     (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
 }
 catch {
     $ex = $_.Exception
     $errorResponse = $ex.Response.GetResponseStream()
     $reader = New-Object System.IO.StreamReader($errorResponse)
     $reader.BaseStream.Position = 0
     $reader.DiscardBufferedData()
     $responseBody = $reader.ReadToEnd();
     Write-Host "Response content:`n$responseBody" -f Red
     Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
     Write-Host $ex
     break
 }


}


Function Remove-App(){
       <#
    .SYNOPSIS
    This function is used to remove an app in the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and removes the app
    Please ensure you remove all dependencies first otherwise this will fail
    .EXAMPLE
    Remove-App -AppID $AppID
    Returns all users registered with Azure AD
    .NOTES
    NAME: Remove-App
    #>
    
    [cmdletbinding()]
    
    param
    (
        $AppID
    )
    
    try {
        $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$AppID/"
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Delete  
    }
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        Write-Host $ex
        break
    }







}


Function ListAppCategories(){
    <#
 .SYNOPSIS
 This function is used to list mobile app categories in the Graph API REST interface
 .DESCRIPTION
 The function connects to the Graph API Interface and lists the app
 Categories
 .EXAMPLE
ListAppCategories
 Returns App Categories
 .NOTES
 NAME: ListAppCategories
 #>
  
 try {
     $uri = "https://graph.microsoft.com/beta/deviceAppManagement/mobileAppCategories"
     Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get  
 }
 catch {
     $ex = $_.Exception
     $errorResponse = $ex.Response.GetResponseStream()
     $reader = New-Object System.IO.StreamReader($errorResponse)
     $reader.BaseStream.Position = 0
     $reader.DiscardBufferedData()
     $responseBody = $reader.ReadToEnd();
     Write-Host "Response content:`n$responseBody" -f Red
     Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
     Write-Host $ex
     break
 }







}

Function AddAppCategory(){
    <#
 .SYNOPSIS
 This function is used to add mobile app categories in the Graph API REST interface
 .DESCRIPTION
 The function connects to the Graph API Interface and adds a category
 Categories
 .EXAMPLE
AddAppCategory $CategoryName
 .NOTES
 NAME: AddAppCategory
 #>

 [cmdletbinding()]
    
 param
 (
     $DisplayName
 )
  
 try {


$JSON = @{
    "@odata.type" = "#microsoft.graph.mobileAppCategory"
    "displayName" = $DisplayName
} | ConvertTo-Json


    $uri = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileAppCategories"
    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON  -ContentType "application/json"  
 }
 catch {
     $ex = $_.Exception
     $errorResponse = $ex.Response.GetResponseStream()
     $reader = New-Object System.IO.StreamReader($errorResponse)
     $reader.BaseStream.Position = 0
     $reader.DiscardBufferedData()
     $responseBody = $reader.ReadToEnd();
     Write-Host "Response content:`n$responseBody" -f Red
     Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
     Write-Host $ex
     break
 }




}

Function Update-AppsCategory(){
    
    <#
    .SYNOPSIS
    This function is used to update the category for an app in intune
    .DESCRIPTION
    The function connects to the Graph API Interface and updates the apps category
    .EXAMPLE
    AppManagementInstallScript
    Returns an Application Assignment configured in Intune
    .NOTES
    NAME: Get-ApplicationAssignment
    #>
    
    [cmdletbinding()]
    
    param
    (
        $ApplicationId,
        $categoryID

    )
    
    $graphApiVersion = "Beta"
    $Resource = "deviceAppManagement/mobileApps/$ApplicationId"
    try {
      
            $JSON = @"
    {
        "@odata.id": "https://graph.microsoft.com/beta/deviceAppManagement/mobileAppCategories/$categoryID"
    }
"@

    Write-Host $JSON
  
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)/categories/`$ref"
    Write-Host $uri
    #exit
    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
        
    }
    catch {
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    }   
}