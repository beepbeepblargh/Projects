# Create and start post-migration log file
$postMigrationLog = "C:\ProgramData\IntuneMigration\post-migration.log"
Start-Transcript -Path $postMigrationLog -Verbose

# Rename the BW Tenant user profile, disable the MiddleBoot task, and reboot

# Get BW Tenant user profile directory name from XML file
Write-Host "Getting BW Tenant user profile name"
[xml]$memSettings = Get-Content -Path "C:\ProgramData\IntuneMigration\MEM_Settings.xml"
$memConfig = $memSettings.Config
$user = $memConfig.User
Write-Host "Current user directory name is C:\Users\$($user)"

# Rename directory
$currentDirectory = "C:\Users\$($user)"
$renamedDirectory = "C:\Users\OLD_$($user)"

if(Test-Path $currentDirectory)
{
	Rename-Item -Path $currentDirectory -NewName $renamedDirectory
	Write-Host "Renaming path $($currentDirectory) to $($renamedDirectory)"
}
else 
{
	Write-Host "Path $($currentDirectory) not found"
}
# Disable Warning message
try {
	Start-Sleep -Seconds 10
	Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name legalnoticecaption -Value ""
	Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name legalnoticetext -Value ""
	Write-Host "Removed warning message for sign in."
	
} 
catch {
	Write-Host "Unable to remove warning message. Review error in logs"
}

# Disable MiddleBoot task
Disable-ScheduledTask -TaskName "MiddleBoot"
Write-Host "Disabled MiddleBoot scheduled task"

Start-Sleep -Seconds 2

# Reboot in 30 seconds
shutdown -r -t 30

Stop-Transcript

