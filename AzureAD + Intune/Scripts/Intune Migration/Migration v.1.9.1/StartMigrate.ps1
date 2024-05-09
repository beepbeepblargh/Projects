<# PRIMARY MIGRATION SCRIPT FOR INTUNE TENANT TO TENANT MIGRATION #>
<# WARNING: THIS MUST BE RUN AS SYSTEM CONTEXT #>
<#APP REG PERMISSIONS NEEDED:
Device.ReadWrite.All
DeviceManagementApps.ReadWrite.All
DeviceManagementConfiguration.ReadWrite.All
DeviceManagementManagedDevices.PrivilegedOperations.All
DeviceManagementManagedDevices.ReadWrite.All
DeviceManagementServiceConfig.ReadWrite.All
#>

$ErrorActionPreference = 'SilentlyContinue'

<# =================================================================================================#>
#### STEP 1: LOCAL FILES AND LOGGING ####
<# =================================================================================================#>

#Copy necessary files from intunewin package to local PC
$resourcePath = "C:\ProgramData\IntuneMigration"

if (!(Test-Path $resourcePath)) {
	mkdir $resourcePath
}

$packageFiles = @(
	"migrate.ppkg",
	"AutopilotRegistration.xml",
	"AutopilotRegistration.ps1",
	"MigrateBitlockerKey.xml",
	"MigrateBitlockerKey.ps1",
	"SetPrimaryUser.xml",
	"SetPrimaryUser.ps1",
	"GroupTag.ps1",
	"GroupTag.xml",
	"MiddleBoot.ps1",
	"MiddleBoot.xml",
	"RestoreProfile.ps1",
	"RestoreProfile.xml"
)

foreach ($file in $packageFiles) {
	Copy-Item -Path "$($PSScriptRoot)\$($file)" -Destination "$($resourcePath)" -Force -Verbose
}

#Set detection flag for Intune install
$installFlag = "$($resourcePath)\Installed.txt"
New-Item $installFlag -Force
Set-Content -Path $($installFlag) -Value "Package Installed"

#Start logging of script
Start-Transcript -Path "$($resourcePath)\migration.log" -Verbose

# Verify context is 
Write-Host "Running as..."
whoami
Write-Host ""


<# =================================================================================================#>
#### STEP 2: AUTHENTICATE TO MS GRAPH ####
<# =================================================================================================#>

#BW TENANT Application Registration Auth 
Write-Host "Authenticating to MS Graph..."
$clientId = ""
$clientSecret = ""
$tenant = ""

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/x-www-form-urlencoded")

$body = "grant_type=client_credentials&scope=https://graph.microsoft.com/.default"
$body += -join ("&client_id=" , $clientId, "&client_secret=", $clientSecret)

$response = Invoke-RestMethod "https://login.microsoftonline.com/$tenant/oauth2/v2.0/token" -Method 'POST' -Headers $headers -Body $body

#Get Token form OAuth.
$token = -join ("Bearer ", $response.access_token)

#Reinstantiate headers.
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", $token)
$headers.Add("Content-Type", "application/json")
Write-Host "MS Graph Authenticated"

<# =================================================================================================#>
#### STEP 3: GET CURRENT STATE INFO ####
<# =================================================================================================#>
#Gather Autopilot and Intune Object details

Write-Host "Gathering device info..."
$serialNumber = Get-WmiObject -Class Win32_Bios | Select-Object -ExpandProperty serialnumber
Write-Host "Serial number is $($serialNumber)"

$autopilotObject = Invoke-RestMethod -Method Get -uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities?`$filter=contains(serialNumber,'$($serialNumber)')" -headers $headers
$intuneObject = Invoke-RestMethod -Method Get -uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices?`$filter=contains(serialNumber,'$($serialNumber)')" -headers $headers

$autopilotID = $autopilotObject.value.id
Write-Host "Autopilot ID is $($autopilotID)"
$intuneID = $intuneObject.value.id
Write-Host "Intune ID is $($intuneID)"
$groupTag = $autopilotObject.value.groupTag
Write-Host "Current Autopilot GroupTag is $($groupTag)."

<#===============================================================================================#>
# Get active username

