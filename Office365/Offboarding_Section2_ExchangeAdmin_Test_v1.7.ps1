<# 
.Requires -version 2 - Runs in Exchange Management Shell
- Written by Chris Ng
# This script is intended to automate the creation of an OOO message
# and to convert the user's mailbox to a shared mailbox.
# Confirmed working, may need to switch Connect-MsolService and Connect-EXOPSSession.
# 
# v.1.7 - Added function to check mailbox if it exists. If it does, it'll proceed with mailbox check, otherwise, it'll just assign an E3.
# v.1.6.1 - Fixed logic issue as the original comparison compared two unlike custom objects rather than Long Integers.
# v.1.6 - Further logic added to compare the mailbox and the quota size to ensure no Mailbox error occurs.
# v.1.5 - Logic added for assigning E1 and E3 licenses (Work In Progress)
# v.1.4 - CSV prompt
# v.1.3 - Added Error handling
# v.1.2 - Converted script into a function for easier viewing
# v.1.1 - Cleaned up some of the automation/added a lot more variables.
# v.1.0 - Proof of concept barebones ver.



#>

Connect-MsolService
# Make sure this runs first. Otherwise, you won't connect to MS Office 365 properly. Requires logic to detect whether or not it's already been run.
Connect-EXOPSSession

# Sometimes needs to switch between Connect-MsolService or EXOPSSession
# May be because of whether or not a user is a consultant due to manual and automated offboarding.
# May need an if command to check the user's title first and run which connect service based on that.
Import-Module ActiveDirectory
Import-Module MsOnline

$Multiuser = Read-Host -Prompt "Do you need to add multiple users? (Y/N only)"
# WIP
$CSVFile = "C:\Users\c-christopher.ng\documents\csv\HuluUsers.csv"
$logdate = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
$logname = ".\" + "Office365log_" + "$logdate" + ".txt"
# String for a log file. Location needs to exist first. First draft to see if it works.

Function Start-Countdown {  
    Param(
        [Int32]$Seconds = 240,
        [string]$Message = "Pausing for 4 minutes..."
    )
    ForEach ($Count in (1..$Seconds))
    {   Write-Progress -Id 1 -Activity $Message -Status "Waiting for $Seconds seconds, $($Seconds - $Count) left" -PercentComplete (($Count / $Seconds) * 100)
        Start-Sleep -Seconds 1
    }
    Write-Progress -Id 1 -Activity $Message -Status "Completed" -PercentComplete 100 -Completed
}

function Get-MailboxCheck {
    $MailboxCheck=(Get-Mailbox -Identity $HuluUser -ErrorAction SilentlyContinue)
    If ($MailboxCheck -eq $null){
        Return $False}
    Else {Return $True}
}

