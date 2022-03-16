<#Selenium_Jira_AutoAdd.ps1
Note: Purpose of this script is to auto-add users from Active Directory to Jira using Selenium to automate and identify web elements.
V.0.2.0 - Modified Script to include auto-adding Okta-Jira in an attempt to consolidate account creation and adding to one place.
Keep in mind that Hulu Jira is basically defunct now, but cool concept either way.
V.0.1.0 - Modified script to use encrypted password, CTRL + A to highlight and remove box fields if the user already exists, and clicking cancel in the event the user fails. Still needs a way to interact with "Leave Page" javascript window.
V.0.0.1- Testing Google Forms automated manipulatiion using a combination of AD, Powershell, and ChromeDriver
#>

Import-Module ActiveDirectory
$userName = 'c-christopher.ng@hulu.com'
$Password = Get-Content "" | ConvertTo-SecureString
#Replace above "" with encrypted password text file. Note that this is NOT a secure method.
$Marshal = [System.Runtime.InteropServices.Marshal]
$Bstr = $Marshal::SecureStringToBSTR($Password)
$SecurePwd = $Marshal::PtrToStringAuto($Bstr)
$Marshal::ZeroFreeBSTR($Bstr)
#The above code block will take my Encrypted password and temporarily unencrypt it to be used in Okta. It will also clear the memory after so it won't get stored anywhere.

$MultiPrompt = Read-Host -Prompt "Is this for multiple users? (Y/N)"

function Close-Selenium {
	$ChromeDriver.close()
	$ChromeDriver.quit()
}

<#

Function Get-ChromeVersion {
	If ($IsWindows -or $Env:OS) {
		Try {
			(Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)').VersionInfo.FileVersion
			}
		Catch{
			throw "'Google Chrome Not Found in Registry";
			}
	}
}

$ChromeVersion = Get-ChromeVersion -ErrorAction Stop;
Write-Output "Google Chrome version $ChromeVersion found on machine";

$ChromeVersion = $ChromeVersion.Substring(0, $ChromeVersion.LastIndexOf("."));
#   and append the result to URL "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_". 
#   For example, with Chrome version 72.0.3626.81, you'd get a URL "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_72.0.3626".
$ChromeDriverVersion = (Invoke-WebRequest "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$ChromeVersion").Content;
Write-Output "Latest matching version of Chrome Driver is $ChromeDriverVersion";

$TempFilePath = [System.IO.Path]::GetTempFileName();
# replacing the above just in case with the line below.
#$TempFilePath = c:\Selenium\chromedriver.exe;
$TempZipFilePath = $TempFilePath.Replace(".tmp", ".zip");
Rename-Item -Path $TempFilePath -NewName $TempZipFilePath;
$TempFileUnzipPath = $TempFilePath.Replace(".tmp", "");

If ($IsWindows -or $Env:OS) {
    Invoke-WebRequest "https://chromedriver.storage.googleapis.com/$ChromeDriverVersion/chromedriver_win32.zip" -OutFile $TempZipFilePath;
    Expand-Archive $TempZipFilePath -DestinationPath $TempFileUnzipPath;
    Move-Item "$TempFileUnzipPath/chromedriver.exe" -Destination "path/to/save/chromedriver.exe" -Force;
}
ElseIf ($IsMacOS) {
    Invoke-WebRequest "https://chromedriver.storage.googleapis.com/$ChromeDriverVersion/chromedriver_mac64.zip" -OutFile $TempZipFilePath;
    Expand-Archive $TempZipFilePath -DestinationPath $TempFileUnzipPath;
    Move-Item "$TempFileUnzipPath/chromedriver" -Destination "path/to/save/chromedriver" -Force;
}
Else {
    Throw "Your operating system is not supported by this script.";
}
#>

<#
# Clean up temp files
Remove-Item $TempZipFilePath;
Remove-Item $TempFileUnzipPath -Recurse;
#>