#Gets principal name from the intune device object
$device_user_principal_name = $intuneObject.value.userPrincipalName
$bwusername = $device_user_principal_name.Split('@')[0]
Write-Host "The device Brandwatch username is $bwusername"

#Logged in username
$activeUsername = (Get-WMIObject Win32_ComputerSystem | Select-Object username).username
$user = $activeUsername -replace '.*\\'
Write-Host "Current active user is $($user)"
Write-Host "Getting current user SID..."
$objUser = New-Object System.Security.Principal.NTAccount("$activeUsername")
$strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
$activeUserSID = $strSID.Value

<#===============================================================================================#>
# User paths to be migrated
# Paths can be added or removed from this array as needed without affecting the migration.  Note that more paths will mean more files will mean larger data sizes...

$locations = @(
	"AppData\Local"
	"AppData\Roaming"
	"Documents"
	"Desktop"
	"Pictures"
	"Downloads"
)

$xmlLocations = @()

foreach($location in $locations)
{
	$xmlLocations += "<Location>$location</Location>`n"
}

<#===============================================================================================#>
# Write data to local XML
$xmlString = @"
<Config>
<GroupTag>$groupTag</GroupTag>
<User>$user</User>
<BWuser>$bwusername</BWuser>
<SerialNumber>$serialNumber</SerialNumber>
<Locations>
$xmlLocations</Locations>
</Config>
"@

$xmlPath = "$($resourcePath)\MEM_Settings.xml"
New-Item $xmlPath -Force
Set-Content -Path $xmlPath -Value $xmlString
Write-Host "Setting local content to $($xmlPath)"

<# =================================================================================================#>
#### STEP 4: SET REQUIRED POLICY ####
<# =================================================================================================#>
# Ensure Microsoft Account creation policy is enabled

$regPath = "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Accounts"
$regName = "AllowMicrosoftAccountConnection"
$value = 1

$currentRegValue = Get-ItemPropertyValue -Path $regPath -name $regName -ErrorAction SilentlyContinue

if ($currentRegValue -eq $value) {
	Write-Host "Registry value for AllowMicrosoftAccountConnection is correctly set to $value."
}
else {
	Write-Host "Setting MDM registry value for AllowMicrosoftAccountConnection..."
	reg.exe add "HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Accounts" /v "AllowMicrosoftAccountConnection" /t REG_DWORD /d 1 /f | Out-Host
}

<#===============================================================================================#>
# Only show OTHER USER option after reboot
Write-Host "Turning off Last Signed-In User Display...."
try {
	Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name dontdisplaylastusername -Value 1 -Type DWORD -Force
	Write-Host "Enabled Interactive Logon policy"
} 
catch {
	Write-Host "Failed to enable policy"
}
Write-Host "Creating sign in warning message for user..."

try {
	Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name legalnoticecaption -Value "DO NOT SIGN IN YET"
	Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name legalnoticetext -Value "PLEASE DO NOT SIGN IN UNTIL YOUR COMPUTER RESTARTS AGAIN/THIS MESSAGE DISAPPEARS"
	Write-Host "Created warning message for sign in."
	
} 
catch {
	Write-Host "Unable to create warning message"
}
<# =================================================================================================#>
#### STEP 5: USER DATA MIGRATION ####
<# =================================================================================================#>

# Check local user data size and available disk space
$totalProfileSize = 0

# Retrieve the profile list directory
$profileListPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

# Match the signed in user's SID to their home directory
$profileImagePath = Get-ItemPropertyValue -LiteralPath "$($profileListPath)\$($activeUserSID)" -Name "ProfileImagePath"
Write-Host "User's Home Directory": $profileImagePath


foreach($location in $locations)
{
	$userLocation = "$($profileImagePath)\$($location)"
	$backupLocation = "C:\Users\Public\Temp\$($location)"
	$size = (Get-ChildItem $userLocation -Recurse | Measure-Object Length -Sum).sum
	$totalProfileSize += $size
	$totalProfileSize += $size
	$sizeGB = "{0:N2} Gb" -f ($size/ 1Gb)
	Write-Host "$($profileImagePath)\$($location) size is $($sizeGB)"
}

