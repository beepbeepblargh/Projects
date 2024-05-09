<# 
.IntuneEnroller.ps1
Enrolls the machine into Intune AFTER a machine shows up in EntraID.
If the machine is not in EntraID, please either have the user manually add their machine to Entra, or attempt to run the .ppkg file again.
#> 

Start-Transcript -Append "C:\ProgramData\IntuneMigration\post-migration.log" -Verbose

try {
	Start-Process -FilePath "C:\Windows\system32\deviceenroller.exe" -ArgumentList @("/c", "/AutoEnrollMDM") -Passthru
	Write-Host "Device enrolled into Intune. Wait 1 minute and verify within Intune"
}
catch {
	Write-Host "Enrollment Failed. Review logs"
}

Stop-Transcript