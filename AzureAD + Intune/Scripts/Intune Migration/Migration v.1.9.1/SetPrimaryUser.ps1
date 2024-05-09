# Start and append post-migration log file
Start-Transcript -Append "C:\ProgramData\IntuneMigration\post-migration.log" -Verbose

$ErrorActionPreference = 'SilentlyContinue'

# Update Intune device primary user with current active user
<#PERMISSIONS NEEDED FOR APP REG:
Device.ReadWrite.All
DeviceManagementApps.ReadWrite.All
DeviceManagementConfiguration.ReadWrite.All
DeviceManagementManagedDevices.PrivilegedOperations.All
DeviceManagementManagedDevices.ReadWrite.All
DeviceManagementServiceConfig.ReadWrite.All
User.ReadWrite.All
#>

# App reg info for tenant B
$clientId = ""
$clientSecret = ""
$tenant = ""

# Authenticate to graph
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/x-www-form-urlencoded")

$body = "grant_type=client_credentials&scope=https://graph.microsoft.com/.default"
$body += -join("&client_id=" , $clientId, "&client_secret=", $clientSecret)

$response = Invoke-RestMethod "https://login.microsoftonline.com/$tenant/oauth2/v2.0/token" -Method 'POST' -Headers $headers -Body $body

#Get Token form OAuth.
$token = -join("Bearer ", $response.access_token)

#Reinstantiate headers.
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", $token)
$headers.Add("Content-Type", "application/json")
Write-Host "MS Graph Authenticated"

#==============================================================================#
# Get Device and user info
[xml]$memSettings = Get-Content "C:\ProgramData\IntuneMigration\MEM_Settings.xml"
$memConfig = $memSettings.Config

$serialNumber = $memConfig.SerialNumber
$bwuser = $memConfig.BWuser

$intuneObject = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=contains(serialNumber,'$($serialNumber)')" -Headers $headers

$IntuneDeviceId = $intuneObject.value.id
Write-Host "Intune Device ID is $($IntuneDeviceId)"

# #Variable for pulling based off of username instead of DisplayName
# $fulluserName = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI" -name "LastLoggedonUser"
$BWdomain = "@brandwatch.com"

#We pull the Brandwatch user stored in the memconfig xml file as the logged in name will not match in some cases with the email address
$userName = $bwuser + $BWdomain


#Condition for ensuring user account matches Entra ID UPN
# if (($fulluserName).StartsWith("CORP\")){
# 	Write-Host "CORP Domain Detected in username. Removing CORP Domain from username..."
# 	$userName = $fulluserName -replace '^CORP\\', ''
# 	$userName = $userName + $BWdomain
# 	Write-Host "String is now $userName, proceeding..."
# }
# elseif (($fulluserName).StartsWith("AzureAD\")) {
# 	Write-Host "AzureAD Domain Detected in username. Removing AzureAD Domain from username..."
# 	$userName = $fulluserName -replace '^AzureAD\\', '' 
# 	$userName = $username + $BWdomain
# 	Write-Host "String is now $userName, proceeding..."
# }
# else {
# 	Write-Host "Error detected when parsing username..."
# }

Write-Host "Getting current user $($userName) Azure AD object ID..."

$userObject = Invoke-RestMethod -Method Get -Uri "https://graph.microsoft.com/beta/users?`$filter=userPrincipalName eq '$($userName)'" -Headers $headers
$userId = $userObject.value.id
Write-Host "Azure AD user object ID for $($userName) is $($userId)"

# Get user URI REF and construct JSON body for graph call
$deviceUsersUri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$intuneDeviceId')/users/`$ref"
$userUri = "https://graph.microsoft.com/beta/users/" + $userId

$id = "@odata.id"
$JSON = @{ $id="$userUri" } | ConvertTo-Json -Compress

# POST primary user in graph
Invoke-RestMethod -Method Post -Uri $deviceUsersUri -Headers $headers -Body $JSON -ContentType "application/json"

Start-Sleep -Seconds 3

# Disable Task
Disable-ScheduledTask -TaskName "SetPrimaryUser"
Write-Host "Disabled SetPrimaryUser scheduled task"

Stop-Transcript
