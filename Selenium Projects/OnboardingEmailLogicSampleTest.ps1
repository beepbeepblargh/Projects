<#Written by Chris Ng
Ver.0.1 - POC version intended to send out mass onboarding emails
#>

Import-Module ActiveDirectory

$Users = Import-Csv -Path "C:/Users/adm-ngc/desktop/sample.csv"
function Close-Selenium {
	$ChromeDriver.close()
	$ChromeDriver.quit()
}
function Invoke-AutomateXPath {
	$UserEmail = $UserIdentity.EmailAddress.ToString()
	$Pernr = $UserIdentity.EmployeeNumber
	$HubID = $UserIdentity.EmployeeID
	$Department = $UserIdentity.Department
	$HiringManagerNameElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[7]/div/div[2]/div/div/input'
	$HiringManagerEmailElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[8]/div/div[2]/div/div/input'
	$NewHireDeptElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[9]/div/div[2]/div/div/input'
	$NewHireCorpEmailElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[11]/div/div[2]/div/div/input'
	$PernrElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[12]/div/div[2]/div/div/input'
	$HubIDElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[13]/div/div[2]/div/div/input'
	$SubmitElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[3]/div[1]/button/div'

	Start-sleep -seconds 3
	$TechEmail = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[2]/div/div[2]/div/div/input'
	$FirstNameElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[3]/div/div[2]/div/div/input'
	$SurNameElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[4]/div/div[2]/div/div/input'
	$PersonalEmailElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[5]/div/div[2]/div/div/input'
	$TodayDate = Get-Date -Format "MM/dd/yyyy"
#Needs to be changed to match the date requested.
	$HireDate = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[6]/div/div[2]/div/div/input[1]'
	$MyEmail = "c-christopher.ng@disneystreaming.com"
	#replace the above with auto-pulled email. Current email is just as a test
	Start-Sleep -seconds 3
	<# If ($YourAccount.contains('c-christopher.ng')){
		$AccountElement = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="SelectId_0"]/div[2]/div[2]'
	}
		Else {
		Write-Host "You're not Chris. Closing Script"
		Close-Selenium
		Exit
		}
		Invoke-SeClick -Element $AccountElement
	#>
	# Timers are set due to the slowness of automation matching when coinciding with assigning values to variables.
	Send-SeKeys -Element $TechEmail -Keys $MyEmail
	Send-SeKeys -Element $FirstNameElement -Keys $UserIdentity.Givenname
	Send-SeKeys -Element $SurnameElement -Keys $UserIdentity.surname
	Send-SeKeys -Element $PersonalEmailElement -keys $Useremail
#Needs to be changed to pulled from somewhere or would have to be paused for the manager to place the item. basically can't be pulled
#Perhaps suggesting saving this info somewhere within user's AD profile. Otherwise, would need to be manually saved in CSV.
	Send-SeKeys -Element $HireDate -keys $TodayDate
	Start-Sleep -Seconds 8
	Send-SeKeys -Element $NewHireCorpEmailElement -keys $Useremail
	Send-SeKeys -Element $PernrElement -Keys $Pernr
	Send-SeKeys -Element $HubIDElement -Keys $HubID
	Start-Sleep -Seconds 5
	$UserRole = $UserIdentity.EmployeeType
	Start-Sleep -Seconds 4
	if ($UserRole -eq "REG"){
		$AccountElement2 = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[10]/div/div[2]/div/div[1]/div/label/input'
		Invoke-SeClick -Element $AccountElement2
	}
	elseif ($UserRole -eq "INT"){
		$AccountElement2 = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[10]/div/div[2]/div/div[2]/div/label/input'
		Invoke-SeClick -Element $AccountElement2
	}
	elseif ($UserRole -eq "CON"){
		$AccountElement2 = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[10]/div/div[2]/div/div[3]/div/label/input'
		Invoke-SeClick -Element $AccountElement2
	}
	elseif ($UserRole -eq "PAR"){
		$AccountElement2 = Find-SeElement -Driver $ChromeDriver -XPath '//*[@id="form-container"]/div/div/div[1]/div/div[1]/div[2]/div[2]/div[10]/div/div[2]/div/div[4]/div/label/input'
		Invoke-SeClick -Element $AccountElement2
	}
	else {
		Write-Host "User does not have a DS or Disney email. Skipping (will be replaced with manual input in the future)" -ForegroundColor Red
		Close-Selenium
	}
	Start-Sleep -seconds 5
