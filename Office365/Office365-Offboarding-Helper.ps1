#1.0.1 Resolved a logic issue for comparing mailbox item size and quota not properly comparing. - Chris Ng
#1.0 Changed SamAccountNameMode to a switch. Made InputFileName mandatory. Added logic to quit if there are no valid users in MSOL
#0.9 Added Logic to Skip AD Managed DLs
#0.8 Added logic to check if AD Account exists
#0.75 Removed Import CSV logic and now use importing SAMAccountNames from text file
#0.7 Added Logic to assignment of E1 licenses and if E1 licenses are 0 add E3 instead - Chris Ng
#0.6 Added logic to check if self is manager, Added logic for removing ownership from groups and DLs, added Unattended Mode


<#
.SYNOPSIS
Office365 Offboarding Helper
.DESCRIPTION
Using a text file with users' SAMAccountNames on each line, this script will add an Office365 E1 license, wait for the mailbox to be created, find the manager, set the default OOO message, set the mailbox to shared, backup all distribution lists and Office365 groups, remove all lists and groups, and remove all Office365 licenses.
.PARAMETER InputFileName
The name of the text file that you are importing the users from.
.PARAMETER SAMAccountNameMode
Supply an email address to run this on just a single email address.
.EXAMPLE
.\Office365-Offboarding-Helper.ps1
Launches the script and then asks you for a csv file.
.EXAMPLE
.\Office365-Offboarding-Helper.ps1 -InputFileName test.txt
Launches the script and runs on every user in the text file
.EXAMPLE
.\Office365-Offboarding-Helper.ps1 -SAM bill.smith
Launches the script and runs on just the single user account with no CSV file.
#>

param (
[Parameter(
    Mandatory=$true,
    HelpMessage="Enter the name of the text File (in the current working directory) unless you are using the -SAMAccountNameMode switch; if so, Enter User`'s SAMAccountName"
        )]
[string]$InputFileName,

[alias('SAM')]
[switch]$SAMAccountNameMode,
[switch]$UnattendedMode

)


[string]$DefaultEmailForDistributionLists="hit.automation@hulu.com"
[string]$PresidentofCompany = "kelly.campbell"










function Connect-ToMSOL{
#Connect to MSOL licensing service
    import-module msonline
    connect-msolservice

}




function Get-ManagerNameandEmail {
    Param(
    [string]$UserName
    )
    $OOO_Output = New-Object -TypeName PSObject


#ManagerisEnabled is true if this is being called from the main script or later in this function we look up the manager and it's not disabled
#If the function has already ran and found the manager to be disabled, then ManagerCheck will be the manager, and we will be getting that info instead
    If ($ManagerisEnabled -eq $True){$ManagerCheck = $UserName}

    $ManagerInfo = Get-ADUser (Get-ADUser $ManagerCheck -Properties Manager | Select Manager -ExpandProperty Manager) -Properties Name, Mail, Enabled | Select-Object SAMAccountName, Name, Mail, Enabled




#Convert to Variables that will display correctly
    $ManagerSAMAccountName = $ManagerInfo.SamAccountName
    $ManagerEmail = $ManagerInfo.Mail
    $ManagerName = $ManagerInfo.Name
    $ManagerisEnabled = $ManagerInfo.Enabled


#If Manager is Self, President or Empty
    If ($ManagerSAMAccountName -eq $ManagerCheck -or $ManagerSAMAccountName -eq $PresidentofCompany -or $ManagerSAMAccountName -eq $Null -or $ManagerSAMAccountName -eq "") {
        $OOOMessageText = "Hello, The Hulugan you're attempting to contact is no longer with Hulu. Thank you."
        $ManagertoUseForDLs=$DefaultEmailForDistributionLists

    If ($ManagerSAMAccountName -eq $ManagerCheck){
        Write-Information "$ManagerCheck has self as manager.`nGenerating generic OOO message instead of including manager info." -InformationAction Continue}
    If ($ManagerSAMAccountName -eq $Null -or $ManagerSAMAccountName -eq ""){
        Write-Information "Manager not found. Generating generic OOO message instead of including manager info." -InformationAction Continue}
    If ($ManagerSAMAccountName -eq $PresidentofCompany){
        Write-Information "Manager is $PresidentofCompany. Generating generic OOO message instead of including manager info." -InformationAction Continue}

    $d = [ordered]@{Manager=$ManagertoUseForDLs;OOO_Message=$OOOMessageText}
    $OOO_Output | Add-Member -NotePropertyMembers $d -TypeName OOO

    Return $OOO_Output
}






#Go up one level if manager is disabled
If ($ManagerisEnabled -eq $False){
    $ManagerCheck = Get-ADUser $ManagerSAMAccountName -properties manager | Select-Object Manager -ExpandProperty Manager
    Write-Information "$ManagerSAMAccountName is disabled. Going up one level and re-running the Manager Check." -InformationAction Continue
    Get-ManagerNameandEmail
    }

#Set Standard Message if Manager is enabled
ElseIf ($ManagerisEnabled -eq $True){
    Write-Information "Manager is $ManagerSAMAccountName." -InformationAction Continue
    $OOOMessageText = "Hello, The Hulugan you're attempting to contact is no longer with Hulu. If you require additional help, feel free to contact $ManagerName at $ManagerEmail. Thank you."
    $ManagertoUseForDLs=$ManagerEmail

    $d = [ordered]@{Manager=$ManagertoUseForDLs;OOO_Message=$OOOMessageText}
    $OOO_Output | Add-Member -NotePropertyMembers $d -TypeName OOO

    Return $OOO_Output

}







}


