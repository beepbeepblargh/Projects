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
$baseUrl = 'https://graph.microsoft.com/v1.0' 
 
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
$userPurpose = Invoke-RestMethod -Method Delete -Uri $url -headers $header
#Write-Host $userPurpose

<#  
# Call the REST-API
$userPurpose = Invoke-RestMethod -Method GET -headers $header -Uri $url
 
# For getting the attribute to userpurpose from mailbox settings
# write-host $userPurpose.value
#>

<#
--------------------------------------------------------
$ApplicationID   = "ID-Of-The-Application"
$TenantID        = "ID-Of-The-Tenant"
$AccessSecret    = "Secret"

#Create an hash table with the required value to connect to Microsoft graph
$Body = @{    
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $ApplicationID
    client_secret = $AccessSecret
} 

#Connect to Microsoft Graph REST web service
$ConnectGraph = Invoke-RestMethod -Uri https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token -Method POST -Body $Body

#Endpoint Analytics Graph API
$GraphUrl = "https://graph.microsoft.com/v1.0/devices/Device-Id-Of-The-Device"

# define request body as PS Object
$requestBody = @{
    extensionAttributes = @{
		"extensionAttribute1" = "Test"
	}
}

# Convert to PS Object to JSON object
$requestJSONBody = ConvertTo-Json $requestBody

#define header, use the token from the above rest call to AAD.
# in post method define the body is of type JSON using content-type property.
$headers = @{
    'Authorization' = $(“{0} {1}” -f $ConnectGraph.token_type,$ConnectGraph.access_token)
    'Accept' = 'application/json'
    'Content-Type' = "application/json"
}

#This API call update the device extension attribute
$webResponse = Invoke-RestMethod -Uri $GraphUrl -Method 'PATCH' -Headers $headers -Body $requestJSONBody -verbose

#>