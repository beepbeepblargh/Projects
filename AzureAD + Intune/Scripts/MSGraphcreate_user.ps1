# Connecting to Azure Parameters
$tenantID = ""
$applicationID = ""
$clientKey =  "" #Secret Key
 
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
$baseUrl = 'https://graph.microsoft.com/v1.0/' 
 
# Pack the token into a header for future API calls
$header = @{
          'Authorization' = "$($Token.token_type) $($Token.access_token)"
         'Content-type'  = "application/json"
}
$string = "Testpassword134"

# Define the UPN for the user we want to get userPurpose for
$userid = "testaccount@brandwatch.com"
<#$body = @"
{
	"AccountEnabled": "true",
	"DisplayName": "TestAccountGraph",
	"UserPrincipalName": $userid,
	"Department": "Engineering",
	"PasswordProfile" : {
		"forceChangePasswordNextSignIn": "true",
		"forceChangePasswordNextSignInWithMfa": false,
		"password": string
		}
	}@"
#>

$body = @{
	AccountEnabled = $true
	DisplayName = "TestAccountGraph"
	UserPrincipalName = $userid
	Department = "Engineering"
	PasswordProfile = {
		forceChangePasswordNextSignIn = $true
		forceChangePasswordNextSignInWithMfa = $false
		password = $string
		}
	}
# The above is problematic because Powershell does not like how we tried to turn this into a json (@") but invoke-restmethod needs
# a json to throw back as a post/body. May need to pipe the above into ConvertToJson
#also, may need a line to authenticate to graph api first. Then run the subsequent line with just -Body
$createUser = Invoke-RestMethod -Method POST -headers $header -Body ($body | ConvertTo-Json) -Uri $url -ContentType "application/json"
start-sleep -seconds 15
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