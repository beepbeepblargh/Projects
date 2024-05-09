# Disable Admin Access
$activeUsername = (Get-WMIObject Win32_ComputerSystem | Select-Object username).username
Write-Host "Current user is $activeUsername"
try {
	net localgroup Administrators "$($activeUsername)" /delete
}
catch {
	Write-Host "Script failed. Review transcript if possible"
}