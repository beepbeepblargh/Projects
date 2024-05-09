# Start and append post-migration log file
$postMigrationLog = "C:\ProgramData\IntuneMigration\post-migration.log"
Start-Transcript -Append $postMigrationLog -Verbose

$activeUsername = (Get-WMIObject Win32_ComputerSystem | Select-Object username).username
$currentUser = $activeUsername -replace '.*\\'

if ($currentUser -eq "Administrator" -or $currentUser -eq "Winadmin"){
	Write-Host "User signed in as local admin. Disabling post-migration scripts and exiting. "
	#Disable-ScheduledTask -TaskName "RestoreProfile"
	#Write-Host "Disabled RestoreProfile scheduled task"
	$ScheduledTasksList = @(
		"AutopilotRegistration"
		"GroupTag"
		"MigrateBitLockerKey"
		"SetPrimaryUser"		
	)
	foreach ($task in $ScheduledTasksList){
		Disable-ScheduledTask -TaskName "$task"
		Write-Host "Disabled $($task)). Task will be re-enabled once user signs into CORP account"
	}
	Exit
}

else {
	$ErrorActionPreference = 'SilentlyContinue'
	# Check if migrating data
	Write-Host "Checking for Data Migration Flag..."
	$dataMigrationFlag = "C:\ProgramData\IntuneMigration\MIGRATE.txt"

	# Enrolling device into Intune and setting Primary user
	try {
		Start-Process -FilePath "C:\Windows\system32\deviceenroller.exe" -ArgumentList @("/c", "/AutoEnrollMDM") -Passthru
		Write-Host "Device enrolled into Intune. Wait 1 minute and verify within Intune"
	}
	catch {
		Write-Host "Enrollment Failed. Review logs"
	}

	if(Test-Path $dataMigrationFlag)
	{
		Write-Host "Data Migration Flag Found"
		Write-Host "Begin data restore..."
		# Get current active user profile
		$activeUsername = (Get-WMIObject Win32_ComputerSystem | Select-Object username).username
		$currentUser = $activeUsername -replace '.*\\'

		# Get backed up locations
		[xml]$memSettings = Get-Content "C:\ProgramData\IntuneMigration\MEM_Settings.xml"
		$memConfig = $memSettings.Config
		$dataLocations = $memConfig.Locations

		$locations = $dataLocations.Location

		# Restore user data
		foreach($location in $locations)
		{
			$userPath = "C:\Users\$($currentUser)\$($location)"
			$publicPath = "C:\Users\Public\Temp\$($location)"
			Write-Host "Initiating data restore of $($location)"
			robocopy $publicPath $userPath /E /ZB /R:0 /W:0 /V /XJ /FFT
		}
	}
	else 
	{
		Write-Host "Data Migration flag not found.  Data will not be restored"
	}

	Start-Sleep -Seconds 3

	# Renable the GPO so the user can see the last signed-in user on logon screen
	try {
		Set-ItemProperty -Path "HKLM:Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name dontdisplaylastusername -Value 0 -Type DWORD
		Write-Host "$(Get-TimeStamp) - Disable Interactive Logon GPO"
	} 
	catch {
		Write-Host "$(Get-TimeStamp) - Failed to disable GPO"
	}


	# Disable RestoreProfile Task
	Disable-ScheduledTask -TaskName "RestoreProfile"
	Write-Host "Disabled RestoreProfile scheduled task"
	# Checking for and Re-enabling post-migration ScheduledTasks if previously disabled.
	$ScheduledTasksList = @(
		"AutopilotRegistration"
		"GroupTag"
		"MigrateBitLockerKey"
		"SetPrimaryUser"				
	)
	foreach ($task in $ScheduledTasksList){
		Enable-ScheduledTask -TaskName "$($task)"
		Write-Host "Re-enabled $($task)"
	}
	Write-Host "Rebooting machine in 30 seconds"
	Shutdown -r -t 30
}	

Stop-Transcript
