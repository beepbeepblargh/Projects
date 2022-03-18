Function Get-ChromeVersion {
	If ($IsWindows -or $Env:OS) {
		Try {
			(Get-Item (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe').'(Default)').VersionInfo.FileVersion
			}
		Catch{
			throw "'Google Chrome Not Found in Registry";
			}
	}
}

$ChromeVersion = Get-ChromeVersion -ErrorAction Stop;
Write-Output "Google Chrome version $ChromeVersion found on machine";

$ChromeVersion = $ChromeVersion.Substring(0, $ChromeVersion.LastIndexOf("."));
#   and append the result to URL "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_". 
#   For example, with Chrome version 72.0.3626.81, you'd get a URL "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_72.0.3626".
$ChromeDriverVersion = (Invoke-WebRequest "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_$ChromeVersion").Content;
Write-Output "Latest matching version of Chrome Driver is $ChromeDriverVersion";

$TempFilePath = [System.IO.Path]::GetTempFileName();
# replacing the above just in case with the line below.
#$TempFilePath = "c:\Selenium\chromedriver.exe";
$TempZipFilePath = $TempFilePath.Replace(".tmp", ".zip");
Rename-Item -Path $TempFilePath -NewName $TempZipFilePath;
$TempFileUnzipPath = $TempFilePath.Replace(".tmp", "");

If ($IsWindows -or $Env:OS) {
    Invoke-WebRequest "https://chromedriver.storage.googleapis.com/$ChromeDriverVersion/chromedriver_win32.zip" -OutFile $TempZipFilePath;
    Expand-Archive $TempZipFilePath -DestinationPath $TempFileUnzipPath;
    Move-Item "$TempFileUnzipPath/chromedriver.exe" -Destination "C:\selenium\chromedriver.exe" -Force;
}
ElseIf ($IsMacOS) {
    Invoke-WebRequest "https://chromedriver.storage.googleapis.com/$ChromeDriverVersion/chromedriver_mac64.zip" -OutFile $TempZipFilePath;
    Expand-Archive $TempZipFilePath -DestinationPath $TempFileUnzipPath;
    Move-Item "$TempFileUnzipPath/chromedriver" -Destination "path/to/save/chromedriver" -Force;
}
Else {
    Throw "Your operating system is not supported by this script.";
}

Get-ChromeVersion

<#
# Clean up temp files
Remove-Item $TempZipFilePath;
Remove-Item $TempFileUnzipPath -Recurse;
#>