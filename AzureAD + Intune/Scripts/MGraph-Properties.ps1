# Replace these values with your actual values
$clientId = ""
$clientSecret = ""
$tenantId = ""
$userIdOrPrincipalName = "" # Replace with the user's UPN or object ID

# Construct the token endpoint URL
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"

# Construct the Graph API request URL
$graphApiUrl = "https://graph.microsoft.com/v1.0/users/$userIdOrPrincipalName"

# Construct the token request body
$tokenRequestBody = @{
    client_id     = $clientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

# Get the access token
$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -ContentType "application/x-www-form-urlencoded" -Body $tokenRequestBody
$accessToken = $tokenResponse.access_token

# Construct the headers for the API request
$headers = @{
    Authorization = "Bearer $accessToken"
}

# Make the Graph API request to get user information
$userResponse = Invoke-RestMethod -Uri $graphApiUrl -Headers $headers -Method Get

# Extract required user information
$email = $userResponse.mail
$upn = $userResponse.userPrincipalName
$proxyAddresses = $userResponse.proxyAddresses

Write-Host "Email Address: $email"
Write-Host "UPN: $upn"
Write-Host "Proxy Addresses:"
foreach ($proxyAddress in $proxyAddresses) {
    Write-Host "- $proxyAddress"
}
