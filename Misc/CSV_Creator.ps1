# CSV Creator - v.0.1
# Written by Chris Ng
# Exports and appends users one by one to a CSV file if need be.
# Will experiment with either foreach or while loops to see which works best here.Can also wrap this into user_properties_listing
#$logdate = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
#$UserCSV = "C:\Users\c-christopher.ng\documents\" + "UserCSV_" + "$logdate"
# Aim is to wrap the bottom line with a foreach so that it will prompt you for a username
# and for each username, it gets appended into the CSV with the below titles.
# Check account, if account exists, run the below line. Else, echo account doesn't exist, try again.

Import-Module ActiveDirectory
$logdate = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
# $OutFile = ".\Documents\CSV\" + "ExportUsers_" + "$logdate" + ".csv"
# $newcsv = {} | Select SamAccountName,DisplayName,GivenName,Surname,Mail,DistinguishedName,Description,Enabled,UserPrincipalName,LastLogon,PasswordExpired,PasswordLastSet,ObjectGUID,MsExchHideFromAddressLists,whenCreated,whenChanged | Export-CSV -NoTypeInformation -path $OutFile
Do {
	$User = Read-host "What is the username you want added?"
	Get-ADUser -Identity $User -properties * | Export-CSV -Append -Path $Outfile
	Write-Host "$User appears to have been added. Double check" -ForegroundColor Green
	$Quit =  Read-Host "Would you like to add another? (Y/N)"
	If ($Quit -eq "[yY]"){
		Write-Host "You have selected Yes. Type in the next user" -ForegroundColor Green
	}
	Else {
		Write-Host "Closing Script" -ForegroundColor Red
		Exit
	}
}
While ($Quit -ne "[nN]")
# Just in case the Else section somehow doesn't catch the script termination.