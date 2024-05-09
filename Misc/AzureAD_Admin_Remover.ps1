<#
.SYNOPSIS
This script is intended to remove all accounts that are not supposed to have admin access from the admin 
#>

Get-LocalGroupMember -Group 'Administrators' | Where {$_.Name -like 'AzureAD\*'} | Remove-LocalGroupMember Administrators