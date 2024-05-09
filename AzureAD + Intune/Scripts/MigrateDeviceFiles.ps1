<#
.MigrateDeviceFiles v1
This script is intended to be used to Robocopy one profile to the currently active user profile. 
To run it, upload it to the user's computer. Then run the following alias MigrateDeviceFiles
and then when prompted, type in the user's previous home folder name.
#>

#Setting and confirming PATH for script

#Defining location/directories
$locations = @(
	"AppData\Local"
	"AppData\Roaming"
	"Documents"
	"Desktop"
	"Pictures"
	"Downloads"
)

#Fetching Current User
$activeUsername = (Get-WMIObject Win32_ComputerSystem | Select-Object username).username
$currentUser = $activeUsername -replace '.*\\'

#Asking technician to fill in current user and applying 
#$previoususer = Read-Host -Prompt "What is the name of the user folder that we are trying to migrate?"
$previoususer = # Replace this line with the foldername in quotes. ex. chrisng
Foreach ($location in $locations) {
	Start-Sleep -seconds 2
	$userPath = "C:\Users\$($currentUser)\$($location)"
	$previousPath = "C:\Users\$($previoususer)\$($location)"
	#$previousPath = "C:\Users\Testchris\Downloads\Testfolder\$($location)"
	robocopy $previousPath $userPath /E /ZB /R:0 /W:0 /V /XJ /FFT
	Write-Host "$location has been restored to $currentuser. Please verify all files have been restored."
}