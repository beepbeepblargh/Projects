$tenantID = ""
$applicationID = ""
$clientKey = ""
#$Uri = "https://login.microsoft.com/$tenantId/oauth2/token"
$url = "https://login.microsoftonline.com/$tenantId/oauth2/token"
$resource = "https://graph.microsoft.com/"
$restbody = @{
         grant_type    = 'client_credentials'
         client_id     = $applicationID
         client_secret = $clientKey
         resource      = $resource
}
Write-Host "Authenticating to MS Graph now..."
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

# Get the primary user of the device
$primaryUser = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName

# Extract the username from the full user name
$targetUser = $primaryUser -replace ".*\\"

# Check if the user is a member of the Administrators group
$isAdmin = [bool](net localgroup administrators | Select-String -Pattern $targetUser)

#Retrieve Device ID from Locale Machine registry
#$DeviceID = Get-ItemPropertyValue HKLM:\SOFTWARE\Microsoft\Provisioning\Diagnostics\Autopilot\EstablishedCorrelations -Name EntDMID -ErrorAction SilentlyContinue
#$DeviceID = "db6ae0c8-8fad-43a8-8a45-f29af03f7f7f" #needs to be the Azure Object ID, not the Intune Device ID -_-. 
#$DeviceID = "240464bd-ed00-4058-9c2b-c81e8864dc02"
Start-Sleep -seconds 2
$uri = $baseUrl + '/devices' + "(deviceId='{240464bd-ed00-4058-9c2b-c81e8864dc02}'"

if ($isAdmin -eq $true) {
    # User is in the Administrators group, perform specific actions
    Write-Host "$targetUser is a member of the Administrators group. Adding to Device ExtensionAttribute1 in AAD"
	try {
		#Remove-LocalGroupMember -Group "Administrators" -Member $primaryUser
		#Start-Sleep -seconds 2
		$groupassignment = "AdminUser"
		#Add in line to update device's Extension attributes in Azure AD to show Primary User, Last Logged in User, and whether they have standard or administrators
		$attributes = @{
		  "extensionAttribute1" = "$groupassignment"
		  "extensionAttribute2" = "$targetUser"
		  } | ConvertTo-Json
		Invoke-RestMethod -Uri $uri -Body $attributes -Method PATCH -ContentType "application/json" -headers $header
		Write-Host "Extension Attributes Added"
	}
	catch {
		Write-Error $_
		Exit 1
	}
} 
else {
    # User is not in the Administrators group
    Write-Host "$targetUser is not a member of the Administrators group."
	try {
		#Remove-LocalGroupMember -Group "Administrators" -Member $primaryUser
		#Start-Sleep -seconds 2
		$groupassignment = "StandardUser"
		#Add in line to update device's Extension attributes in Azure AD to show Primary User, Last Logged in User, and whether they have standard or administrators
		$attributes = @{
		  "extensionAttributes" = @{
		  "extensionAttribute1" = "$groupassignment"
		  "extensionAttribute2" = "$currentuser"
		  }
		  } | ConvertTo-Json
		Invoke-RestMethod -Uri $uri -Body $attributes -Method PATCH -ContentType "application/json" -headers $header
	}
	catch {
		Write-Error $_
		Exit 1
	}
}