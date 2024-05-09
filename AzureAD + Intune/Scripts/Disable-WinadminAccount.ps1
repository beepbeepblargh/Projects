$user = "winadmin"
try
{
    $Result = (Get-LocalUser -Name $user -ErrorAction Stop).Enabled
    try
    {
        if ($Result)
        {
            Get-LocalUser -Name $user | Disable-LocalUser
			net user "Administrator" "DontfeartheReaper%6" /active:yes
            Start-Sleep -Seconds 2

        }
    }
    catch
    {
        $_.Exception.Message #in case disable fails
    }
}
catch
{
    $_.Exception.Message #if user doesnt exist
}