Function Assign-License {
	$E1StandardLicense = Get-MsolAccountSku | Where-Object {$_.skuPartNumber -eq "STANDARDPACK"} 
	$E1StandardLicenseTotal = $E1StandardLicense.ActiveUnits - $E1StandardLicense.ConsumedUnits
	$E3EnterpriseLicense = Get-MsolAccountSku | Where-Object {$_.skuPartNumber -eq "ENTERPRISEPACK"} 
	$E3EnterpriseLicenseTotal = $E3EnterpriseLicense.ActiveUnits - $E3EnterpriseLicense.ConsumedUnits
	# The above lines will try and see how many licenses are left for E1/E3.
	$MailboxTotalItemSizeObject = Get-MailboxStatistics -Identity $HuluEmail | Select -ExpandProperty TotalItemSize | Select -ExpandProperty Value
	$MailboxTotalItemSizeValue = $MailboxTotalItemSizeObject.tostring().trimend(" bytes)").split("(")
	$MailboxTotalItemSize = [long]$MailboxTotalItemSizeValue[1]
	# The Above Lines go through the painstaking process of coverting the object to a string, removing some sections, and then converting to a long integer.
	# For comparing the mailbox items with its storage size.
	$MailboxSizeObject = Get-Mailbox -Identity $HuluEmail | Select -ExpandProperty ProhibitSendQuota
	$MailboxSizeValue = $MailboxSizeObject.tostring().trimend(" bytes)").split("(")
	$MailboxSize = [long]$MailboxSizeValue[1]
	$MailboxExists = Get-Mailbox -Identity $HuluEmail
	# The Above Lines go through the painstaking process of coverting the object to a string, removing some sections, and then converting to a long integer.
	# For comparing the mailbox items with its storage size.

	# try {
	# $MailboxExists
	# Write-Host "Checking to see if mailbox currently exists."
	# }
	# catch {
	
	# }
	#Need to check if mailbox exists first. Add Lines here to detect Mailbox. OR, if it doesn't, can look into expanding ProhibitSendQuota temporarily.
	#Set-Mailbox <UserID> -ProhibitSendQuota 100GB -ProhibitSendReceiveQuota 100GB -IssueWarningQuota 100GB
	$error.clear()
	If (($MailboxTotalItemSize -lt $MailboxSize) -and ($E1StandardLicenseTotal -gt 0)) {
	# May need to make this an -and
		try {
			Write-Host "Attempting to add E1 License"
			Set-MsolUserLicense -UserPrincipalName $HuluEmail -AddLicenses hulu:StandardPACK
		}
		catch {
			Write-Error -Message $_.Exception.Message
			echo $_.Exception | format-list -force >> $Logname
		}
	}
	ElseIf (($E3EnterpriseLicenseTotal -gt 0) -or ($error)){
		try {
			Write-Host "Could not add E1 License. Attempting to add E3 License"
			Set-MsolUserLicense -UserPrincipalName $HuluEmail -AddLicenses hulu:EnterprisePACK
		}
		catch {
			Write-Error -Message $_.Exception.Message
			echo $_.Exception | format-list -force >> $Logname
		}
	}
	Else {
		Write-Host "Could not add any licenses. Closing script and writing error log."
		Exit
	}
}

function Set-MailStuff {
	Write-Host "Waiting 4 minutes for mailbox to sync." -ForegroundColor Yellow
	Start-Countdown -Seconds 240 -Message "Counting down from 4 minutes"
#	Comment the above out if deemed unnecessary

	Write-Host "Attempting to add OOO Message now."
	#THE FOLLOWING ATTEMPTS TO ADD AN OOO MESSAGE TO A USER'S MAILBOX	
	$error.clear()
	try { 
		Set-MailboxAutoReplyConfiguration -Identity $HuluEmail -AutoReplyState Enabled -InternalMessage "Hello, The Hulugan you're attempting to contact is no longer with Hulu. If you require additional help, feel free to contact $Manager at $ManagerEmail. Thank you" -ExternalMessage "Hello, The Hulugan you're attempting to contact is no longer with Hulu. If you require additional help, feel free to contact $Manager at $ManagerEmail. Thank you" -ExternalAudience All -ErrorAction Stop
	}
	catch { 
		Write-Host "`n"
		Write-Host "Error occurred. Please review the Exchange Admin console and the following error." -ForegroundColor Red
		"`t Error occurred when attempting to add an OOO message" >> $logname
		echo $_.Exception | format-list -force >> $logname
		Write-Host $_.exception -ForegroundColor Red | format-list -force
	}
	
	If (!$error) {
		Write-Host "`n"
		Write-Host "No error occurred. OOO has been successfully added. Continuing script." -ForegroundColor Green
		Get-MailboxAutoReplyConfiguration $HuluEmail | Select -ExpandProperty ExternalMessage
	}
	
	# THE FOLLOWING BLOCK ATTEMPTS TO CONVERT THE USER'S MAILBOX TO A SHARED MAILBOX.
	Write-Host "Attempting to convert the user's mailbox to a shared mailbox"
	$error.clear()
	try {		
		Set-Mailbox -Identity $HuluEmail -Type Shared -ErrorAction Stop		
	}
	catch {	
		Write-Host "`n"
		Write-Host "Error occurred. Please review the Exchange Admin console and the following error." -ForegroundColor Red
		"`t Error occurred when attempting to convert a mailbox to shared" >> $logname
		echo $_.Exception | format-list -force >> $logname
		Write-Host $_. -ForegroundColor Red	
	}
	If (!$error) {	
		Write-Host "Mailbox is now shared." -ForegroundColor Green		
	}

	(Get-MsolUser -UserPrincipalName $HuluEmail).licenses.AccountSkuId | Foreach { Set-MsolUserLicense -UserPrincipalName $HuluEmail -RemoveLicenses $_ }
	Write-Host "`n"
	Write-Host "Licenses have been removed" -ForegroundColor Green
	Get-MsolUser -UserPrincipalName $HuluEmail
}

