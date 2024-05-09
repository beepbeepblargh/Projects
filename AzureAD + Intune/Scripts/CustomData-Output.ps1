Update-MSGraphEnvironment -SchemaVersion 'beta'
Connect-MSGraph

$result = Invoke-MSGraphRequest -HttpMethod GET -Url 'deviceManagement/deviceManagementScripts/b113448a-528a-4beb-b7d5-381a117d5184/deviceRunStates?$expand=managedDevice' | Get-MSGraphAllPages
$success = $result| Where-Object -Property errorCode -EQ 0
$resultMessage = $success.resultMessage 
$objResultMessage = $resultMessage | ConvertFrom-Json
$objResultMessage | Out-GridView 