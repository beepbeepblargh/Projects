# Install AzureAD module if not already installed
$azureadmodule = Get-InstalledModule -Name AzureAD
if ($azureadmodule -eq $false) {
	Write-Host "Installing AzureAD Module"
	Install-Module -Name AzureAD
}
elseif ($azureadmodule -eq $true) {
	Write-Host "Azure AD Module already exists on this device. Proceeding..."
}
# Connect to Azure AD (log in using your Azure AD account)
Connect-AzureAD

# Replace the following variables with your desired values
$oldDomain = "brandwatch.com"
$newDomain = "ms.brandwatch.com"

# Retrieve all users from the current domain
$users = Get-AzureADUser -All $true
#$users =  Get-AzureADUser -All $true | Where-Object {$_.DisplayName -like "*Test Chris*"} 

foreach ($user in $users) {
    $currentUPN = $user.UserPrincipalName
    $newUPN = $currentUPN -replace $oldDomain, $newDomain

    # Only update the user if the UPN is different
    if ($currentUPN -like "*ms.brandwatch.com*") {
		Write-Host "Skipping $($user.UserPrincipalName). User is already on @ms.brandwatch.com."
    }
	else {
		Write-Host "Changing UPN for $($user.UserPrincipalName) from $currentUPN to $newUPN"
        Revoke-AzureADUserAllRefreshToken -ObjectId $user.ObjectId
		Set-AzureADUser -ObjectId $user.ObjectId -UserPrincipalName $newUPN

	}
}

Write-Host "UPN change completed."
