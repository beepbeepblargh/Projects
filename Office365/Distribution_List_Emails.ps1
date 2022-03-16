# Extract Distribution List Members Script v.0.1
# Written by Chris Ng
<#
Intended to pull the members of a distribution list from Office 365 Exchange Admin using Powershell Exchange Online. Be sure to Connect-EXOPsession
before running this script.
#>
$AliasName = Read-Host -Prompt "What's the Alias name?"
# Calls the Distribution name. Has to be exact. To automate this for Task Scheduler,replace the above with Get-DistributionGroup | Select Name
$Alias = Get-DistributionGroup -Identity "$AliasName" | Select-Object -ExpandProperty PrimarySMTPAddress
# Filters out the Alias's email address.
$logdate = Get-Date -Format "MM-dd-yyyy_hh-mm-ss"
$logname = ".\" + "DistributionGroup_" + "$AliasName" + "_" + "$logdate" + ".csv"
# Creates a variable to store the name of the .csv/log
# Get-DistributionGroupMember -Identity $Alias | select DisplayName,Title,PrimarySMTPAddress
# Shows you what users/email addresses are associated with this.

<# Foreach ($DL in $AliasName){
	Get-DistributionGroupMember -Identity $Alias | select DisplayName,Title,PrimarySMTPAddress | Export-CSV -NoTypeInformation -Path .\$logname 
	Write-Host "A CSV of the following team members associated with $AliasName has been exported."
	# Issue with this script is that there are apparently thousands of DL's that currently exist so backing them all up may not be the wisest choice.
	# Trying to see if I can just pull the DL's that were created within Office 365 and not synced over by AD
	# Also, you get this error when running the Foreach for this script. 
	Export-CSV : The specified path, file name, or both are too long. The fully qualified file name must be less than 260
characters, and the directory name must be less than 248 characters.
At C:\Users\c-christopher.ng\documents\github\Powershell\Automation-Projects\Distribution_List_Emails.ps1:15 char:95
+ ... e,PrimarySMTPAddress | Export-CSV -NoTypeInformation -Path .\$logname
+                            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OpenError: (:) [Export-Csv], PathTooLongException
    + FullyQualifiedErrorId : FileOpenFailure,Microsoft.PowerShell.Commands.ExportCsvCommand
}	
	#>
Get-DistributionGroupMember -Identity $Alias | select DisplayName,Title,PrimarySMTPAddress | Export-CSV -NoTypeInformation -Path .\$logname 
# Exports the above list to a CSV. In the future, made want to also grab their samaccountname info to export with the csv.
Write-Host "A CSV of the following team members associated with $AliasName has been exported."