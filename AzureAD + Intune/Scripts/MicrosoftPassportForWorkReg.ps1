<#
MicrosoftPassportForWorkReg.ps1
This script pushes a reg key that will auto-disable Windows Hello for Business from Prompting 
during sign-in
#>

try {
	if(-NOT (Test-Path -LiteralPath "\[HKEY_LOCAL_MACHINESOFTWAREPoliciesMicrosoftPassportForWork")){ return $false };
}
catch { return $false }
return $true