Connect-AzureAD
$user = Get-AzureADUser -ObjectId "ericr@ms.brandwatch.com"

$email = $user.Mail
$upn = $user.UserPrincipalName
$proxyAddresses = $user.ProxyAddresses

Write-Host "Email Address: $email"
Write-Host "UPN: $upn"
Write-Host "Proxy Addresses:"
foreach ($proxyAddress in $proxyAddresses) {
    Write-Host "- $proxyAddress"
}