function Set-MailboxAutoReply {
    Set-MailboxAutoReplyConfiguration -Identity $UserEmail -AutoReplyState Enabled -ExternalAudience All -ExternalMessage $OOOMessageText -InternalMessage $OOOMessageText
    Write-Information "Message has been updated to`n$OOOMessageText" -InformationAction Continue

}



function Get-MailboxAutoReply{
    Write-Host "Current Mailbox AutoReply Settings:"
    $MBAutoreplysettings = (Get-MailboxAutoReplyConfiguration -Identity $UserEmail | Select AutoReplyState, InternalMessage, ExternalMessage | format-list | out-string)
    Write-Host $MBAutoreplysettings


}
function Set-MailboxtoShared {
    Set-Mailbox -Identity $UserEmail -Type Shared -verbose
    Write-Host "" ; "Mailbox has been set to Shared." ; ""
    get-mailbox $UserEmail | select UserPrincipalName, RecipientTypeDetails
}










function Remove-AllLicenses {

    $ALL_LICENSES = "hulu:ENTERPRISEPACK","hulu:STANDARDPACK","hulu:VISIOCLIENT","hulu:STREAM","hulu:FLOW_PER_USER","hulu:SPZA_IW","hulu:FLOW_FREE","hulu:EXCHANGESTANDARD","hulu:POWER_BI_STANDARD","hulu:EMS","hulu:PROJECTPROFESSIONAL","hulu:INFORMATION_PROTECTION_COMPLIANCE"
    ForEach ($License in $ALL_LICENSES){Set-MsolUserLicense -UserPrincipalName $UserEmail -RemoveLicenses $License 2>$null}

}




Function Start-CountDown {  
    Param(
        [Int32]$Seconds = 240,
        [string]$Message = "Pausing for 4 minutes..."
    )
    ForEach ($Count in (1..$Seconds))
    {   Write-Progress -Id 1 -Activity $Message -Status "Waiting for $Seconds seconds, $($Seconds - $Count) left" -PercentComplete (($Count / $Seconds) * 100)
        Start-Sleep -Seconds 1
    }
    Write-Progress -Id 1 -Activity $Message -Status "Completed" -PercentComplete 100 -Completed
}



function Get-MailboxCheck {
    param (
        [Parameter(
    Mandatory=$true,
    HelpMessage="Enter the name of the text File (in the current working directory) unless you are using the -SAMAccountNameMode switch; if so, Enter User`'s SAMAccountName"
        )]
[string]$UserIdentity


)
    $MailboxCheck=(Get-Mailbox -Identity $UserIdentity -ErrorAction SilentlyContinue)
    If ($MailboxCheck -eq $null){
        Return $False}
    Else {Return $True}
}



