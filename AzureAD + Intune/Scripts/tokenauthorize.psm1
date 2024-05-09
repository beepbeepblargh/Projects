function Get-AuthToken {

    <#
    .SYNOPSIS
    This function is used to authenticate with the Graph API REST interface
    .DESCRIPTION
    The function authenticate with the Graph API Interface with the tenant name
    .EXAMPLE
    Get-AuthToken
    Authenticates you with the Graph API interface
    .NOTES
    NAME: Get-AuthToken
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,
    
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,
    
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ClientSecret
    )
        try {
            $connectionDetails = @{
                'TenantId'     = $TenantId
                'ClientId'     = $ClientId
                'ClientSecret' = $ClientSecret | ConvertTo-SecureString -AsPlainText -Force
            }
            $authTokenInfo = Get-MsalToken @connectionDetails
            $tokenContent = $authTokenInfo.AccessToken 
            $authToken = @{
                'Authorization'= "Bearer $tokenContent"
            }
            return $authToken
    
        }
        catch {
    
        write-host $_.Exception.Message -f Red
        write-host $_.Exception.ItemName -f Red
        write-host
        break
        }
    }    