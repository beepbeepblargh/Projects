<#Selenium_GForms.ps1
Written by Chris Ng
v.0.0.7 - Added logic to identify whether the user is using a Disneystreaming email, disney email, or other. Also condensed the bulk of assigning variables to "Invoke-AutomateXPath"
Notes: Will introduce error handling/try-catches in V.0.0.8 as well as review of user account status. ex. if can't find account, automatically skip.
Also, may need to shuffle certain sections around such as when Selenium pops up during Bulk account creation.	
Final note: Added adding Github_logins as a test run for Single user mode. If it runs smoothly, may add to bulk user in v.0.0.8 along with password resets. Sync time between AD is approx 15 minutes.
v.0.0.6 - Added logic to determine if user is in github_logins
V.0.0.5 - Multi-user version working, but creates separate windows per user added.
V.0.0.4 - Failed 
V.0.0.3 - Logic is working better. Added in a line identifying whether or not the user needs credentials sent or not based on if whencreated -eq passwordlastset. 
V.0.0.2 - Confirmed working, but logic written is a bit shaky. Also, missing auto-updater for ChromeDriver as well as an auto-updater matching the .net version on the computer for webdriver.
V.0.0.1- Testing Google Forms automated manipulating using a combination of AD and Powershell
#>

Import-Module ActiveDirectory
$YourAccount = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$MultiPrompt = Read-Host -Prompt "Is this for multiple users? (Y/N)"

function Close-Selenium {
	$ChromeDriver.close()
	$ChromeDriver.quit()
}

<# The below works, but needs to be modified so that it will only run if either the version or the date matches correctly.

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
	Move-Item "$TempFileUnzipPath/chromedriver" -Destination "C:\Selenium\chromedriver" -Force;
    #Move-Item "$TempFileUnzipPath/chromedriver" -Destination "path/to/save/chromedriver" -Force;
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
function Invoke-AutomateXPath {
			Start-sleep -seconds 5
			$DropdownElement1 = Find-SeElement -Driver $ChromeDriver -Id "SelectId_0_placeholder"
			$FirstNameElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[3]/div/div[2]/div/div/input'
			$SurNameElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[4]/div/div[2]/div/div/input'
			$PersonalEmailElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[5]/div/div[2]/div/div/input'
			$DropdownElement2 = Find-SeElement -Driver $ChromeDriver -Id "SelectId_1"
			Invoke-SeClick -Element $DropdownElement1
			Start-Sleep -seconds 5
			If ($YourAccount.contains('c-christopher.ng')){
				$AccountElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="SelectId_0"]/div[2]/div[2]'
			}
			Else {
				Write-Host "You're not Chris. Closing Script"
				Close-Selenium
				Exit
			}
			Invoke-SeClick -Element $AccountElement
			# Timers are set due to the slowness of automation matching when coinciding with assigning values to variables.
			Send-SeKeys -Element $FirstNameElement -Keys $UserProperties.Givenname
			Send-SeKeys -Element $SurnameElement -Keys $UserProperties.surname
			Send-SeKeys -Element $PersonalEmailElement -keys $UserProperties.EmailAddress
			Start-Sleep -Seconds 3
			Invoke-SeClick -Element $DropdownElement2
			Start-Sleep -Seconds 5
			if ($UserEmail.Contains('@disneystreaming.com')){
				$AccountElement2 = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="SelectId_1"]/div[2]/div[4]/div/span'
				Invoke-AutomateXPathPt2
			}
			elseif ($UserEmail.Contains('@disney.com')){
				$AccountElement2 = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="SelectId_1"]/div[2]/div[5]/div/span'
				Invoke-AutomateXPathPt2
			}
			else {
				Write-Host "User does not have a DS or Disney email. Skipping (will be replaced with manual input in the future)" -ForegroundColor Red
				Close-Selenium
			}

	}
	
function Invoke-AutomateXPathPt2 {
	Start-Sleep -Seconds 2
	Invoke-SeClick -Element $AccountElement2
	Start-Sleep -Seconds 5
	$SamAccountElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[8]/div/div[2]/div/div/input'
	$UserEmailElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[9]/div/div[2]/div/div/input'
	Send-SeKeys -Element $SamAccountElement -Keys $UserProperties.SamAccountName
	Send-SeKeys -Element $UserEmailElement -keys $UserProperties.EmailAddress

	$SubmitElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[3]/div[1]/button/div'
	Start-Sleep -seconds 15
	Invoke-SeClick -Element $SubmitElement
	#commented out the above just in case. Will test it out when I have an actual user that needs to be added to github
	Start-Sleep -seconds 3
	#$SubmitAnother = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[2]/div[2]/div[2]/a'
	#Invoke-SeClick -Element $SubmitAnother
	Close-Selenium
	#Select Element for submitting another form. and then click it.
}