function Check-MailboxFiveTimes {
           param (
        [Parameter(
    Mandatory=$true,
    HelpMessage="Enter the name of the text File (in the current working directory) unless you are using the -SAMAccountNameMode switch; if so, Enter User`'s SAMAccountName"
        )]
[string]$UserIdentity


)
    For ($TimesWeCheckedTheMailBox=1; $TimesWeCheckedTheMailBox -lt 6; $TimesWeCheckedTheMailBox++){
  
        If ((Get-MailboxCheck -UserIdentity $UserIdentity) -eq $true){
            Write-Information "Mailbox for $UserIdentity found" -InformationAction Continue 
            Return $True}
        Else {
            Write-Information "Mailbox for $UserIdentity not found. Waiting for 4 minutes.`nWe've checked the mailbox $TimesWeCheckedTheMailBox out of 5 times." -InformationAction Continue
            Start-CountDown
            }
        
    }
    Write-Information "$UserIdentity mailbox still not created so skipping..." -InformationAction Continue
    Return $False
}

function Check-IfMSOLUserExists {
    param (

    [Parameter(Mandatory=$true)]
    [string]$UserEmail
    )

    Write-Information "Checking if $UserEmail exists in Office365"

    $IsLicensed = (get-msoluser -userprincipalname $UserEmail -ErrorAction SilentlyContinue).isLicensed
    If ($IsLicensed -eq $null) {Return $False}
    Else {Return $True}
}

function Check-IfADAccountExists{
    param(
        [Parameter(
    Mandatory=$true,
    ValueFromPipelineByPropertyName=$true,
    ValueFromPipeline=$True
        )]
        [string]$SamAccountName
        )
    $ADUserCheck=(Get-ADUser $SamAccountName -ErrorAction SilentlyContinue)
    If ($ADUserCheck -eq $null){
        Return $False}
    Else {
        Return $True}
    }


function Get-DistributionListsUserIsaMemberOf {
    param (
        [Parameter(Mandatory=$true)]
        [string]$UserEmail
           )
    $UserDN = (Get-User $UserEmail | select -ExpandProperty DistinguishedName)
    $UserDLsandO365Groups = (Get-Recipient -Filter "Members -eq '$UserDN'" -RecipientTypeDetails GroupMailbox,MailUniversalDistributionGroup | 
    Select-Object Name, Alias, RecipientTypeDetails, ManagedBy, PrimarySMTPAddress |
    Sort-Object -Property RecipientTypeDetails, Name, ManagedBy)
    
    $UserDLExportFileName = "Office365Lists" + "-" + $UserEmail + "-" + $Date + ".csv"
    $UserDLsandO365Groups | Export-CSV -Path $UserDLExportFileName -NoTypeInformation
    Write-Information "Exported Office365 Distribution Lists and Groups to:`n$pwd\$UserDLExportFileName" -InformationAction Continue
    Return $UserDLsandO365Groups
}


function Get-Office365GroupMembers {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Alias
           )
$Members=(Get-UnifiedGroupLinks $Alias -LinkType Members | select Name)
Return $Members
}



function Check-IfDistributionListIsDirSynced {

param(
[Parameter(
    Mandatory=$true
        )]
    [string]$PrimarySMTPAddress
    )


If ((Get-DistributionGroup $PrimarySMTPAddress | Select -ExpandProperty IsDirSynced) -eq $True){

    Return $True
    }
Else {Return $False}




}
function Remove-AllDistributionLists {
         param (
        [Parameter(Mandatory=$true)]
        [string]$UserEmail,
        [Parameter(Mandatory=$true)]
        [string]$UserIdentity,
        [Parameter(Mandatory=$true)]
        [string]$ManagerIdentity,
        [Parameter(Mandatory=$true)]
        [string]$ManagertoUseForDLs
           )

    $UserDistributionLists | ForEach-Object -Process{
        $Alias=$_.Alias
        $PrimarySMTPAddress=$_.PrimarySMTPAddress
        

        If ($SkippedDLs -notcontains $PrimarySMTPAddress){
 
            If (($_.ManagedBy | Measure-Object).Count -gt 1 -and $_.ManagedBy -eq $UserIdentity){
                Write-Information "$UserIdentity is an owner of $Alias and must be removed prior to removal from Distribution List" -InformationAction Continue
                Set-DistributionGroup -verbose -Identity $PrimarySMTPAddress -ManagedBy @{Remove=$UserEmail}
                Start-CountDown -Seconds 30 -Message "Waiting 30 Seconds after Changing Distribution List Ownership"
                }
            If (($_.ManagedBy | Measure-Object).Count -le 1 -and $_.ManagedBy -eq $UserIdentity){
                Write-Information "$UserIdentity is sole owner of $Alias and must be replaced prior to removal from Distribution List" -InformationAction Continue
                Set-DistributionGroup -verbose -Identity $PrimarySMTPAddress -ManagedBy @{Add=$ManagertoUseForDLs}
                Start-CountDown -Seconds 30 -Message "Waiting 30 Seconds after Changing Distribution List Ownership"
                Set-DistributionGroup -verbose -Identity $PrimarySMTPAddress -ManagedBy @{Remove=$UserEmail}
                Start-CountDown -Seconds 30 -Message "Waiting 30 Seconds after Changing Distribution List Ownership"
                }
            Remove-DistributionGroupMember -Identity $PrimarySMTPAddress -Member $UserEmail -Confirm:$false -verbose
                }    
        Else {Write-Information "$PrimarySMTPAddress is Directory Managed and was Not Removed." -InformationAction SilentlyContinue}
            
}
}





