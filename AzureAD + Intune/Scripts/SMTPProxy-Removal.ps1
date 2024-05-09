<#
#>
$csvpath = Read-Host -Prompt "What's the path of the csv?"
$csvfile = Import-Csv -Path $csvpath

foreach {
	Restore-Msoluser -UserPrincipalName "$username@ms.brandwatch.com" -AutoReconcileProxyConflicts
}