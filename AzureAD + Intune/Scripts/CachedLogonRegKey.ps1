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
#--------------------------------------------------------------------------------------------
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$Name = "CachedLogonsCount"
$value = "0"
$Type = "REG_SZ"
addregkey($registryPath, $Name, $value, $Type)
#--------------------------------------------------------------------------------------------

