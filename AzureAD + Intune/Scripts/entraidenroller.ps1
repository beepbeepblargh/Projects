<# Entra ID Enroller.ps1
. This script is intended to enroll a machine if it fails to do so initially, with the current .ppkg
installed on the user's machine in C:\ProgramData\IntuneMigration
#>

Start-Transcript -Path "C:\ProgramData\IntuneMigration\entraIDenroller.log" -Verbose

try {
	Write-Host "Installing provisioning package for new Azure AD tenant"
	Install-ProvisioningPackage -PackagePath "$($resourcePath)\migrate.ppkg" -QuietInstall -Force
}
catch {
	Write-Host "Error occurred. Reviewing logs"
}

Stop-Transcript