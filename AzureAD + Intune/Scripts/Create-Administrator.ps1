$userName = "winadmin"
$userexist = (Get-LocalUser).Name -Contains $userName
$userisadmin = [bool](net localgroup administrators | Select-String -Pattern $userName)
if($userexist -eq $false) {
  try{ 
     New-LocalUser -Name $username -Description "Winadmin BreakGlass Account" -NoPassword
     Add-LocalGroupMember -Group "Administrators" -Member "winadmin"
     Start-Sleep -Seconds 2
     Reset-LapsPassword
     Exit 0
   }   
  Catch {
     Write-error $_
     Exit 1
   }
}
elseif($userexist -eq $true) {
    try {
        if ($userisadmin) {
            Write-Host "Breakglass Account is already an admin. Attempting to reset password."
            Reset-LapsPassword
            Exit 0
            }
        else {
            Add-LocalGroupMember -Group "Administrators" -Member "winadmin"
            Start-Sleep -Seconds 2
            Reset-LapsPassword
        Exit 0
        }
    }
    catch {
        Write-Error $_
        Exit 1
    }
}
else {
    Write-Host "Error occurred, exiting..."
    Write-Error $_
    Exit 1
}
