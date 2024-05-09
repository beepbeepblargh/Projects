#If .status = terminated, Write-Host "User.business email is terminated. Skipping"
# if .status = active, Verify business email exists. If exists, add department and job description to user.
# if account errors/not found, redirect/output it to a .txt file.
# Install the Microsoft Graph PowerShell module if you haven't already
# Define the path to the CSV file
#$csvPath = ".\input.csv"
Start-Transcript
$todaydate = Get-Date -f yyyy-MM-dd_HH-mm-ss
$csvPath = Read-Host -Prompt "What's the path of the current CSV?"
# Read the CSV file
$csvData = Import-Csv -Path $csvPath
Connect-MgGraph -Scopes "User.Read.All","Group.ReadWrite.All"
# Iterate through each row in the CSV file
foreach ($row in $csvData) {
    $userPrincipalName = $row.UserPrincipalName
    $department = $row.District
    $jobTitle = $row.JobTitle
    $status = $row.Status
    # Find the user in Azure AD
    $user = Get-MgUser -Filter "userPrincipalName eq '$userPrincipalName'"
	
    if ($row.status -eq "Terminated") {
		Write-Host "$userPrincipalName is no longer active." #>> logfile_$todaydate.txt
	}
	else {
		if ($user) {
				# Update the department and job title attributes
				try {
					$user.Department = $department
					$user.JobTitle = $jobTitle
					Update-MgUser -UserId $user.Id -department $Department -JobTitle $user.JobTitle
					
					Write-Host "Updated user: $userPrincipalName"
				}
				catch {
					$errormessage = "Error updating user: $UserPrincipalName - #_"
					$errors += $errormessage
					Write-Host $errormessage
					Update-MgUser -UserId $user.Id -department $Department

				}
			} else {
				Write-Host "User not found: $userPrincipalName"
			}
	}
}

# Disconnect from Microsoft Graph
Disconnect-MgGraph
Stop-Transcript