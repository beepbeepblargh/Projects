$userName = "winadmin"
$userexist = (Get-LocalUser).Name -Contains $userName
$userisadmin = [bool](net localgroup administrators | Select-String -Pattern $userName)
$password = ConvertTo-SecureString "DontfeartheReaper%6" -AsPlainText -Force
if($userexist -eq $false) {
  try{ 
     New-LocalUser -Name $username -Description "Winadmin BreakGlass Account" -password $password
     Add-LocalGroupMember -Group "Administrators" -Member "winadmin"
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
			Set-LocalUser -Name winadmin -password $password
            Exit 0
            }
        else {
            Add-LocalGroupMember -Group "Administrators" -Member "winadmin"
			Set-LocalUser -Name winadmin -password $password
            Start-Sleep -Seconds 2
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