$totalProfileSizeGB = "{0:N2} GB" -f ($totalProfileSize/ 1Gb)
Write-Host "The size of $($user) user data is $($totalProfileSizeGB)."

$diskSize = Get-Volume -DriveLetter C | Select-Object SizeRemaining -ExpandProperty SizeRemaining
$diskSizeGB = "{0:N2} GB" -f ($diskSize/ 1Gb)
Write-Host "There is $($diskSizeGB) of free space available on the PC."

$neededSpace = $totalProfileSize * 3
$neededSpaceGB = "{0:N2} GB" -f ($neededSpace/ 1Gb)
Write-Host "$($neededSpaceGB) is required to transfer local user data."

<#===============================================================================================#>
# If disk space available, transfer data.

$aadBrokerFolder = Get-ChildItem -Path "$($userLocation)\Packages" -ErrorAction SilentlyContinue | Where-Object {$_.Name -match "Microsoft.AAD.BrokerPlugin_*"} | Select-Object -ExpandProperty Name
$aadBrokerPath = "$($userLocation)\Packages\$($aadBrokerFolder)"

if($diskSize -gt $neededSpace)
{
    Write-Host "$($diskSizeGB) of free space is sufficient to transfer $($totalProfileSizeGB) of local user data.  Begin transfer..." -ForegroundColor Green
	
	foreach($location in $locations)
	{
		$userPath = "$($profileImagePath)\$($location)"
		$publicPath = "C:\Users\Public\Temp\$($location)"
		if(!(Test-Path $publicPath))
		{
			mkdir $publicPath
		}
		Write-Host "Initiating backup of $($location)"
		
		robocopy $userPath $publicPath /E /ZB /R:0 /W:0 /V /XJ /FFT /XD $aadBrokerPath
		Write-Host "$($userPath) backed up to $($publicPath)"
	}
	New-Item -Path $($resourcePath) -Name "MIGRATE.txt"
}
else
{
    Write-Host "$($diskSizeGB) is not sufficient to transfer $($totalProfileSizeGB) of local user data.  Consider backingup $($user) data to external storage." -ForegroundColor Red
}



<# =================================================================================================#>
#### STEP 6: REMOVE PREVIOUS ENROLLMENT ARTIFACTS ####
<# =================================================================================================#>
#Remove previous MDM enrollment settings from registry

Get-ChildItem 'Cert:\LocalMachine\My' | Where-Object { $_.Issuer -match "Microsoft Intune MDM Device CA" } | Remove-Item -Force
Write-Host "Removing Intune enrollment certificate from tenant $($tenant)"
$EnrollmentsPath = "HKLM:\Software\Microsoft\Enrollments\"
$ERPath = "HKLM:\Software\Microsoft\Enrollments\"
$Enrollments = Get-ChildItem -Path $EnrollmentsPath
foreach ($enrollment in $Enrollments) {
	$object = Get-ItemProperty Registry::$enrollment
	$discovery = $object."DiscoveryServiceFullURL"
	if ($discovery -eq "https://enrollment.manage.microsoft.com/enrollmentserver/discovery.svc") {
		$enrollPath = $ERPath + $object.PSChildName
		Remove-Item -Path $enrollPath -Recurse
		Write-Host "Removing enrollment path $($enrollPath) from registry"
	}
}

