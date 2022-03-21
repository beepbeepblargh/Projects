Import-Module ActiveDirectory
$Usernames = Import-CSV -path C:\Users\c-christopher.ng\Documents\names.csv

Foreach ($user in $usernames) {
Get-ADUser -Identity $User -Properties * | Select Name,DisplayName,DistinguishedName,Description,SamAccountName,Enabled,UserPrincipalName,Mail,LastLogon,PasswordExpired,PasswordLastSet,ObjectGUID,info,MsExchHideFromAddressLists,whenCreated,whenChanged,Manager |Export-CSV -path C:\users\c-christopher.ng\documents\test-revised.csv
}
# Will edit this so you can filter for a user instead. Too strict to rely on knowing the SamAccountName