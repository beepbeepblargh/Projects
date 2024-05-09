$Path = "HKLM:\\SOFTWARE\Policies\Microsoft\PassportForWork"
$Key = "Enabled"
$Key2 = "DisablePostLogonProvisioning"
$KeyFormat = "DWord"
$Value = "1"

if(!(Test-Path $Path)){New-Item -Path $Path -Force}
Set-ItemProperty -Path $Path -Name $Key -Value $Value -Type $KeyFormat
Set-ItemProperty -Path $Path -Name $Key2 -Value $Value -Type $KeyFormat