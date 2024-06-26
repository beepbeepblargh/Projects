﻿#Written by Chris Ng
param([switch]$Elevated)

function Test-Admin {
  $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
  $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) 
    {
        # tried to elevate, did not work, aborting
    } 
    else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
}

exit
}

New-LocalUser -Name "User" -Password ( ConvertTo-SecureString -AsPlainText -Force 'TestPassword') -PasswordNeverExpires -fullname User -Description User -AccountNeverExpires -UserMayNotChangePassword | Add-LocalGroupMember -Group administrators
Write-Progress -Activity "Percent Bar" -Status "Completed" -PercentComplete 75
