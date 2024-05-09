<#
MSOffice_Sign_In_EventLog.ps1
#>
Param
(
    [int]$InactiveDays,
    [switch]$CreateSession,
    [string]$TenantId,
    [string]$ClientId,
    [string]$CertificateThumbprint
)
Import-Module Microsoft.Graph.Beta.Reports

Function Connect_MgGraph {
 #Check for module installation
 $Module=Get-Module -Name microsoft.graph.beta -ListAvailable
 if($Module.count -eq 0) { 
  Write-Host Microsoft Graph PowerShell SDK is not available  -ForegroundColor yellow  
  $Confirm= Read-Host Are you sure you want to install module? [Y] Yes [N] No 
  if($Confirm -match "[yY]") { 
   Write-host "Installing Microsoft Graph PowerShell module..."
   Install-Module Microsoft.Graph.beta -Repository PSGallery -Scope CurrentUser -AllowClobber -Force
  }
  else {
   Write-Host "Microsoft Graph Beta PowerShell module is required to run this script. Please install module using Install-Module Microsoft.Graph cmdlet." 
   Exit
  }
 }
 #Disconnect Existing MgGraph session
 if($CreateSession.IsPresent) {
  Disconnect-MgGraph
 }


 Write-Host Connecting to Microsoft Graph...
 if(($TenantId -ne "") -and ($ClientId -ne "") -and ($CertificateThumbprint -ne "")) {  
  Connect-MgGraph -TenantId $TenantId -AppId $ClientId -CertificateThumbprint $CertificateThumbprint

 }
 else {
  Connect-MgGraph -Scopes "User.Read.All","AuditLog.read.All"
 }
}

Write-Host "Connecting to Graph Beta"
Connect_MgGraph
$path = Read-Host "What's the Path of the CSV file?"
$upns = Import-CSV -Path "$path"

$ExportCSV = ".\MSOfficeSignInEvents_$((Get-Date -format yyyy-MMM-dd-ddd` hh-mm-ss` tt).ToString()).csv"


foreach ($upn in $upns) {
	$user = $upn.upn
	#Get-MgBetaAuditLogSignIn -Filter "contains(appDisplayName,'Microsoft Office')" -Filter "userPrincipalName/any(eq 'chris.ng@ms.brandwatch.com')" -Filter "contains(resourceId,'0f698dd4-f011-4d23-a33e-b36416dcb1e6')" -Top 1
	#Get-MgBetaAuditLogSignIn -Filter "UserPrincipalName eq 'abarros@ms.brandwatch.com' and contains(resourceId,'0f698dd4-f011-4d23-a33e-b36416dcb1e6')" -Sort "createdDateTime DESC" -Top 1 | Select-Object -Property AppDisplayName,ClientAppUsed,CreatedDateTime,ResourceID,UserPrincipalName
	Get-MgBetaAuditLogSignIn -Filter "UserPrincipalName eq '$user' and ResourceDisplayName eq 'OfficeClientService'" -Sort "createdDateTime DESC" -Top 1 | Select-Object -Property AppDisplayName,ClientAppUsed,CreatedDateTime,ResourceDisplayName,ResourceID,UserPrincipalName | Export-Csv -Path $ExportCSV -NoType -Append
	Write-Host "$user has been added to the spreadsheet"
}