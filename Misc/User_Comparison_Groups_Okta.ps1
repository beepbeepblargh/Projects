﻿Import-Module Okta -Force
$Username1 = Read-Host -Prompt "What is the username of the first user? (Do not include @brandwatch.com/@cision.com)"
$Username2 = Read-Host -Prompt "What is the username of the second user? (Do not include @brandwatch.com/@cision.com)"
$Identity1 = (oktaGetUserbyID -oOrg Cision -userName $userName1 | Select id).id
$Identity2 = (oktaGetUserbyID -oOrg Cision -userName $userName2 | Select id).id

function Get-OktaGroupComparison{
    <#
    .SYNOPSIS
        This will compare 2 user accounts in Okta and tell you their group membership and how they are similar and different. 
    .PARAMETER Identity1
        The first user account that you would like to compare. 
    .PARAMETER Identity2
        The second user account that you would like to compare. 
    .EXAMPLE
        Get-OktaGroupComparison -Identity1 cng -Identity2 cng2
    .EXAMPLE
        Get-OktaGroupComparison cng cng2
    .NOTES
    #>

    [CmdletBinding()] 
    param (
        [Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$True,ValueFromPipeline=$True,
        HelpMessage="The first user account that you would like to compare")] 
        [string]$Identity1,

        [Parameter(ValueFromPipelineByPropertyName=$true,Mandatory=$False,ValueFromPipeline=$True,
        HelpMessage="The second user account that you would like to compare")] 
        [string]$Identity2
    )

    #$user1 = (Get-ADPrincipalGroupMembership -Identity $Identity1 | select Name | Sort-Object -Property Name).Name
    $user1 = (oktaGetGroupsbyUserId -oOrg Cision -uid $Identity1).profile.name
	Write-Verbose ($user1 -join "; ")
    #$user2 = (Get-ADPrincipalGroupMembership -Identity $Identity2 | select Name | Sort-Object -Property Name).Name
    $user2 = (oktaGetGroupsbyUserId -oOrg Cision -uid $Identity2).profile.name
	Write-Verbose ""
    Write-Verbose ($user2 -join "; ")
    $SameGroups = (Compare-Object $user1 $user2 -PassThru -IncludeEqual -ExcludeDifferent)
    Write-Verbose ""
    Write-Verbose ($SameGroups -join "; ")
    $UniqueID1 = (Compare-Object $user1 $user2 -PassThru | where {$_.SideIndicator -eq "<="})
    Write-Verbose ""
    Write-Verbose ($UniqueID1 -join "; ")
    $UniqueID2 = (Compare-Object $user1 $user2 -PassThru | where {$_.SideIndicator -eq "=>"})
    Write-Verbose ""
    Write-Verbose ($UniqueID2 -join "; ")
    $ID1Name = (Get-ADUser -Identity $Identity1 | Select Name).Name
    Write-Verbose ""
    Write-Verbose ($ID1Name -join "; ")
    $ID2Name = (Get-ADUser -Identity $Identity2 | Select Name).Name
    Write-Verbose ""
    Write-Verbose ($ID2Name -join "; ")

    Write-Host "--------------------------------------------------------------------------"
    Write-Host "[$ID1Name] and [$ID2Name] have the following groups in common:"
    Write-Host "--------------------------------------------------------------------------"
    $SameGroups
    Write-Host ""

    Write-Host "--------------------------------------------------------------------------"
    Write-Host "The following groups are unique to [$ID1Name]:"
    Write-Host "--------------------------------------------------------------------------"
    $UniqueID1
    Write-Host ""
    Write-Host "--------------------------------------------------------------------------"
    Write-Host "The following groups are unique to [$ID2Name]:"
    Write-Host "--------------------------------------------------------------------------"
    $UniqueID2

}
Get-OktaGroupComparison $Identity1 $Identity2