If ($Multiuser -eq "Y") {
	$HuluUserCSV = Import-CSV $CSVFile
	Foreach ($User in $HuluUserCSV) {
		$HuluEmail = $User.Mail
		$HuluUser = $User.SamAccountName
		$Value = Get-Msoluser -userprincipalname $HuluEmail | Select-Object -ExpandProperty IsLicensed
		$Manager = Get-ADUser $HuluUser -Properties * | Select @{N='Manager';E={$_.Manager.Substring($_.Manager.IndexOf("=") + 1, $_.Manager.IndexOf(",") - $_.Manager.IndexOf("=") - 1)}} | Select-Object -ExpandProperty Manager
		# Pulls manager's name from AD User's property and then removes it 
		$ManagerEmail = Get-ADUser $HuluUser -properties * | select Displayname, Givenname, Surname, Enabled, EmployeeNumber, EmailAddress, Department, StreetAddress, Title, Country, Office, employeeType, SID, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}} | Select-Object -ExpandProperty ManagerEmail
		# Pulls the manager's email from the user properties. Can probably be written better without unnecessary repetition.

		Write-Host "$HuluUser is being worked on" -ForegroundColor Blue
		If ($Value -eq $true) {
			Write-Host "User has a valid license." -ForegroundColor Yellow
		#	Changed this to a variable to make it easier to reference and hopefully make this more efficient.
			(Get-MsolUser -UserPrincipalName $HuluEmail).licenses.AccountSkuId
			(Get-MsolUser -UserPrincipalName $HuluEmail).licenses.AccountSkuId | Foreach { Set-MsolUserLicense -UserPrincipalName $HuluEmail -RemoveLicenses $_ }
		#	The above SHOULD iterate through the list of licenses associated with the email and then remove them.
			Write-Host "All licenses have been removed." -ForegroundColor Green
			Assign-License
			Set-MailStuff
			Write-Host "`n"
			Write-Host "Adding Next User" -ForegroundColor Green
		}

		ElseIf ($Value -eq $false) {
			Write-Host "User does not have a license. Adding an E3 license." -ForegroundColor Yellow
			Assign-License
			# Need to add logic for determining what license to add, as the next line will state the user has an E1 license.
			Set-MailStuff
			Write-Host "`n"
			Write-Host "Adding Next User" -ForegroundColor Green
		}
	
		Else {
			Write-Host "Error Occurred" -ForegroundColor Red 
			Exit
		}
	}
}