Write-Host "Our enrollpath is $enrollPath"
<#===============================================================================================#>
#Remove previous MDM enrollment tasks in task scheduler
$enrollID = $enrollPath.Split('\')[-1]
<# Alternate Command for trimming away extra '\'. Needs testing
if ($enrollID.Endswith('\') -or ($enrollPath.Endswith('\') {
	$enrollID = $enrollID.TrimEnd('\')
}
#>
Write-Host "Our enrollID is $enrollPath"
$enrollID = $enrollID.Replace("\", "")

Write-Host "Our enrollID post replace is $enrollPath"
$taskPath = "\Microsoft\Windows\EnterpriseMgmt\$($enrollID)\"
Write-Host "Our enrollID is $enrollPath"
Write-Host "Taskpath has been set as $taskPath"

if ([string]::IsNullOrEmpty($enrollID)){
    Write-Host "Enrollment id is empty, cannot check for intune tasks to remove"
 }else
 {
    Write-Host "Looking for tasks to remove!!!"
    $tasks = Get-ScheduledTask -TaskPath $taskPath
    if ($tasks.Count -gt 0) {
        Write-Host "Deleting tasks in folder: $taskPath"
        foreach ($task in $tasks) {
            $taskName = $task.TaskName
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Host "Deleted task: $taskName"
        }
    }
    else {
        Write-Host "No tasks found in folder: $taskPath"
    }
 }

Write-Host "Removed previous Intune enrollment"

<# =================================================================================================#>
#### STEP 7: LEAVE AZURE AD AND INTUNE ####
<# =================================================================================================#>

#Remove device from Current Azure AD and Intune environment

Write-Host "Leaving the $($tenant) Azure AD and Intune environment"
Start-Process "C:\Windows\sysnative\dsregcmd.exe" -ArgumentList "/leave"

# Check if device is domain joined
$dsregStatus = (dsregcmd /status | Select-String "DomainJoined")
$dsregString = $dsregStatus.ToString()
$domainJoin = $dsregString.Split(":")[1].Trim()

# If machine is domain joined, remove from domain
if($domainJoin -eq "YES"){
	$password = ConvertTo-SecureString "MyPlainTextPassword" -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential ("domain\username", $password)

	Write-Host "Computer $($env:COMPUTERNAME) is Domain Joined.  Attempting to remove..."
	try {
		Remove-Computer -UnjoinDomainCredential $cred -Force
		Write-Host "Removed computer $($env:COMPUTERNAME) from $($tenant)"
	}
	catch {
		Write-Host "Could not remove computer $($env:COMPUTERNAME) from $($tenant)"
	}
} else {
	Write-Host "Computer $($env:COMPUTERNAME) is not Domain Joined"
}

Start-Sleep -Seconds 5



<# =================================================================================================#>
#### STEP 8: SET POST-MIGRATION TASKS ####
<# =================================================================================================#>

#Create post-migration tasks

foreach($file in $packageFiles)
{
    if($file -match '.xml')
    {
        $name = $file.Split('.')[0]
        schtasks /create /TN $($name) /xml "$($resourcePath)\$($file)" /f
		Write-Host "Created $($name) task"
    }
}

<# =================================================================================================#>
#### STEP 9: JOIN Cision MS TENANT ####
<# =================================================================================================#>

#Run ppkg to enroll into new tenant
Write-Host "Installing provisioning package for new Azure AD tenant"
Install-ProvisioningPackage -PackagePath "$($resourcePath)\migrate.ppkg" -QuietInstall -Force

<# =================================================================================================#>
#### STEP 10: DELETE OBJECTS FROM BW TENANT AND REBOOT ####
<# =================================================================================================#>

#Delete Intune and Autopilot objects from old tenant
if ($intuneID -eq $null) {
	Write-Host "Intune ID is null.  Skipping Intune object deletion..."
}
else {
	Write-Host "Attempting to Delete the Intune object..."
	try {
		Invoke-RestMethod -Method Delete -Uri "https://graph.microsoft.com/beta/deviceManagement/managedDevices/$($intuneID)" -Headers $headers
		Start-Sleep -Seconds 2
		Write-Host "Intune object deleted."
	}
 catch {
		Write-Host "Intune object deletion failed.  Trying again..."
		Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
		Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
	}

}

if ($autopilotID -eq $null) {
	Write-Host "Autopilot ID is null.  Skipping Autopilot object deletion..."
}
else {
	Write-Host "Attempting to Delete the Autopilot object..."
	try {
		Invoke-RestMethod -Method Delete -Uri "https://graph.microsoft.com/beta/deviceManagement/windowsAutopilotDeviceIdentities/$($autopilotID)" -Headers $headers
		Start-Sleep -Seconds 2
		Write-Host "Autopilot object deleted."
	}
 catch {
		Write-Host "Autopilot object deletion failed.  Trying again..."
		Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
		Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription
	}
}

<#===============================================================================================#>
# Reboot
Shutdown -r -t 30

Stop-Transcript