function Remove-AllOffice365Groups{
        param (
        [Parameter(Mandatory=$true)]
        [string]$UserEmail,
        [Parameter(Mandatory=$true)]
        [string]$UserIdentity,
        [Parameter(Mandatory=$true)]
        [string]$ManagerIdentity,
        [Parameter(Mandatory=$true)]
        [string]$ManagertoUseForDLs
           )


        $UserO365Groups | ForEach-Object -Process{
            $Alias=$_.Alias
            $PrimarySMTPAddress=$_.PrimarySMTPAddress
            If (($_.ManagedBy | Measure-Object).Count -gt 1 -and $_.ManagedBy -eq $UserIdentity){
                Write-Information "$UserIdentity is an owner of $Alias and must be removed prior to removal from Group" -InformationAction Continue
                Remove-UnifiedGroupLinks -Confirm:$false -Verbose -Identity $PrimarySMTPAddress -LinkType Owner -Links $UserEmail
                Start-CountDown -Seconds 30 -Message "Waiting 30 Seconds after Changing Group Ownership"}
            If (($_.ManagedBy | Measure-Object).Count -le 1 -and $_.ManagedBy -eq $UserIdentity){
                Write-Information "$UserIdentity is sole owner of $Alias and must be replaced prior to removal from Group" -InformationAction Continue

                                                #Check if the ManagertoUseForDLs is a member
                $GroupMembers=(Get-Office365GroupMembers -Alias $Alias)

                If ($GroupMembers -contains $ManagerIdentity) {
                    Write-Information "$Alias contains $ManagerIdentity so we can make them group owner" -InformationAction Continue
                    $NewOwner=$ManagerIdentity
                    }
                Else {
                    Write-Information "$Alias does not contain $ManagerIdentity so we need to promote someone else in the list to Group owner" -InformationAction Continue
                    $GroupMembers = ($GroupMembers | Where-Object "Name" -ne $UserIdentity)
                    $NewOwner= $GroupMembers[0] | Select-Object -ExpandProperty Name
                    Write-Information "Using $NewOwner as New Owner" -InformationAction Continue
                    }


                Add-UnifiedGroupLinks -Confirm:$false -Verbose -Identity $PrimarySMTPAddress -LinkType Owner -Links $NewOwner
                Start-CountDown -Seconds 30 -Message "Waiting 30 Seconds after Changing Group Ownership"
                Remove-UnifiedGroupLinks -Confirm:$false -Verbose -Identity $PrimarySMTPAddress -LinkType Owner -Links $UserEmail
                Start-CountDown -Seconds 30 -Message "Waiting 30 Seconds after Changing Group Ownership"
                } 
            Remove-UnifiedGroupLinks -Confirm:$false -Verbose -Identity $PrimarySMTPAddress -LinkType Member -Links $UserEmail
            }
            }














function Check-IFActiveDirectoryisConnected {

    If ((test-computersecurechannel) -eq $False){
        Write-Host "Active Directory Not Connected. Quitting." -BackgroundColor Black -ForegroundColor Red
        Exit}
    Else {Write-Host "Connected to Active Directory."}
}

    function Get-Office365Identity {
         param (
                [Parameter(Mandatory=$true)]
                [string]$UserEmail)
         $UserIdentity=(Get-Mailbox -Identity $UserEmail | Select-Object -ExpandProperty Identity)
         Return $UserIdentity} 