If ($Multiprompt -eq "Y") {
	$HuluUser = Import-CSV -Path 'C:\Users\c-christopher.ng\Documents\BulkUser.csv'
	$admin = Get-Credential
	$workingPath = 'C:\Selenium'
	if (($env:Path -split ';') -notcontains $workingPath) {
		$env:Path += ";$workingPath"
	}

	$env:Path -split ';'

	Import-Module "$($workingPath)\WebDriver.dll"
	$ChromeOptions = New-Object OpenQA.Selenium.Chrome.ChromeOptions
	$ChromeOptions.addArguments('headless')
	# Allows chrome driver to run parallel to you doing other actions on PC.
	$ChromeDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver

	$ChromeDriver.Navigate().GoToURL("https://jira.hulu.com/secure/admin/user/UserBrowser.jspa")
	#may need to replace webdriver.dll


	$OktaEmail = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="idp-discovery-username"]'
	$OktaRememberBox = Find-SeElement -Driver $chromedriver -XPath '//*[@id="form1"]/div[1]/div[2]/div[2]/div/span/div/label'
	$OktaNext = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="idp-discovery-submit"]'
	Send-SeKeys -Element $OktaEmail -Keys $userName
	Invoke-SeClick -Element $OktaRememberBox
	Start-Sleep -seconds 2
	Invoke-SeClick -Element $OktaNext

	Start-Sleep -Seconds 3
	$OktaPassword = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="okta-signin-password"]'
	Send-SeKeys -Element $OktaPassword -Keys $SecurePwd
	$OktaSignin = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="okta-signin-submit"]'
	Invoke-SeClick -Element $OktaSignin
	Start-Sleep -Seconds 3
	$OktaSendPush = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form96"]/div[2]/input'
	Invoke-SeClick -Element $OktaSendPush
	Start-Sleep -Seconds 15
	$JiraLogin = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="login-form-authenticatePassword"]'
	Send-SeKeys -Element $JiraLogin -Keys $SecurePwd
	$JiraConfirmBox = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="login-form-submit"]'
	Invoke-SeClick -Element $JiraConfirmBox
	#The above block deals with automating the Okta Login Prompt.



	<#
	$ElementRetry = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="resubmit-form"]/div/input[11]'
	Invoke-SeClick -Element $ElementRetry
	The above is if initial login fails.
	#>
	Start-Sleep -seconds 5
	Foreach ($User in $HuluUser) {
		$Group = "Okta-Jira"
		$ExistingGroups = Get-ADPrincipalGroupMembership $User.SamAccountName | Select-Object Name		
		If($ExistingGroups.Name -eq $Group){
			Write-Host "$User is part of $Group already. Proceeding with script" -ForegroundColor Green
			}
		Else{
			#Write-Host "$UserAccount is not part of $Group. Please add the user after this script is done." -ForegroundColor Yellow
			Write-Host "$User is not part of $Group. Attempting to add user to $Group." -foregroundcolor Yellow
			try {
				Add-ADGroupMember -Identity $Group -Members $user.SamAccountName -Credential $admin
				$ExistingGroups = Get-ADPrincipalGroupMembership $user.SamAccountName | Select-Object Name
				If ($ExistingGroups.Name -eq $Group) {
					Write-Host "$User already exists in $Group." -ForeGroundColor Green
					}
				Else {
					Write-Host "$User successfully added to $Group. Await 15 minutes for sync to occur in AD" -ForeGroundColor Green
				}
			}
			catch {
			Write-Host "Encountered Error" -ForegroundColor Red
			# Commented above out as this needs to be run from X-Account to be able to add to groups from Powershell.
			}
		}
		Start-sleep -seconds 3
		$ElementCreateUser = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="create_user"]'
		Invoke-SeClick -Element $ElementCreateUser
		Start-Sleep -seconds 2

		$UserProperties = Get-ADUser $User.SamAccountName -properties * | select SamAccountName, Displayname, Givenname, Surname, Enabled, EmployeeNumber, EmailAddress, Department, StreetAddress, Title, Country, Office, employeeType, SID, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}}
		$ElementEmailAddress = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-email"]'
		$ElementNameUser = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-fullname"]'
		$ElementSamAccount = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-username"]'
		$ElementCreateAnother = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create"]/div/div[6]/fieldset/div/label'
		$ElementCreateUser = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-submit"]'

		Send-SeKeys -Element $ElementEmailAddress -Keys $UserProperties.EmailAddress
		Start-Sleep -seconds 1
		Send-SeKeys -Element $ElementNameUser -Keys $UserProperties.Displayname
		#Need to refer to Active Directory and subtract the (DSS) portion of this, otherwise, I'll have to continue to pull from the CSV.
		Send-SeKeys -Element $ElementSamAccount -Keys $UserProperties.samaccountname
		#Invoke-SeClick -Element $ElementCreateAnother
		Start-Sleep -Seconds 10
		Invoke-SeClick -Element $ElementCreateUser
		Start-Sleep -Seconds 5
		$ElementUserExists = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-username-error"]'
		If ($ElementUserExists.displayed -eq $True) {
			$ElementEmailAddress = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-email"]'
			$ElementNameUser = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-fullname"]'
			$ElementSamAccount = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-username"]'
			$ElementCancel = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-cancel"]'
			Send-SeKeys -Element $ElementEmailAddress -Keys ([OpenQA.Selenium.Keys]::delete)
			Send-SeKeys -Element $ElementNameUser -Keys ([OpenQA.Selenium.Keys]::control, 'a')
			Send-SeKeys -Element $ElementNameUser -Keys ([OpenQA.Selenium.Keys]::delete)
			Send-SeKeys -Element $ElementSamAccount -Keys ([OpenQA.Selenium.Keys]::Control, 'a')
			Send-SeKeys -Element $ElementSamAccount -Keys ([OpenQA.Selenium.Keys]::delete)
			# Or if missing a field, Log the user that wasn't added and then skip to the next one. 
			}
		Else {
			$ElementCancel = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-cancel"]'
			Start-sleep -Seconds 5
			Invoke-SeClick -Element $ElementCancel
		}
	}
}
Elseif ($Multiprompt -eq "N") {
	$HuluUser = Read-Host -Prompt "What is the user you need created in Jira?"
	$Group = "Okta-Jira"
	$ExistingGroups = Get-ADPrincipalGroupMembership $HuluUser | Select-Object Name		
		If($ExistingGroups.Name -eq $Group){
			Write-Host "$HuluUser is part of $Group already. Proceeding with script" -ForegroundColor Green
			}
		Else{
			#Write-Host "$UserAccount is not part of $Group. Please add the user after this script is done." -ForegroundColor Yellow
			Write-Host "$HuluUser is not part of $Group. Attempting to add user to $Group." -foregroundcolor Yellow
			try {
				Add-ADGroupMember -Identity $Group -Members $HuluUser -Credential $admin
				$ExistingGroups = Get-ADPrincipalGroupMembership $HuluUser | Select-Object Name
				If ($ExistingGroups.Name -eq $Group) {
					Write-Host "$HuluUser already exists in $Group." -ForeGroundColor Green
					}
				Else {
					Write-Host "HuluUser successfully added to $Group. Await 15 minutes for sync to occur in AD" -ForeGroundColor Green
				}
			}
			catch {
			Write-Host "Encountered Error" -ForegroundColor Red
			}
		}
		
		$workingPath = 'C:\Selenium'
	if (($env:Path -split ';') -notcontains $workingPath) {
		$env:Path += ";$workingPath"
	}

	$env:Path -split ';'

	Import-Module "$($workingPath)\WebDriver.dll"
	$ChromeOptions = New-Object OpenQA.Selenium.Chrome.ChromeOptions
	$ChromeOptions.addArguments('headless')
	# Allows chrome driver to run parallel to you doing other actions on PC.
	$ChromeDriver = New-Object OpenQA.Selenium.Chrome.ChromeDriver

	$ChromeDriver.Navigate().GoToURL("https://jira.hulu.com/secure/admin/user/UserBrowser.jspa")
	#may need to replace webdriver.dll or wrap C# in powershell to get methods working properly.

	$OktaEmail = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="idp-discovery-username"]'
	$OktaRememberBox = Find-SeElement -Driver $chromedriver -XPath '//*[@id="form18"]/div[1]/div[2]/div[2]/div/span/div/label'
	$OktaNext = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="idp-discovery-submit"]'

	Send-SeKeys -Element $OktaEmail -Keys $userName
	Invoke-SeClick -Element $OktaRememberBox
	Start-Sleep -seconds 2
	Invoke-SeClick -Element $OktaNext

	Start-Sleep -Seconds 3
	$OktaPassword = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="okta-signin-password"]'
	Send-SeKeys -Element $OktaPassword -Keys $SecurePwd
	$OktaSignin = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="okta-signin-submit"]'
	Invoke-SeClick -Element $OktaSignin
	Start-Sleep -Seconds 5
	$OktaSendPush = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form96"]/div[2]/input'
	Invoke-SeClick -Element $OktaSendPush
	Start-Sleep -Seconds 15
	$JiraLogin = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="login-form-authenticatePassword"]'
	Send-SeKeys -Element $JiraLogin -Keys $SecurePwd
	$JiraConfirmBox = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="login-form-submit"]'
	Invoke-SeClick -Element $JiraConfirmBox
	#The above block deals with automating the Okta Login Prompt.

	<#
	$ElementRetry = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="resubmit-form"]/div/input[11]'
	Invoke-SeClick -Element $ElementRetry
	The above is if initial login fails.
	#>
	Start-Sleep -seconds 5
	$ElementCreateUser = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="create_user"]'
	Invoke-SeClick -Element $ElementCreateUser
	Start-Sleep -seconds 2

	$UserProperties = Get-ADUser $HuluUser -properties * | select SamAccountName, Displayname, Givenname, Surname, Enabled, EmployeeNumber, EmailAddress, Department, StreetAddress, Title, Country, Office, employeeType, SID, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}}
	$ElementEmailAddress = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-email"]'
	$ElementNameUser = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-fullname"]'
	$ElementSamAccount = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-username"]'
	$ElementCreateAnother = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create"]/div/div[6]/fieldset/div/label'
	$ElementCreateUser = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-submit"]'

	Send-SeKeys -Element $ElementEmailAddress -Keys $UserProperties.EmailAddress
	#If this doesn't work, will need to make sure the CSV has all of this info and refer back to $User.EmailAddress instead and match the headers of the CSV file
	Send-SeKeys -Element $ElementNameUser -Keys $UserProperties.Displayname
	#Need to refer to Active Directory and subtract the (DSS) portion of this, otherwise, I'll have to continue to pull from the CSV.
	Send-SeKeys -Element $ElementSamAccount -Keys $UserProperties.samaccountname
	#Invoke-SeClick -Element $ElementCreateAnother
	Start-Sleep -Seconds 10
	Invoke-SeClick -Element $ElementCreateUser
	Start-Sleep -Seconds 5
	Wait-SeElementExists -Driver $ChromeDriver -id 'user-create-username-error' -Timeout 5
	$ElementUserExists = Wait-SeElementExists -Driver $ChromeDriver -id 'user-create-username-error'
	#$ElementUserExists = Find-SeElement -Driver $ChromeDriver -Id 'user-create-username-error'
	
	If ($ElementUserExists.displayed -eq $True) {
		$ElementEmailAddress = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-email"]'
		$ElementNameUser = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-fullname"]'
		$ElementSamAccount = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-username"]'
		$ElementCancel = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="user-create-cancel"]'
		Send-SeKeys -Element $ElementEmailAddress -Keys ([OpenQA.Selenium.Keys]::delete)
		Send-SeKeys -Element $ElementNameUser -Keys ([OpenQA.Selenium.Keys]::control, 'a')
		Send-SeKeys -Element $ElementNameUser -Keys ([OpenQA.Selenium.Keys]::delete)
		Send-SeKeys -Element $ElementSamAccount -Keys ([OpenQA.Selenium.Keys]::Control, 'a')
		Send-SeKeys -Element $ElementSamAccount -Keys ([OpenQA.Selenium.Keys]::delete)
		Start-sleep -Seconds 5
		Invoke-SeClick -Element $ElementCancel
		# Or if missing a field, Log the user that wasn't added and then skip to the next one. 
	}
	start-Sleep -s 15
	Close-Selenium
	Exit
}
Else {
	Close-Selenium
	Write-Host "Error Occurred" -foregroundcolor Red
	Exit
}
start-Sleep -s 15
Close-Selenium
Exit
#$ChromeDriver.FindElementByXPath('//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[3]/div/div[2]/div/div/input').SendKeys('Charles')
# Above commented out does not work as .Findelementbyxpath() does not exist apparently.
