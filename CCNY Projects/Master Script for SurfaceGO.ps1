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

'running with full privileges'

Invoke-Expression "C:\Users\Helpdesk\Desktop\SurfaceGO\Scripts\Multiple Local Account Creation - Surface Pro.ps1"
Invoke-Expression "C:\Users\Helpdesk\Desktop\SurfaceGO\Scripts\MSI PowerShell Install Script-Test3 For ALL MSI in Directory.ps1"
Start-Process "cmd.exe" "/c" "C:\Users\Helpdesk\Desktop\SurfaceGO\Scripts\Multiple EXE - test2.bat"