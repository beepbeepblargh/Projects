$UserCSV = Read-Host -Prompt "What's the direct path of the CSV file?" #use full path instead. .\ is relative path and could cause issues if you are not careful
$UserList = gc $UserCSV
$outputFilePath = "C:\Users\c-christopher.ng\Documents\User&Group_Output.csv"

$finalResult = foreach ($u in $UserList)
{
    #CSV takes data in a table format. So best to replicate that with a PS Cusotm object that can easily be represented ina table format.
    #Need to modify script so that it only pulls csv.samaccountname
	$obj = [PSCustomObject]@{
        UserName = $u
        Status = ""
		
	#Import-CSV - Path $Userlist
    }
    try
    {
        $ADUser = Get-ADUser -Identity $u -ErrorAction Stop
        $obj.Status = "Exists"
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        $obj.Status = "Does not Exist"
    }
    catch
    {
        $obj.Status = $_.Exception.Message
    }
    $obj
}

$FinalResult
#$finalResult | Export-Csv -Path $outputFilePath -NoTypeInformation -Force