##################################################################################################################

#Begin Script Main Body

##################################################################################################################

Check-IFActiveDirectoryisConnected

#Clear Variables
Write-Host "UnattendedMode is $UnattendedMode"
Write-Host "SamAccountNameMode is $SamAccountNameMode"

$Date = Get-Date -Format "MM-dd-yyyy"
$AllADInformationAllUsers = @()
[boolean]$AtLeastOneUserExistsWithoutaLicense=$False
#Begin Main Menu
Write-Host "Offboard Users from text file"

#Check if MSOL is connected
Write-Host "Checking if MSOL is loaded"
#If there is an error we load MSOnline
Get-MsolAccountSku -ErrorVariable Errorlog *>$null
If ($Errorlog -ne $null){
Connect-ToMSOL
}

#Check if exists in AD and add to one of two Arrays (text file mode)
$SkippedADUsers=@()
$VerifiedADUsers=@()
If (!$SAMAccountNameMode){
    Get-Content $InputFileName | ForEach-Object -Process {
        $SamAccountName = $_.Trim()
        #Avoid errors from blank lines in text file
         If ($SamAccountName -ne ""){
       
     
            If ((Check-IfADAccountExists $SamAccountName -ErrorAction SilentlyContinue) -eq $false){
                Write-Host "$SamAccountName doesn't exist in Active Directory." -BackgroundColor Black -ForegroundColor Red
                $SkippedADUSers+=$SamAccountName}
            Else {
                Write-Host "Found $SamAccountName in Active Directory. Moving Forward..."
                $VerifiedADUsers+=$SamAccountName}
         }   
    If ($VerifiedADUSers.count -eq 0){
        Write-Host "No Valid Users found in Active Directory. Quitting." -BackgroundColor Black -ForegroundColor Red
        Exit}
     }  

Write-Host "`n`nAll Skipped Users:`n"
$SkippedADUSers
Write-Host "`n`nGoing Forward with These Users:`n"
$VerifiedADUsers
}


#Run AD Check for samaccountnamemode
If ($SAMAccountNameMode) {
    If ((Check-IfADAccountExists $InputFileName -ErrorAction SilentlyContinue) -eq $false){
            Write-Host "$InputFileName doesn't exist in Active Directory. Quitting." -BackgroundColor Black -ForegroundColor Red
            Exit}
    #GrabADInfo from SamAccountName for Single User
    $AllADInformationAllUsers = (Get-ADUser $InputFileName -Properties SAMAccountName, Enabled, CanonicalName, Mail, AccountExpirationDate, msExchHideFromAddressLists, Manager | select SAMAccountName, Enabled, CanonicalName, Mail, AccountExpirationDate, msExchHideFromAddressLists, Manager)

}
#Loop to grab all AD Information from Text File



If (!$SAMAccountNameMode){
    $VerifiedADUsers | ForEach-Object -Process{
    $SAMAN = $_
    $UserInfo = (Get-ADUser $SamAN -Properties SAMAccountName, Enabled, CanonicalName, Mail, AccountExpirationDate, msExchHideFromAddressLists, Manager | select SAMAccountName, Enabled, CanonicalName, Mail, AccountExpirationDate, msExchHideFromAddressLists, Manager)


    $AllADInformationAllUsers += $UserInfo
        }
    }

Write-Host "`n`nDisplaying All User Info From Active Directory`n---------------------" ; $AllADInformationAllUsers | Format-List
$UserEmail = $_.mail



#If user doesn't exist in MSOL remove from $AllADInformationAllUsers
$AllSkippedUsers=@()
$AllADInformationAllUsers | ForEach-Object -Process {
    $SamAccountName = $_.SAMAccountName
    If ((Check-IfMSOLUserExists $_.Mail) -eq $False){
    
    Write-Host "No Office365 Account Found For $SamAccountName" -BackgroundColor Black -ForegroundColor Red
    $AllSkippedUsers+=$SamAccountName
    }
    Else {Write-Host "Office365 Account Found For $SamAccountName"}
}

Write-Host "`n`nSkipping These Users:`n"
$SkippedADUsers
$AllSkippedUsers