If ($MultiPrompt -eq "Y") {
	$PromptCSV = Read-Host -Prompt "What's the path of the csv file?"
	$HuluUser = Import-CSV -path $PromptCSV
	Start-Sleep -seconds 10
	$admin = Get-Credential
	Foreach ($User in $HuluUser) {
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

		$ChromeDriver.Navigate().GoToURL("https://forms.office.com/Pages/ResponsePage.aspx?id=s8T3eOrNtEeTACIhQlerfkx2F7f8TXpKlF6op6eJm-RUMlFSR0xWOTJIM0NORzQ2NzJFWTg0SDg0Si4u")
		#Google form here. (No longer functional as of 3/15/2022. Needs to be replaced)
		Start-sleep -seconds 3
		$UserProperties = Get-ADUser $User.SamAccountName -properties * | select SamAccountName, Displayname, Givenname, Surname, Enabled, EmployeeNumber, EmailAddress, passwordlastset, whenCreated, Department, StreetAddress, Title, Country, Office, employeeType, SID, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}}
		$UserPasswordLastSet = $userproperties.passwordlastset.tostring()
		$UserWhenCreated = $userproperties.whenCreated.tostring()
		$UserAccountname = $UserProperties.Displayname
		$UserAccount = $UserProperties.SamAccountName
		$UserEmail = $UserProperties.EmailAddress.ToString()
		$Group = "Github_logins"
		$ExistingGroups = Get-ADPrincipalGroupMembership $User.SamAccountName | Select-Object Name
		
		If($ExistingGroups.Name -eq $Group){
			Write-Host "$UserAccount is part of $Group already. Proceeding with script" -ForegroundColor Green
			}
		Else{
			#Write-Host "$UserAccount is not part of $Group. Please add the user after this script is done." -ForegroundColor Yellow
			Write-Host "$UserAccount is not part of github_logins. Attempting to add user to github_logins."
			try {
				Add-ADGroupMember -Identity github_logins -Members $user.SamAccountName -Credential $admin
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
			
		if ($UserPasswordLastSet -eq $UserWhenCreated) {
			Write-Host "$UserAccountname does not know their password. Proceeding with script" -ForegroundColor Green	
			Invoke-AutomateXPath
		}
		Else {
			Write-Host "Review $UserAccountname's account before proceeding" -ForegroundColor Yellow
			$ReviewPrompt = Read-Host -Prompt "Are you sure you want to continue? (Y/N)"
			If ($ReviewPrompt -eq "Y") {
				Write-Host "Continuing with Script" -ForegroundColor Green
				Invoke-AutomateXPath
			}
			Elseif ($ReviewPrompt -eq "N"){
				Write-Host "Skipping to next user." -ForegroundColor Red
				Close-Selenium
				
			}
			Else {
				Write-Host "Response not recognized. Closing script" -ForegroundColor Red
				Exit
			}
	}
	
	}
}

ElseIf ($MultiPrompt -eq "N") {
	$HuluUser = Read-Host -Prompt "What is the username(samAccountName)?"
	#Verify that the user exists. And check if their passwordlastset is the same as whenCreated. 
	$UserProperties = Get-ADUser $HuluUser -properties * | select SamAccountName, Displayname, Givenname, Surname, Enabled, EmployeeNumber, EmailAddress, Department, StreetAddress, Title, Country, Office, employeeType, SID, passwordlastset, whenCreated, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}}
	$UserEmail = $UserProperties.EmailAddress.toString()
	$UserPasswordLastSet = $userproperties.passwordlastset.tostring()
	$UserWhenCreated = $userproperties.whenCreated.tostring()
	$group = "Github_logins"
	$ExistingGroups = Get-ADPrincipalGroupMembership $HuluUser | Select-Object Name
	
	If ($ExistingGroups.Name -eq $Group) {
		Write-Host "$HuluUser already exists in $Group. Proceeding with Script." -ForeGroundColor Yellow
        }
	Else {
		Write-Host "$HuluUser is not part of $Group. Proceeding with script. Will attempt to add user to $Group." -ForegroundColor Yellow
		try {
			Add-ADGroupMember -Identity github_logins -Members $HuluUser -Credential $admin
			$ExistingGroups = Get-ADPrincipalGroupMembership $HuluUser | Select-Object Name
				If ($ExistingGroups.Name -eq $Group) {
					Write-Host "$HuluUser already exists in $Group." -ForeGroundColor Green
					}
				Else {
					Write-Host "$HuluUser successfully added to $Group. Await 15 minutes for sync to occur in AD" -ForeGroundColor Green
				}
		}
		catch {
			Write-Host "Encountered Error" -ForegroundColor Red
		}
	}
	
	If ($UserPasswordLastSet -eq $UserWhenCreated) {
		Write-Host "This user does not know their password." -ForegroundColor Green
	}
	Else {
		Write-Host "Review this user's account before proceeding" -ForegroundColor Yellow
		$ReviewPrompt = Read-Host -Prompt "Are you sure you want to continue? (Y/N)"
		If ($ReviewPrompt -eq "Y") {
			Write-Host "Continuing with Script" -ForegroundColor Green
		}
		Elseif ($ReviewPrompt -eq "N"){
			Write-Host "Closing Script" -ForegroundColor Red
			Exit
		}
		Else {
			Write-Host "Response not recognized. Closing script" -ForegroundColor Red
			Exit
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

	$ChromeDriver.Navigate().GoToURL("https://forms.office.com/Pages/ResponsePage.aspx?id=s8T3eOrNtEeTACIhQlerfkx2F7f8TXpKlF6op6eJm-RUMlFSR0xWOTJIM0NORzQ2NzJFWTg0SDg0Si4u")
	#may need to replace webdriver.dll

	Start-sleep -seconds 5
	Invoke-AutomateXPath
	Close-Selenium
}
Else {
	Write-Host "Error occurred. Closing session." -ForegroundColor Red
	Close-Selenium

}

Close-Selenium
#$ChromeDriver.FindElementByXPath('//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[3]/div/div[2]/div/div/input').SendKeys('Charles')
# Above commented out does not work as .Findelementbyxpath() does not exist apparently.
