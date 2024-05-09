$serial = Get-WmiObject win32_bios | select Serialnumber
$currentComputerName = $env:COMPUTERNAME
$desiredComputerName = "BW-$serial"
Write-Host "The device serial number is $($serial)"
Write-Host "Current device name is $($olddevicename)"
#Confirm that signed in user is CORP\. if so, continue with script.
Write-Host "Checking that machine belongs to the CORP domain"
$activeUsername = (Get-WMIObject Win32_ComputerSystem | Select-Object username).username


# Check if the current computer name matches the desired pattern
if ($currentComputerName -ne $desiredComputerName) {
    # Rename the computer to the desired pattern
	try {
		Rename-Computer -NewName $desiredComputerName -Force -Restart
		Write-Host "Computer renamed to $desiredComputerName. Restarting..."
		}
	catch {
	
	}
} 
else {
    Write-Host "Computer name already matches the desired pattern."
}