$AllSkippedUsers | ForEach-Object -Process{
    $SAMAccountName = $_
    $AllADInformationAllUsers = ($AllADInformationAllUsers | Where-Object "SamAccountName" -ne $SAMAccountName)
}
[int]$NumberofVerifiedUsers=($AllADInformationAllUsers.SamAccountName.Count)
Write-Host "`n`nGoing Forward with These $NumberofVerifiedUsers Users:`n"
$AllADInformationAllUsers.SamAccountName

If ($NumberofVerifiedUsers -lt 1){
    Write-Host "No valid users. Quitting." -BackgroundColor Black -ForegroundColor Red
    Exit}


#Remove All Licenses from All Users
Write-Host "`n`nRemove all licenses from All Users?"
If ($UnattendedMode -eq $False){$CONTINUE = Read-Host "Press C to Continue. Any other Key Skips"}
If ($CONTINUE -eq "C" -or $UnattendedMode -eq $True)
    {
    $AllADInformationAllUsers | ForEach-Object -Process{
    Write-Host "" ; "Removing Office365 Licenses from:"
    $_.SAMAccountName | format-list
    $UserEmail = $_.mail
    Remove-AllLicenses
    }
}

#Get Licenses from all Users


$AllADInformationAllUsers | ForEach-Object -Process{
    Write-Host "" ; "Displaying Office365 License Information for`n"
    $_.SAMAccountName | format-list
    (Get-MsolUser -UserPrincipalName $_.mail).licenses.accountskuid

    }














#Adds Licenses to All Users
Write-Host "`n`nAdd license to All Users?`n"
If ($UnattendedMode -eq $False){$CONTINUE = Read-Host "Press C to Continue. Any other Key Skips"}
If ($CONTINUE -eq "C" -or $UnattendedMode -eq $True){
    $AllADInformationAllUsers | ForEach-Object -Process{
        Write-Host "`n`nAdding license to:`n"
        $_.SAMAccountName | format-list
        Set-MsolUser -UserPrincipalName $_.mail -UsageLocation US
        $E1StandardLicense = Get-MsolAccountSku | Where-Object {$_.skuPartNumber -eq "STANDARDPACK"} 
        $E1StandardLicenseTotal = $E1StandardLicense.ActiveUnits - $E1StandardLicense.ConsumedUnits
        $E3EnterpriseLicense = Get-MsolAccountSku | Where-Object {$_.skuPartNumber -eq "ENTERPRISEPACK"} 
        $E3EnterpriseLicenseTotal = $E3EnterpriseLicense.ActiveUnits - $E3EnterpriseLicense.ConsumedUnits
		$MailboxTotalItemSizeObject = Get-MailboxStatistics -Identity $_.mail | Select -ExpandProperty TotalItemSize | Select -ExpandProperty Value
		$MailboxTotalItemSizeValue = $MailboxTotalItemSizeObject.tostring().trimend(" bytes)").split("(")
		$MailboxTotalItemSize = [long]$MailboxTotalItemSizeValue[1]
		$MailboxSizeObject = Get-Mailbox -Identity $_.mail | Select -ExpandProperty ProhibitSendQuota
		$MailboxSizeValue = $MailboxSizeObject.tostring().trimend(" bytes)").split("(")
		$MailboxSize = [long]$MailboxSizeValue[1]
	# The above lines convert the mailbox value objects into a string, trims off parts, and then reconverts to a Long integer to compare with -lt/-gt.

		
	# If (Get-MailboxCheck -UserIdentity $_.Mail -eq $True) {}
        If (($MailboxTotalItemSize -lt $MailboxSize) -and ($E1StandardLicenseTotal -gt 0)) {
	# Compares File Size total within Mailbox with the Mailbox quota and if it is less than the quota, and if the licenses exist, go 
	try {
		Write-Host "Attempting to add E1 License"
		Set-MsolUserLicense -UserPrincipalName $_.mail -AddLicenses hulu:StandardPACK
	}
	catch {
		Write-Error -Message $_.Exception.Message
		echo $_.Exception | format-list -force >> $Errorlog
	}
}
        ElseIf (($E3EnterpriseLicenseTotal -gt 0) -or ($error)) {
	try {
		Write-Host "Could not add E1 License. Attempting to add E3 License"
		Set-MsolUserLicense -UserPrincipalName $_.mail -AddLicenses hulu:EnterprisePACK
}
	catch {
		Write-Error -Message $_.Exception.Message
		echo $_.Exception | format-list -force >> $Errorlog

Else {
	Write-Host "Could not add any licenses. Closing script and writing error log."
	Exit
}
}
}
    }
}