#Code Block for Adding Manager and Dept info starts below
	$HiringManagerName = $null
	Start-Sleep -seconds 2
	$HiringManagerName = $UserIdentity.Manager
	Start-Sleep -seconds 2
	
	if ($HiringManagerName -eq $null) {
		$HiringManagerName = "Guest"
		Start-Sleep -seconds 3
		Send-SeKeys -Element $HiringManagerNameElement -Keys $HiringManagerName
		Send-SeKeys -Element $HiringManagerEmailElement -keys "Guest"
		
	}
	else {
		$ManagerActualName = Get-ADUser -Filter * -Searchbase $HiringManagerName -Server bamtech.dss.media -Properties * -ErrorAction SilentlyContinue	| Select Name, Emailaddress
		Start-Sleep -seconds 2
		if ($ManagerActualName) {
			Send-SeKeys -Element $HiringManagerNameElement -Keys $ManagerName.Name
			Send-SeKeys -Element $HiringManagerEmailElement -keys $ManagerName.EmailAddress
		}
		elseif (!$ManagerActualName) {
			$ManagerName = Get-ADUser -Filter * -Searchbase $HiringManagerName -Server ext.dss.media -Properties * -ErrorAction SilentlyContinue | Select Name, Emailaddress
			Start-Sleep -seconds 3
			Send-SeKeys -Element $HiringManagerNameElement -Keys $ManagerName.Name
			Send-SeKeys -Element $HiringManagerEmailElement -keys $ManagerName.EmailAddress			
		}
		else {
			Write-Host "Error"
		}
	}
	$HiringManagerEmail = $UserIdentity.ManagerEmail
	
	if ($Department -eq $null) {
		$Department = "Guest"
		Start-Sleep -seconds 3
		Send-SeKeys -Element $NewHireDeptElement -keys $Department
	}
	else {
		Send-SeKeys -Element $NewHireDeptElement -keys $Department	
	}
	Start-Sleep -seconds 10
	Invoke-SeClick -Element $SubmitElement

}
	



Foreach ($User in $Users) {
    $Username = $User.Samaccountname
    $UserIdentity = Get-ADUser -Identity $Username -Server bamtech.dss.media -Properties * -ErrorAction SilentlyContinue | select SamAccountName, Displayname, Givenname, Surname, Enabled, EmployeeNumber, EmailAddress, passwordlastset, Department, EmployeeID, Manager, EmployeeType, SID, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}}
    #Need to figure out how to get messages to not display.
	If ($UserIdentity) {
        Write-Host "$Username exists in bamtech.dss.media, proceeding with script." -ForegroundColor Green
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
		$ChromeDriver.Navigate().GoToURL("https://forms.office.com/Pages/ResponsePage.aspx?id=qDzwZQptPkmeSshayVJqA8qFpKA1mrZIm943kmVJw65UNUdBSk5PNTg2OVdKWlBQOFY4NFpGNTIxNC4u")
		#may need to replace webdriver.dll
		Start-sleep -seconds 3			
		Invoke-AutomateXPath | Wait-Process
		Start-Sleep -seconds 10
		$UserIdentity = $null
		Close-Selenium

		}
	Elseif (!$UserIdentity){
		$UserIdentity = Get-ADUser -Identity $Username -Server ext.dss.media -Properties * -ErrorAction SilentlyContinue |  select SamAccountName, Displayname, Givenname, Surname, Enabled, EmployeeNumber, EmailAddress, passwordlastset, Department, EmployeeID, Manager, EmployeeType, SID, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}}
		If ($UserIdentity) {
			Write-Host "$Username exists in ext.dss.media, proceeding with script."
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
			$ChromeDriver.Navigate().GoToURL("https://forms.office.com/Pages/ResponsePage.aspx?id=qDzwZQptPkmeSshayVJqA8qFpKA1mrZIm943kmVJw65UNUdBSk5PNTg2OVdKWlBQOFY4NFpGNTIxNC4u")
			#may need to replace webdriver.dll
			Start-sleep -seconds 3			
			Invoke-AutomateXPath | Wait-Process
			Start-Sleep -seconds 10
			$UserIdentity = $null
			Close-Selenium
            }
		Else {
			Write-Host "Could not locate user"
			}
        }
    }

