#Written by Chris Ng
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

$PSScriptRoot = 'C:\Users\helpdesk\Desktop\SurfaceGO'
$msiList = @(
Get-ChildItem -Path $PSScriptRoot -Recurse -Include *.msi
)
foreach ($m in $msiList) {    
$logPath = Join-Path -Path $PSScriptRoot -ChildPath ((Split-Path -Path $m -Leaf).Replace(".msi", ".log"))
$installArg = "/I `"$m`" /L*v `"$logPath`" /qn /norestart"
try {
   Start-Process -FilePath msiexec.exe -ArgumentList $installArg -Wait -NoNewWindow -PassThru -ErrorAction Stop
}
catch {
    Write-Error -ErrorRecord $_
}    
}