ElseIf ($Multiuser -eq "N") {
	Write-Host "Executing Single User Add Script" -ForegroundColor Green
	$HuluUser = Read-Host -Prompt "What is the user's Hulu account?"
	$HuluEmail = $HuluUser + "@hulu.com"
	# change this later to Get-ADUser $HuluUser -Properties * | 
	#$Manager = ""
	#$ManagerEmail = ""
	$Manager = Get-ADUser $HuluUser -Properties * | Select @{N='Manager';E={$_.Manager.Substring($_.Manager.IndexOf("=") + 1, $_.Manager.IndexOf(",") - $_.Manager.IndexOf("=") - 1)}} | Select-Object -ExpandProperty Manager
	# Pulls manager's name from AD User's property and then removes it 
	$ManagerEmail = Get-ADUser $HuluUser -properties * | select Displayname, Givenname, Surname, Enabled, EmployeeNumber, EmailAddress, Department, StreetAddress, Title, Country, Office, employeeType, SID, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}} | Select-Object -ExpandProperty ManagerEmail
	# Pulls the manager's email from the user properties. Can probably be written better without unnecessary repetition.
	#Get-MsolUser -UserPrincipalName $HuluEmail | Select-Object DisplayName,UserPrincipalName,UsageLocation,IsLicensed
	$Value = Get-Msoluser -userprincipalname $HuluEmail | Select-Object -ExpandProperty IsLicensed
	$MailboxCheck = Get-MailboxCheck 
	# The above line checks on whether the user is licensed or not for Office 365.
		If ($Value -eq $true) {
			Write-Host "User has a valid license." -ForegroundColor Yellow
			#Changed this to a variable to make it easier to reference and hopefully make this more efficient.
			(Get-MsolUser -UserPrincipalName $HuluEmail).licenses.AccountSkuId
			(Get-MsolUser -UserPrincipalName $HuluEmail).licenses.AccountSkuId | Foreach { Set-MsolUserLicense -UserPrincipalName $HuluEmail -RemoveLicenses $_ }
			#The above SHOULD iterate through the list of licenses associated with the email and then remove them.
			Write-Host "All licenses have been removed." -ForegroundColor Green
			If ($MailboxCheck -eq $true){
				Assign-License
				Set-MailStuff
				Exit
			}
			Else {
				Set-MsolUserLicense -UserPrincipalName $HuluEmail -AddLicenses hulu:EnterprisePACK
				Write-Host "Adding E3 License" -ForegroundColor Green
				# Will replace this with a function. This is just out of laziness.
				Set-MailStuff
				Exit
			}
		}

		ElseIf ($Value -eq $false) {
			Write-Host "User does not have a license. Attempting to add an E1 license." -ForegroundColor Yellow
			If ($MailboxCheck -eq $true){
				Assign-License
				Set-MailStuff
				Exit
			}
			Else {
				Set-MsolUserLicense -UserPrincipalName $HuluEmail -AddLicenses hulu:EnterprisePACK
				Write-Host "Adding E3 License" -ForegroundColor Green
				# Will replace this with a function. This is just out of laziness.
				Set-MailStuff
				Exit
			}
		}
	
		Else {
			Write-Host "Error Occured" >> $logname
			Exit
		}
}

Else {
	Write-Host "Error Occurred. Situation not recognized." -ForegroundColor Red >> $logname
	Exit
}
	
# TBA: If E1 is full, set to E3. OR If Cannot Add E1, add E3. OR
#  OR if error = Microsoft.Online.Administration.Automation.LicenseQuotaExceededException,Microsoft.Online.Administration.Automation.SetUserLicense
#  OR I can set up an -errorAction after Set-MsolUserLicense. If the initial standardpack fails, add an E3 license.
# E1 sku= hulu:STANDARDPACK
# E3 sku= hulu:ENTERPRISEPACK
# Set-MailboxAutoReplyConfiguration -Identity $HuluEmail -AutoReplyState Enabled -InternalMessage "Hello, The Hulugan you’re attempting to contact is no longer with Hulu. If you require additional help, feel free to contact $Manager at $ManagerEmail. Thank you" -ExternalMessage "Hello, The Hulugan you’re attempting to contact is no longer with Hulu. If you require additional help, feel free to contact $Manager at $ManagerEmail. Thank you"- for OOO messages in mailbox. Will set this first and then convert mailbox to shared.
# Need to script in success output and Echo messages if success or fail. Also logic for what to do if error occurs. Will make a separate copy of this script for modification purposes.
# May incorporate as a function.