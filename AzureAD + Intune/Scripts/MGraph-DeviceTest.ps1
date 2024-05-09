# Replace these values with your actual values
$clientId = ""
$clientSecret = ""
$tenantId = ""
$userIdOrPrincipalName = "" # Replace with the user's UPN or object ID

# Construct the token endpoint URL
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/token"

# Construct the Graph API request URL
$graphApiUrl = "https://graph.microsoft.com/v1.0/devices/$userIdOrPrincipalName"
$resource = "https://graph.microsoft.com/"

# Construct the token request body
$restbody = @{
         grant_type    = 'client_credentials'
         client_id     = $clientId
         client_secret = $clientSecret
         resource      = $resource
}

# Get the access token
$token = Invoke-RestMethod -Method POST -Uri $tokenurl -Body $restbody

#$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -ContentType "application/x-www-form-urlencoded" -Body $tokenRequestBody
#$Token = $tokenResponse.access_token

# Construct the headers for the API request
<#
$headers = @{
    Authorization = "Bearer $accessToken"
}
#>

$header = @{
          'Authorization' = "$($Token.token_type) $($Token.access_token)"
         'Content-type'  = "application/json"
}

# Make the Graph API request to get device information
$intuneObject = Invoke-RestMethod -Method Get -uri $graphApiUrl -Headers $header


# Extract required device information
$serial = $intuneobject.displayName
$deviceID =  $intuneObject.deviceId
Write-Host "Display Name: $serial"
Write-Host "deviceID: $deviceID"
