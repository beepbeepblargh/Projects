#requires -version 2
<#
Registry-Setup.ps1
.SYNOPSIS
  Sets all config for a new build
.DESCRIPTION
  Sets the following:
  Chrome Homepage
  Allows Printer installs
  Disable FastBoot

.INPUTS
 $regpath - The full registry path
 $regname - The name of the key
 $regvalue - The value of the key
 $regtype - either STRING or DWORD
.OUTPUTS
  Log file stored in C:\Windows\Temp\build-device.log>
  
.EXAMPLE
  addregkey($path, "Test", "1", "DWORD")
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"


#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$sScriptVersion = "1.0"

#Log File Info
$sLogPath = "C:\Windows\Temp\build-device.log"

#----------------------------------------------------------[Configurables]----------------------------------------------------------
################################################## SET THESE FOR EACH CLIENT ###############################################


##No special characters
<# $clientname = "<CLIENTREPLACENAME>"

$o365tenant = "<CLIENTTENANT>"

$homepage = "<CLIENTHOMEPAGE>"

##Include File Extension:
$backgroundname = "<BACKGROUNDFILENAME>"

#Azure Blob SAS for background image
$backgroundpath = "<BACKGROUNDBLOBURL>"
#>

#-----------------------------------------------------------[Functions]------------------------------------------------------------

start-transcript -path $LogPath

Function addregkey($regpath, $regname, $regvalue, $regtype){
   
  Begin{
    write-host "Adding keys"
  }
  
  Process{
    Try{
        IF(!(Test-Path $regpath))
        {
        New-Item -Path $regpath -Force | Out-Null
        New-ItemProperty -Path $regpath -Name $regname -Value $regvalue `
        -PropertyType $regtype -Force | Out-Null}
        ELSE {
        New-ItemProperty -Path $regpath -Name $regname -Value $regvalue `
        -PropertyType $regtype -Force | Out-Null}
    }
    
    Catch{
      write-host $_.Exception
      Break
    }
  }
  
  End{
    If($?){
      write-host "Completed Successfully."
    }
  }
}



#-----------------------------------------------------------[Execution]------------------------------------------------------------

## Allow Printer Installs
<#
write-host "Configuring Printers"
$registryPath = "HKLM:\Software\Policies\Microsoft\Windows\DriverInstall\Restrictions"
$Name = "AllowUserDeviceClasses"
$value = "1"
$Type = "DWORD"
addregkey($registryPath, $Name, $value, $Type)

$registryPath = "HKLM:\Software\Policies\Microsoft\Windows\DriverInstall\Restrictions\AllowUserDeviceClasses"
$Name = "{4658ee7e-f050-11d1-b6bd-00c04fa372a7}"
$value = ""
$Type = "String"
addregkey($registryPath, $Name, $value, $Type)

$registryPath = "HKLM:\Software\Policies\Microsoft\Windows\DriverInstall\Restrictions\AllowUserDeviceClasses"
$Name = "{4d36e979-e325-11ce-bfc1-08002be10318}"
$value = ""
$Type = "String"
addregkey($registryPath, $Name, $value, $Type)
#>
#-----------------------------------------------------------------------------------------------------------------------------------


## Disable FastBoot
write-host "Disable FastBoot"
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
$Name = "HiberbootEnabled"
$value = "0"
$Type = "DWORD"
addregkey($registryPath, $Name, $value, $Type)

#-----------------------------------------------------------------------------------------------------------------------------------
<#
##Remove Unwanted Settings
write-host "Removing Settings"
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$Name = "SettingsPageVisibility"
$value = "hide:gaming-broadcasting;gaming-gamebar;gaming-gamedvr;gaming-gamemode;quietmomentsgame;gaming-xboxnetworking;cortana-notifications;cortana;cortana-moredetails;cortana-permissions;cortana-windowssearch;cortana-language;cortana-talktocortana"
$Type = "String"
addregkey($registryPath, $Name, $value, $Type)
#>

#-----------------------------------------------------------------------------------------------------------------------------------
## Modify Windows Hello Registry Settings (Enable)
Write-Host "Modifying Registry to remove forced Windows Hello prompts upon sign in"
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PassportForWork"
$Name = "Enabled"
$value = "1"
$Type = "DWORD"
$Check = Test-Path $registryPath
if ($check -eq $False) {

}
addregkey($registryPath, $Name, $value, $Type)

#-----------------------------------------------------------------------------------------------------------------------------------
## Modify Windows Hello Registry Settings (Optional)
Write-Host "Modifying Registry to remove forced Windows Hello prompts upon sign in"
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PassportForWork"
$Name = "DisablePostLogonProvisioning"
$value = "1"
$Type = "DWORD"
addregkey($registryPath, $Name, $value, $Type)

## Stop Logging
stop-transcript