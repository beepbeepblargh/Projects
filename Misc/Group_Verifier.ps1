<#Group_Verifier v.0.2
Written by Chris Ng.
Verifies if a user is already in a group and if not, prompts you to add them
#>
$multiprompt = Read-Host -Prompt "Is this for multiple users? (Y/N)"
If ($multiprompt -eq "Y") {
	$PromptCSV = Read-Host -Prompt "What's the path of the csv file?"
	$HuluUser = Import-CSV -path $PromptCSV
	$Group = Read-Host -Prompt "What's the group you need added?"
    $GroupAdd = Read-Host -Prompt "Do you want to add the users to the group? (Y/N)"
    If($GroupAdd -eq "Y"){
        $admin = Get-Credential
        }
    Else {
        Write-Host "Skipping user add to groups."
    }
	Foreach ($User in $HuluUser) {
		
		$UserProperties = Get-ADUser $User.SamAccountName -properties * | select SamAccountName, Displayname, Givenname, Surname, Enabled, EmployeeNumber, EmailAddress, passwordlastset, whenCreated, Department, StreetAddress, Title, Country, Office, employeeType, SID, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}}
		#$UserPasswordLastSet = $userproperties.passwordlastset.tostring()
		#$UserWhenCreated = $userproperties.whenCreated.tostring()
		$UserAccountname = $UserProperties.Displayname
		$UserAccount = $UserProperties.SamAccountName
		$ExistingGroups = Get-ADPrincipalGroupMembership $User.SamAccountName | Select-Object Name
	<#
		If ($User.status -eq "Exists") {
			Write-Host "$User exists"
		}
		Else {
			Write-Host "$User does not exist by this username. Please review"
		}
		#>
		If($ExistingGroups.Name -eq $Group){
			Write-Host "$UserAccount is part of $Group already. Skipping to next user." -ForegroundColor Green
			}
		Else{
			Write-Host "$UserAccount is not part of $Group. Proceeding with script. Please add the user after this script is done." -ForegroundColor Yellow
            If($GroupAdd -eq "Y"){
                Add-ADGroupMember -Identity $Group -Members $UserAccount -Credential $admin
                }
            Else {
                Write-Host "Skipping adding user to group."
            }
                
            # Add-ADGroupMember -Identity github_logins -Members $user.SamAccountName
			# Commented above out as this needs to be run from X-Account to be able to add to groups from Powershell.
			}
	}
}
Elseif ($multiprompt -eq "N"){
	$HuluUser = Read-Host -Prompt "What is the username(samAccountName)?"
	#Verify that the user exists. And check if their passwordlastset is the same as whenCreated. 
	$UserProperties = Get-ADUser $HuluUser -properties * | select SamAccountName, Displayname, Givenname, Surname, Enabled, EmployeeNumber, EmailAddress, Department, StreetAddress, Title, Country, Office, employeeType, SID, passwordlastset, whenCreated, objectGUID, @{Name="ManagerEmail";Expression={(get-aduser -property emailaddress $_.manager).emailaddress}}
	#$UserPasswordLastSet = $userproperties.passwordlastset.tostring()
	#$UserWhenCreated = $userproperties.whenCreated.tostring()
    $UserAccount = $UserProperties.SamAccountName
    $EnabledAccount = $UserProperties.Enabled
    $ObjectGUID = $UserProperties.objectGUID
	$group = Read-Host -Prompt "What's the group you need to check for the user?"
	$ExistingGroups = Get-ADPrincipalGroupMembership $HuluUser | Select-Object Name
	<#
	If ($HuluUser.status -eq "Exists") {
		Write-Host "$HuluUser exists"
		}
	Else {
		Write-Host "$HuluUser does not exist by this username. Please review"
		}
		#>
	If ($ExistingGroups.Name -eq $Group) {
		Write-Host "$HuluUser already exists in $Group. Exiting Script." -ForeGroundColor Green
        Exit
        }
	Else {
		Write-Host "$HuluUser is not part of $Group" -ForegroundColor Yellow
		$GroupAdd = Read-Host -Prompt "Would you like to add the user to the group? (Y/N)"
            If ($GroupAdd -eq "Y") {
                try { 
                    $Admin = Get-Credential
                    Add-ADGroupMember -Identity $Group -Members $UserAccount -Credential $admin
                    $ExistingGroups = Get-ADPrincipalGroupMembership $UserAccount | Select-Object Name
					Write-Host "$Useraccount has been added to $Group." -ForeGroundColor Green
                        If ($Group -eq "Okta-Operativeone") {
                            Write-Host "GUID : $ObjectGUID"
                            }
                    }

                catch {
                    Write-Host "Encountered Error. Please review logs for error." -ForegroundColor Red
                    #Logging To Be Added.
                }
            }
            Else {
                Write-Host "Closing script." -ForegroundColor Red
                Exit
            }
        }
}