# Connecting to Azure Parameters
$tenantID = ""
$applicationID = ""
$clientKey =  "" 
#SecretID= ""
 
# Authenticate to Microsoft Grpah
 Write-Host "Authenticating to Microsoft Graph via REST method"
 
$url = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$resource = "https://graph.microsoft.com/"
$restbody = @{
         grant_type    = 'client_credentials'
         client_id     = $applicationID
         client_secret = $clientKey
         resource      = $resource
}
     
 # Get the return Auth Token
$token = Invoke-RestMethod -Method POST -Uri $url -Body $restbody
     
# Set the baseurl to MS Graph-API (BETA API)
#$baseUrl = 'https://graph.microsoft.com/beta'
$baseUrl = 'https://graph.microsoft.com/v1.0' 
#Write-Host $token
#Write-Host $token.token_type
#Write-Host $token.access_token
# Pack the token into a header for future API calls
$header = @{
          'Authorization' = "$($Token.token_type) $($Token.access_token)"
         'Content-type'  = "application/json"
}
 
# Define the UPN for the user we want to get userPurpose for
$userid = Read-Host -prompt "What is the user's UPN?"
 
# Build the Base URL for the API call
#$url = $baseUrl + '/users/' + $userid + '/mailboxsettings/userpurpose'
$url = $baseUrl + '/users/' + $userid
$userPurpose = Invoke-RestMethod -Method GET -headers $header -Uri $url
Write-Host $userPurpose

<#  
# Call the REST-API
$userPurpose = Invoke-RestMethod -Method GET -headers $header -Uri $url
 
# For getting the attribute to userpurpose from mailbox settings
# write-host $userPurpose.value
#>