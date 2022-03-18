<#Account_checker_v0.1.ps1
Written by Chris Ng.
Verifies Account status
#>
$multiprompt = Read-Host -Prompt "Is this for multiple users? (Y/N)"
If ($multiprompt -eq "Y") {
	$PromptCSV = Read-Host -Prompt "What's the path of the csv file?"
	$HuluUser = Import-CSV -path $PromptCSV 
	Foreach ($User in $HuluUser) {
		
		$UserProperties = Get-ADUser $User -properties * | select SamAccountName, Displayname, Mail, Enabled, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}}
		#$UserPasswordLastSet = $userproperties.passwordlastset.tostring()
		#$UserWhenCreated = $userproperties.whenCreated.tostring()
		$UserAccountname = $UserProperties.Displayname
		$UserAccount = $UserProperties.SamAccountName
		$UserEnabled = $userProperties.Enabled
		#$ExistingGroups = Get-ADPrincipalGroupMembership $User.SamAccountName | Select-Object Name
		
	<#
		If ($User.status -eq "Exists") {
			Write-Host "$User exists"
		}
		Else {
			Write-Host "$User does not exist by this username. Please review"
		}
		#>
		If($UserEnabled  -eq $True){
			Write-Host "$UserAccount is Enabled" -ForegroundColor Green
			}
		Else{
			Write-Host "$UserAccount is Disabled." -ForeGroundColor Red #>
			}
	}
}
Elseif ($multiprompt -eq "N"){
	$HuluUser = Read-Host -Prompt "What is the username(samAccountName)?"
	#Verify that the user exists. And check if their passwordlastset is the same as whenCreated. 
	$UserProperties = Get-ADUser $HuluUser -properties * | select SamAccountName, Displayname, Givenname, Surname, Enabled, EmployeeNumber, EmailAddress, Department, StreetAddress, Title, Country, Office, employeeType, SID, passwordlastset, whenCreated, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}}
	#$UserPasswordLastSet = $userproperties.passwordlastset.tostring()
	#$UserWhenCreated = $userproperties.whenCreated.tostring()
	#$group = Read-Host -Prompt "What's the group you need to check for the user?"
	$ExistingGroups = Get-ADPrincipalGroupMembership $HuluUser | Select-Object Name
	$UserEnabled = $userProperties.Enabled
	<#
	If ($HuluUser.status -eq "Exists") {
		Write-Host "$HuluUser exists"
		}
	Else {
		Write-Host "$HuluUser does not exist by this username. Please review"
		}
		#>
	If ($UserEnabled -eq $True) {
		Write-Host "$HuluUser is Enabled" -ForegroundColor Green
        }
	Else {
		Write-Host "$HuluUser is Disabled." -ForeGroundColor Red
		}
}