#Check each mailbox up to 5 times to make sure it's been created...
$AllADInformationAllUsers | ForEach-Object -Process {

    If ((Check-MailboxFiveTimes -UserIdentity $_.Mail) -eq $false){
#...and remove from ADInformationAllUsers if it's still not available
        $AllADInformationAllUsers = ($AllADInformationAllUsers | Where-Object "SamAccountName" -ne $_.SAMAccountName)}
}


##################################################################################
#
#       Main Program Loop Starts Here
#
####################################################################################



$AllADInformationAllUsers | ForEach-Object -Process{

    $UserName = $_.SAMACCOUNTNAME ; $UserName = $UserName.Trim()
    $UserEmail = $_.Mail ; $UserEmail = $UserEmail.Trim()

    Get-MailboxAutoReply

    [boolean]$ManagerisEnabled = $True
    $ManagerInfo = (Get-ManagerNameandEmail $UserName)
    $ManagertoUseForDLs = $ManagerInfo.Manager
    $OOOMessageText = $ManagerInfo.OOO_Message

    Write-Host "`nReady to Set OOO Message`nMessage Will Read: " ; $OOOMessageText

    If ($UnattendedMode -eq $False){$CONTINUE = Read-Host "Press C to Continue. Any other Key Skips"}
    If ($CONTINUE -eq "C" -or $UnattendedMode -eq $True){Set-MailboxAutoReply}

    Get-Mailbox $UserEmail | select UserPrincipalName, RecipientTypeDetails
    Write-Host "Set Mailbox to Shared?" 

    If ($UnattendedMode -eq $False){$CONTINUE = Read-Host "Press C to Continue. Any other Key Skips"}
    If ($CONTINUE -eq "C" -or $UnattendedMode -eq $True){Set-MailboxtoShared}

    $UserIdentity =(Get-Office365Identity -UserEmail $UserEmail)





    $UserDLsandO365Groups = (Get-DistributionListsUserIsaMemberOf -UserEmail $UserEmail) 
    Write-Information "Displaying Office365 Groups and Distribution Lists" -InformationAction Continue
    $UserDLsandO365Groups | Format-Table -AutoSize
    $UserO365Groups = ($UserDLsandO365Groups | Where-Object { $_.RecipientTypeDetails -eq "GroupMailbox"})
    $UserDistributionLists = ($UserDLsandO365Groups | Where-Object { $_.RecipientTypeDetails -eq "MailUniversalDistributionGroup"})

    $SkippedDLs=@()

    $UserDistributionLists | forEach {

    If ((Check-IfDistributionListIsDirSynced -PrimarySMTPAddress $_.PrimarySMTPAddress) -eq $true){
        $SkippedDLs+=$_.PrimarySMTPAddress
        }}
    Write-Information "`n`nThe Following DLs are Directory Synced and Will Not be Removed:`n" -InformationAction Continue
    $SkippedDLs
   
    Write-Host "Remove All Office365 Groups and Distribution Lists?"
    If ($UnattendedMode -eq $False){$CONTINUE = Read-Host "Press C to Continue. Any other Key Skips"}
    If ($CONTINUE -eq "C" -or $UnattendedMode -eq $True){
        $ManagerIdentity=(Get-Office365Identity -UserEmail $ManagertoUseForDLs) 
        Remove-AllOffice365Groups -UserEmail $UserEmail -ManagertoUseForDLs $ManagertoUseForDLs -UserIdentity $UserIdentity -ManagerIdentity $ManagerIdentity
        
        Remove-AllDistributionLists -UserEmail $UserEmail -ManagertoUseForDLs $ManagertoUseForDLs -UserIdentity $UserIdentity -ManagerIdentity $ManagerIdentity
        
        
        } 


    Write-Host "Ready to Remove All Office365 licenses?"
    If ($UnattendedMode -eq $False){$CONTINUE = Read-Host "Press C to Continue. Any other Key Skips"}
    If ($CONTINUE -eq "C" -or $UnattendedMode -eq $True){Remove-AllLicenses}

    Write-Host "`n`n`n--------------------"

    }
