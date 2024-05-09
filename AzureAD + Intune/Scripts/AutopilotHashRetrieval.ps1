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
$reponame = "AutopilotHwKeys"
$ownername = ""
$token = ""
$date =get-date -format yyMMddHHmmss
$date = $date.ToString()
$readabledate = get-date -format dd-MM-yyyy-HH-mm-ss
$backupreason = Write-Host "Uploading $targetUser Autopilot Hash"
$uri = "https://api.github.com/repos/$ownername/$reponame/contents/$Newpath"
#$message = "$backupreason - $readabledate"
#$body = '{{"message": "{0}", "content": "{1}" }}' -f $message, $profilesencoded

$localpath = "C:\HWID"
$ABPath = $localpath + "\" + $Newpath
<#
function upload-file-to-github-repo($localPath, $localFilename, $repoPath, $repoFilename, $repoName, $ownern, $message, $token) {
   #
   #   Note:
   #     $repoPath must (currently) not start with a slash. 
   #

   #
   #      File content must be represented in base 64
   #

   $localFileAbsolutePath = resolve-path "C:\HWID\$Newpath"

   if (! (test-path $localFileAbsolutePath)) {
      "$localFileAbsolutePath does not exist"
       return
   }

   $base64 = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($localFileAbsolutePath))

   $url = "https://api.github.com/repos/$ownername/$reponame/contents/$localFileAbsolutePath"

   try {

    #
    #     TODO: PowerShell 7 introduces option -skipHTTPErrorCheck
    #           This option should probably be used in order to have
    #           see what HTTP status code was returned.
    #

    # github API token is required for private repositories

      $response = invoke-restMethod                      `
         $url                                            `
        -headers @{Authorization = "bearer $token"}

   }
   catch [System.Net.WebException] {
     #
     #  I am too lazy to evaluate the details and just assume
     #  that this is a 404. So the resource needs to be created
     #
        write-verbose 'Resource probably does not exist. Trying to create it'

        $body = '{{"message": "{0}", "content": "{1}" }}' -f $message, $base64

     #
     #  TODO: of course, if the url $url does not exist on the webserver,
     #  the following invocation fails.
     #
        $response = invoke-webrequest $url                                               `
          -method          PUT                                                           `
          -contentType     application/json                                              `
          -headers       @{Authorization = "bearer $token"}                              `
          -body            $body

      #
      # expected: 201 Created
      #
        write-verbose "$($response.StatusCode) $($response.StatusDescription)"
        return
   }
   write-verbose "file seems to exit, updating it"
   $sha = $response.sha
   write-verbose "SHA = $sha"

   $body = '{{"message": "{0}", "content": "{1}", "sha": "{2}" }}' -f $message, $base64, $sha

   $response = invoke-webrequest $url                                               `
     -method          PUT                                                           `
     -contentType     application/json                                              `
     -headers       @{Authorization = "bearer $token"}                              `
     -body            $body
}
upload-file-to-github-repo
#>

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

# Replace these variables with your own values
$FileToUpload = $ABPath
$GitHubRepoOwner = "BrandwatchLTD"
$GitHubRepoName = "AutopilotHwKeys"
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
