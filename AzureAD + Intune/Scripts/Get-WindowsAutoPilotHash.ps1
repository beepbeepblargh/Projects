<# Get-WindowsAutopilotInfo.ps1 v.1.0
Written by Chris Ng
7/2/2023
This script is intended to extract the autopilot hash csv file from an already enrolled device and upload it to Github.
#>
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -Type Directory -Path "C:\HWID"
Set-Location -Path "C:\HWID"
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
Install-Script -Name Get-WindowsAutopilotInfo -Force
$Username = $primaryUser = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty UserName

# Extract the username from the full user name
$targetUser = $primaryUser -replace ".*\\"
$deviceserial = (gwmi win32_bios).SerialNumber
Get-WindowsAutopilotInfo -OutputFile AutopilotHWID.csv
$source = "C:\HWID\AutopilotHWID.csv"
$Newpath = "$targetUser"+"_"+"$deviceserial"+"_"+"AutopilotHWID.csv"
Rename-Item -Path $source -NewName $Newpath

#Github API Info
$reponame = ""
$ownername = ""
$token = ""
$date =get-date -format yyMMddHHmmss
$date = $date.ToString()
$readabledate = get-date -format dd-MM-yyyy-HH-mm-ss
$backupreason = Write-Host "Uploading $targetUser Autopilot Hash"
$uri = "https://api.github.com/repos/$ownername/$reponame/contents/$Newpath"

$localpath = "C:\HWID"
$ABPath = $localpath + "\" + $Newpath

function Upload-FileToGitHub {
    param (
        [string]$FilePath,
        [string]$RepoOwner,
        [string]$RepoName,
        [string]$Token
    )

    $BaseURL = "https://api.github.com"
    $UploadURL = "$BaseURL/repos/$RepoOwner/$RepoName/contents/$Newpath"

    $Content = [System.IO.File]::ReadAllBytes($FilePath)
    $EncodedContent = [Convert]::ToBase64String($Content)

    $Headers = @{
        "Authorization" = "token $Token"
        "Content-Type" = "application/json"
    }

    $Data = @{
        "message" = "Upload $Newpath"
        "content" = $EncodedContent
    } | ConvertTo-Json

    $Response = Invoke-RestMethod -Uri $UploadURL -Headers $Headers -Method Put -Body $Data

    return $Response
}

#Variables
$FileToUpload = $ABPath
$GitHubRepoOwner = ""
$GitHubRepoName = ""
$PersonalAccessToken = ""

if (-not (Test-Path $FileToUpload)) {
    Write-Host "File not found. Please provide a valid file path."
}
else {
    try {
        $Response = Upload-FileToGitHub -FilePath $FileToUpload -RepoOwner $GitHubRepoOwner -RepoName $GitHubRepoName -Token $PersonalAccessToken
        if ($Response -and $Response.content) {
            Write-Host "File uploaded successfully."
        } else {
            Write-Host "Error uploading file. Check your credentials and try again."
        }
    }
    catch {
        Write-Host "An error occurred: $_"
    }
}
