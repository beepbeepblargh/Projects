# Written by Chris Ng
$computer = $env:ComputerName
$usr = $env:username
$filename = '*bomgar-scc-win64.msi*'#you can use wildcards here for name and for extension
$searchinfolder = "C:\Users\$usr\*"
$StoredFolder = Get-ChildItem -Path $searchinfolder -Filter $filename -Recurse | %{$_.FullName}
$checkpath = "C:\Users\$usr\desktop\bomgar-scc-win64.msi"

# Checks Path. I should incorporate the do-whiles into a function so that the matching occurs before the do-whiles.
Write-Host "Verifying that Bomgar installation package is on desktop"
Test-Path -Path $checkpath

function Install-Bomgar {
	If (($usr) -eq "Helpdesk") {
		msiexec /i $checkpath KEY_INFO=w0edc308jd67d5h8ziwhji6x8hx866eeiwezyg1c40hc90 jc_name=$FullNameQuotes jc_Comments=$CommentsQuotes jc_tag=$TagQuotes /quiet
	}
	Else {
		Write-Error -ErrorRecord $_
		exit
	}
}

# $Fullname
DO{
	$FullName = Read-Host -Prompt "What is the user's full name?"
	$FullNameQuotes = '"{0}"' -f $FullName
}
While ( ($Null -eq $Fullname) -or ($Fullname -eq '') ) {
}

If ($FullName -ne '') {
	Write-Host "[$FullName] added"
}

# $Comments
DO{
	$Comments = Read-Host -Prompt "What is their username and extension?"
	$CommentsQuotes = '"{0}"' -f $Comments
}
While ( ($Null -eq $Comments) -or ($Comments -eq '') ) {
}

If ($Comments -ne '') {
	Write-Host "[$Comments] added"
}

# $Tag 	
DO{
	$Tag = Read-Host -Prompt "What additional info would you like to add?"
	$TagQuotes = '"{0}"' -f $Tag

}
While ( ($Null -eq $Tag) -or ($Tag -eq '') ) {
}

If ($Tag -ne '') {
	Write-Host "[$Tag] added"
}

# Check location matches and then executes.
If ($StoredFolder -eq $checkpath) {
	Install-Bomgar
}
Else {
	Write-Host "File location did not match. Please add file to the desktop"
	exit
}

