$computer = $env:ComputerName
$dom = $env:userdomain
$user = Get-ChildItem "\\$computer\c$\Users" | Sort-Object LastWriteTime -Descending | Select-Object Name, LastWriteTime -first 1
# Pulls most recent user. This script should only be run if the user was the most recent person who signed in.
$usr = ($user.Name)
$FullName = ([adsi]"WinNT://$dom/$usr,user").fullname
$Comments = "AddLater"
$Tag = "AddLater"
$filename = '*bomgar-scc-win64.msi*'#you can use wildcards here for name and for extension
$searchinfolder = "C:\Program Files (x86)\LANDesk\LDClient\sdmcache\ld\packages\Bomgar\*"
$StoredFolder = Get-ChildItem -Path $searchinfolder -Filter $filename -Recurse | %{$_.FullName}
$checkpath = 'C:\"Program Files (x86)"\LANDesk\LDClient\sdmcache\ld\packages\Bomgar\bomgar-scc-win64.msi'

function Install-Bomgar {
	If (($usr) -eq "Helpdesk") {
		Write-Host "Please change device info from the console ASAP to match user."
		msiexec /i $checkpath KEY_INFO=w0edc308jd67d5h8ziwhji6x8hx866eeiwezyg1c40hc90 jc_name=$computer jc_Comments=$Comments jc_tag=$Tag /quiet
	}
	Elseif (($usr) -ne "Helpdesk") {
		Write-Host "Pulling user info"
		msiexec /i $checkpath KEY_INFO=w0edc308jd67d5h8ziwhji6x8hx866eeiwezyg1c40hc90 jc_name=$FullName jc_Comments=$usr jc_tag=$Tag /quiet
	}
	Else {
		Write-Error -ErrorRecord $_
		exit
	}
}
Write-Host "Verifying that Bomgar installation package is on desktop"
Test-Path -Path $checkpath

If ($StoredFolder -eq $checkpath) {
	Install-Bomgar
}
Else {
	Write-Host "File location did not match. Please add file to the desktop"
	exit
}
