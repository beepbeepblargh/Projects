Import-Module ActiveDirectory
$User = Read-Host -Prompt "What is the username?"

Get-ADUser -Identity $User -Properties * | Select Name,DisplayName,DistinguishedName,Description,SamAccountName,Enabled,UserPrincipalName,Mail,LastLogon,PasswordExpired,PasswordLastSet,ObjectGUID,info,MsExchHideFromAddressLists,whenCreated,whenChanged,Manager
# Will edit this so you can filter for a user instead. Too strict to rely on knowing the SamAccountName