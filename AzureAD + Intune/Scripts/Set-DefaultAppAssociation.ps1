#########################
#
# Set-DefaultAppAsociation
#
# Version 3.0 By Diagg/OSD-Couture.com 
# XML node creation part by Helmut Wagensonner (https://blogs.msdn.microsoft.com/hewagen/making-file-type-associations-enterprise-ready/)
# Release Date 01/10/2019
# Latest relase: 06/01/2020
#
# Purpose: Create file association on the fly during MDT/SCCM deployment
#
# Usage: Create MDT/SCCM properties (cs.ini) with your prefered default application
#        DefaultBrowzer = IE (IE,Chrome, Firefox, Edge)
#        DefaultPdfReade = Adobe
#        DefaultImageViewer = PhotoViewer
#        DefaultMailClient = Outlook
#        DefaultMusicPlayer = VLC (VLC,WMP)
#        DefaultMoviePlayer = VLC (VLC,WMP)
#        DefaultArchiver = 7zip
#        DefaultTxtViewer = NPPP
#
#
#
## History:
#
# 01/10/2019 - V1.0	- Inital Release
#                   - Support for VLC, IE, Firefox, Chrome, PhotoViewer, Outlook, Adobe Reader, Windows Media Player 
# 14/10/2010 - V2.0 - Added a function to set additional registry keys with file association
# 25/10/2019 - V2.1 - Localized app name is no more retrived from the registry, it is now directly registed from the script
# 09/12/2019 - V2.2 - support for switch SetIEAsDefault
# 06/01/2020 - V3.0 - Added support for Edge-Chromium
#                   - Added support for 7Zip
#                   - Added support for Notepad++
# 05/02/2020 - V3.1 - Fixed a bunch of bugs
#					
#
#########################

#Requires -Version 4
#Requires -RunAsAdministrator 


##== Debug
$ErrorActionPreference = "stop"
#$ErrorActionPreference = "Continue"


##== Global Variables
$Script:CurrentScriptName = $MyInvocation.MyCommand.Name
$Script:CurrentScriptFullName = $MyInvocation.MyCommand.Path
$Script:CurrentScriptPath = split-path $MyInvocation.MyCommand.Path


##== Init.
If (!(test-path "HKCR:")){New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT|Out-Null}


#Get Values From MDT
Try
    {$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment -ErrorAction Stop}
Catch
    {Write-host "Unable to register SMS.TSEnvironment, continue with default values"}

If (![string]::IsNullOrWhiteSpace($TSenv))
	{
		If (![string]::IsNullOrWhiteSpace($TSenv.value("SetIEAsDefault")))
			{If (($TSenv.value("SetIEAsDefault")).ToUpper() -eq "YES"){$DefaultBrowzer = "IE"}}
		ElseIf (![string]::IsNullOrWhiteSpace($TSenv.value("SetChromeAsDefault")))
			{If (($TSenv.value("SetIEAsDefault")).ToUpper() -eq "YES"){$DefaultBrowzer = "Chrome"}}
		ElseIf (![string]::IsNullOrWhiteSpace($TSenv.value("SetEdgeAsDefault")))
			{If (($TSenv.value("SetIEAsDefault")).ToUpper() -eq "YES"){$DefaultBrowzer = "Edge"}}
		ElseIf (![string]::IsNullOrWhiteSpace($TSenv.value("SetFirefoxAsDefault")))
			{If (($TSenv.value("SetIEAsDefault")).ToUpper() -eq "YES"){$DefaultBrowzer = "Firefox"}}
		Else
			{$DefaultBrowzer = $TSenv.Value("DefaultBrowzer")}
	} 
Else {$DefaultBrowzer = "Edge"}

If (![string]::IsNullOrWhiteSpace($TSenv)){$DefaultPdfReader = $TSenv.Value("DefaultPdfReader") } Else {$DefaultPdfReader = "Adobe"}
If (![string]::IsNullOrWhiteSpace($TSenv)){$DefaultImageViewer = $TSenv.Value("DefaultImageViewer") } Else {$DefaultImageViewer = ""}
If (![string]::IsNullOrWhiteSpace($TSenv)){$DefaultMailClient = $TSenv.Value("DefaultMailClient") } Else {$DefaultMailClient = ""}
If (![string]::IsNullOrWhiteSpace($TSenv)){$DefaultMusicPlayer = $TSenv.Value("DefaultMusicPlayer") } Else {$DefaultMusicPlayer = ""}
If (![string]::IsNullOrWhiteSpace($TSenv)){$DefaultMoviePlayer = $TSenv.Value("DefaultMoviePlayer") } Else {$DefaultMoviePlayer = ""}
If (![string]::IsNullOrWhiteSpace($TSenv)){$DefaultArchiver = $TSenv.Value("DefaultArchiver") ; $DefaultArchiver = $DefaultArchiver.replace("-","") } Else {$DefaultArchiver = "7ZIP"}
If (![string]::IsNullOrWhiteSpace($TSenv)){$DefaulTxtViewer = $TSenv.Value("DefaulTxtViewer") } Else {$DefaulTxtViewer = "NPPP"}

# Load XML
$Path = "$($env:SystemRoot)\system32\OEMDefaultAssociations.xml"
$OEMXMLFile = [xml](Get-Content -path $Path )
$rootNode = $OEMXMLFile.SelectSingleNode("DefaultAssociations") 

#Firefox Settings
$FireFox_BrowzerSettings = New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".htm" -Value @("Firefox", "FirefoxHTML-E7CF176E110C211B","AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name ".html" -Value @("Firefox", "FirefoxHTML-E7CF176E110C211B","AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name "http" -Value @("Firefox", "FirefoxURL-E7CF176E110C211B","AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name "https" -Value @("Firefox", "FirefoxURL-E7CF176E110C211B","AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
$FireFox_BrowzerSettings.Add($obj)|Out-Null

#Internet Explorer Settings
$IE_BrowzerSettings = New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".htm" -Value @("Internet Explorer", "htmlfile","AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name ".html" -Value @("Internet Explorer", "htmlfile","AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name "http" -Value @("Internet Explorer", "IE.HTTP","AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name "https" -Value @("Internet Explorer", "IE.HTTPS","AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
$IE_BrowzerSettings.Add($obj)|Out-Null

# Chrome Settings
$Chrome_BrowzerSettings = New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".htm" -Value @("Google Chrome", "ChromeHTML", "AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name ".html" -Value @("Google Chrome", "ChromeHTML", "AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name "http" -Value @("Google Chrome", "ChromeHTML", "AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name "https" -Value @("Google Chrome", "ChromeHTML", "AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
$Chrome_BrowzerSettings.Add($obj)|Out-Null

# Edge Chromium Settings
$Edge_BrowzerSettings = New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".htm" -Value @("Microsoft Edge", "MSEdgeHTM", "AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name ".html" -Value @("Microsoft Edge", "MSEdgeHTM", "AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name "http" -Value @("Microsoft Edge", "MSEdgeHTM", "AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name "https" -Value @("Microsoft Edge", "MSEdgeHTM", "AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name "microsoft-edge" -Value @("Microsoft Edge", "MSEdgeHTM", "AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name "microsoft-edge-holographic" -Value @("Microsoft Edge", "MSEdgeHTM", "AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
    $obj|Add-Member -MemberType NoteProperty -Name "ms-xbl-3d8b930f" -Value @("Microsoft Edge", "MSEdgeHTM", "AppX4hxtad77fbk3jkkeerkrm0ze94wjf3s9")
$Edge_BrowzerSettings.Add($obj)|Out-Null


# Adobe Settings
$Adobe_PDFReaderSettings = New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    #$obj|Add-Member -MemberType NoteProperty -Name ".pdf" -Value @("Adobe Acrobat Reader DC", "AcroExch.Document.DC","AppXd4nrz8ff68srnhf9t5a8sbjyar1cr723;ChromeHTML;FirefoxHTML")
    $obj|Add-Member -MemberType NoteProperty -Name ".pdf" -Value @("Adobe Acrobat Reader DC", "AcroExch.Document.DC")
    $obj|Add-Member -MemberType NoteProperty -Name ".pdfxml" -Value @("Adobe Acrobat Reader DC", "AcroExch.pdfxml")
    $obj|Add-Member -MemberType NoteProperty -Name ".pdx" -Value @("Adobe Acrobat Reader DC", "PDXFileType")
    $obj|Add-Member -MemberType NoteProperty -Name ".xfdf" -Value @("Adobe Acrobat Reader DC", "AcroExch.XFDFDoc")
    $obj|Add-Member -MemberType NoteProperty -Name ".xdp" -Value @("Adobe Acrobat Reader DC", "AcroExch.XDPDoc")
    $obj|Add-Member -MemberType NoteProperty -Name "acrobat" -Value @("Adobe Acrobat Reader DC", "acrobat")
$Adobe_PDFReaderSettings.Add($obj)|Out-Null


# Edge Chromium Settings
$Edge_PDFReaderSettings = New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".pdf" -Value @("Microsoft Edge", "MSEdgePDF")
$Adobe_PDFReaderSettings.Add($obj)|Out-Null


# 'old' Photo Viewer Settings
$PhotoViewer_ViewerSettings= New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".bmp" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.Bitmap")
    $obj|Add-Member -MemberType NoteProperty -Name ".dib" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.Bitmap")
    $obj|Add-Member -MemberType NoteProperty -Name ".gif" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.Gif")
    $obj|Add-Member -MemberType NoteProperty -Name ".jfif" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.JFIF")
    $obj|Add-Member -MemberType NoteProperty -Name ".jpe" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.Jpeg")
    $obj|Add-Member -MemberType NoteProperty -Name ".jpeg" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.Jpeg")
    $obj|Add-Member -MemberType NoteProperty -Name ".jpg" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.Jpeg")
    $obj|Add-Member -MemberType NoteProperty -Name ".jxr" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.Wdp")
    $obj|Add-Member -MemberType NoteProperty -Name ".png" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.Png")
    $obj|Add-Member -MemberType NoteProperty -Name ".tif" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.Tiff")
    $obj|Add-Member -MemberType NoteProperty -Name ".tiff" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.Tiff")
    $obj|Add-Member -MemberType NoteProperty -Name ".wdp" -Value @("##LocalizedAppName##", "PhotoViewer.FileAssoc.Wdp")
$PhotoViewer_ViewerSettings.Add($obj)|Out-Null


# VLC Movie player Settings
$VLC_MovieSettings= New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".3g2" -Value @("VLC media player", "VLC.3g2")
    $obj|Add-Member -MemberType NoteProperty -Name ".3gp" -Value @("VLC media player", "VLC.3gp")
    $obj|Add-Member -MemberType NoteProperty -Name ".3gp2" -Value @("VLC media player", "VLC.3gp2")
    $obj|Add-Member -MemberType NoteProperty -Name ".3gpp" -Value @("VLC media player", "VLC.3gpp")
    $obj|Add-Member -MemberType NoteProperty -Name ".asf" -Value @("VLC media player", "VLC.asf")
    $obj|Add-Member -MemberType NoteProperty -Name ".ASX" -Value @("VLC media player", "VLC.asx")
    $obj|Add-Member -MemberType NoteProperty -Name ".avi" -Value @("VLC media player", "VLC.avi")
    $obj|Add-Member -MemberType NoteProperty -Name ".M1V" -Value @("VLC media player", "VLC.m1v")
    $obj|Add-Member -MemberType NoteProperty -Name ".m2t" -Value @("VLC media player", "VLC.m2t")
    $obj|Add-Member -MemberType NoteProperty -Name ".m2ts" -Value @("VLC media player", "VLC.m2ts")
    $obj|Add-Member -MemberType NoteProperty -Name ".m4v" -Value @("VLC media player", "VLC.m4v")
    $obj|Add-Member -MemberType NoteProperty -Name ".mkv" -Value @("VLC media player", "VLC.mkv")
    $obj|Add-Member -MemberType NoteProperty -Name ".mov" -Value @("VLC media player", "VLC.mov")
    $obj|Add-Member -MemberType NoteProperty -Name ".MP2V" -Value @("VLC media player", "VLC.mp2v")
    $obj|Add-Member -MemberType NoteProperty -Name ".mp4" -Value @("VLC media player", "VLC.mp4")
    $obj|Add-Member -MemberType NoteProperty -Name ".mp4v" -Value @("VLC media player", "VLC.mp4v")
    $obj|Add-Member -MemberType NoteProperty -Name ".mpa" -Value @("VLC media player", "VLC.mpa")
    $obj|Add-Member -MemberType NoteProperty -Name ".mpe" -Value @("VLC media player", "VLC.MPE")
    $obj|Add-Member -MemberType NoteProperty -Name ".mpeg" -Value @("VLC media player", "VLC.mpeg")
    $obj|Add-Member -MemberType NoteProperty -Name ".mpg" -Value @("VLC media player", "VLC.mpg")
    $obj|Add-Member -MemberType NoteProperty -Name ".mpv2" -Value @("VLC media player", "VLC.mpv2")
    $obj|Add-Member -MemberType NoteProperty -Name ".mts" -Value @("VLC media player", "VLC.mts")
    $obj|Add-Member -MemberType NoteProperty -Name ".TS" -Value @("VLC media player", "VLC.ts")
    $obj|Add-Member -MemberType NoteProperty -Name ".TTS" -Value @("VLC media player", "VLC.tts")
    $obj|Add-Member -MemberType NoteProperty -Name ".wmv" -Value @("VLC media player", "VLC.wmv")
    $obj|Add-Member -MemberType NoteProperty -Name ".wvx" -Value @("VLC media player", "VLC.wvx")
$VLC_MovieSettings.Add($obj)|Out-Null


# WMP Movie player Settings
$WMP_MovieSettings= New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".3g2" -Value @("Windows media player", "WMP11.AssocFile.3g2")
    $obj|Add-Member -MemberType NoteProperty -Name ".3gp" -Value @("Windows media player", "WMP11.AssocFile.3gp")
    $obj|Add-Member -MemberType NoteProperty -Name ".3gp2" -Value @("Windows media player", "WMP11.AssocFile.3g2")
    $obj|Add-Member -MemberType NoteProperty -Name ".3gpp" -Value @("Windows media player", "WMP11.AssocFile.3gp")
    $obj|Add-Member -MemberType NoteProperty -Name ".asf" -Value @("Windows media player", "WMP11.AssocFile.asf")
    $obj|Add-Member -MemberType NoteProperty -Name ".ASX" -Value @("Windows media player", "WMP11.AssocFile.asx")
    $obj|Add-Member -MemberType NoteProperty -Name ".avi" -Value @("Windows media player", "WMP11.AssocFile.avi")
    $obj|Add-Member -MemberType NoteProperty -Name ".M1V" -Value @("Windows media player", "WMP11.AssocFile.MPEG")
    $obj|Add-Member -MemberType NoteProperty -Name ".m2t" -Value @("Windows media player", "WMP11.AssocFile.m2ts")
    $obj|Add-Member -MemberType NoteProperty -Name ".m2ts" -Value @("Windows media player", "WMP11.AssocFile.m2ts")
    $obj|Add-Member -MemberType NoteProperty -Name ".m4v" -Value @("Windows media player", "WMP11.AssocFile.mp4")
    $obj|Add-Member -MemberType NoteProperty -Name ".MK3D" -Value @("Windows media player", "WMP11.AssocFile.MK3D")
    $obj|Add-Member -MemberType NoteProperty -Name ".mkv" -Value @("Windows media player", "WMP11.AssocFile.mkv")
    $obj|Add-Member -MemberType NoteProperty -Name ".mov" -Value @("Windows media player", "WMP11.AssocFile.mov")
    $obj|Add-Member -MemberType NoteProperty -Name ".MP2" -Value @("Windows media player", "WMP11.AssocFile.mp3")
    $obj|Add-Member -MemberType NoteProperty -Name ".MP2V" -Value @("Windows media player", "WMP11.AssocFile.mpeg")
    $obj|Add-Member -MemberType NoteProperty -Name ".mp4" -Value @("Windows media player", "WMP11.AssocFile.mp4")
    $obj|Add-Member -MemberType NoteProperty -Name ".mp4v" -Value @("Windows media player", "WMP11.AssocFile.mp4")
    $obj|Add-Member -MemberType NoteProperty -Name ".mpa" -Value @("Windows media player", "WMP11.AssocFile.mpeg")
    $obj|Add-Member -MemberType NoteProperty -Name ".mpe" -Value @("Windows media player", "WMP11.AssocFile.mpeg")
    $obj|Add-Member -MemberType NoteProperty -Name ".mpeg" -Value @("Windows media player", "WMP11.AssocFile.mpeg")
    $obj|Add-Member -MemberType NoteProperty -Name ".mpg" -Value @("Windows media player", "WMP11.AssocFile.mpeg")
    $obj|Add-Member -MemberType NoteProperty -Name ".mpv2" -Value @("Windows media player", "WMP11.AssocFile.mpeg")
    $obj|Add-Member -MemberType NoteProperty -Name ".mts" -Value @("Windows media player", "WMP11.AssocFile.m2ts")
    $obj|Add-Member -MemberType NoteProperty -Name ".TS" -Value @("Windows media player", "WMP11.AssocFile.tts")
    $obj|Add-Member -MemberType NoteProperty -Name ".TTS" -Value @("Windows media player", "WMP11.AssocFile.tts")
    $obj|Add-Member -MemberType NoteProperty -Name ".wm" -Value @("Windows media player", "WMP11.AssocFile.asf")
    $obj|Add-Member -MemberType NoteProperty -Name ".wmv" -Value @("Windows media player", "WMP11.AssocFile.wmv")
    $obj|Add-Member -MemberType NoteProperty -Name ".wmx" -Value @("Windows media player", "WMP11.AssocFile.asx")
    $obj|Add-Member -MemberType NoteProperty -Name ".wvx" -Value @("Windows media player", "WMP11.AssocFile.wvx")
$WMP_MovieSettings.Add($obj)|Out-Null


# VLC Music player Settings
$VLC_MusicSettings= New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".aac" -Value @("VLC media player", "VLC.aac")
    $obj|Add-Member -MemberType NoteProperty -Name ".adts" -Value @("VLC media player", "VLC.adts")
    $obj|Add-Member -MemberType NoteProperty -Name ".AIF" -Value @("VLC media player", "VLC.aif")
    $obj|Add-Member -MemberType NoteProperty -Name ".AIFC" -Value @("VLC media player", "VLC.aifc")
    $obj|Add-Member -MemberType NoteProperty -Name ".AIFF" -Value @("VLC media player", "VLC.aiff")
    $obj|Add-Member -MemberType NoteProperty -Name ".amr" -Value @("VLC media player", "VLC.amr")
    $obj|Add-Member -MemberType NoteProperty -Name ".AU" -Value @("VLC media player", "VLC.au")
    $obj|Add-Member -MemberType NoteProperty -Name ".cda" -Value @("VLC media player", "VLC.cda")
    $obj|Add-Member -MemberType NoteProperty -Name ".flac" -Value @("VLC media player", "VLC.flac")
    $obj|Add-Member -MemberType NoteProperty -Name ".m3u" -Value @("VLC media player", "VLC.m3u")
    $obj|Add-Member -MemberType NoteProperty -Name ".m4a" -Value @("VLC media player", "VLC.m4a")
    $obj|Add-Member -MemberType NoteProperty -Name ".m4p" -Value @("VLC media player", "VLC.m4p")
    $obj|Add-Member -MemberType NoteProperty -Name ".mid" -Value @("VLC media player", "VLC.mid")
    $obj|Add-Member -MemberType NoteProperty -Name ".mka" -Value @("VLC media player", "VLC.MKA")
    $obj|Add-Member -MemberType NoteProperty -Name ".mp2" -Value @("VLC media player", "VLC.mp2")
    $obj|Add-Member -MemberType NoteProperty -Name ".mp3" -Value @("VLC media player", "VLC.mp3")
    $obj|Add-Member -MemberType NoteProperty -Name ".ra" -Value @("VLC media player", "VLC.ra")
    $obj|Add-Member -MemberType NoteProperty -Name ".ram" -Value @("VLC media player", "VLC.ram")
    $obj|Add-Member -MemberType NoteProperty -Name ".RMI" -Value @("VLC media player", "VLC.rmi")
    $obj|Add-Member -MemberType NoteProperty -Name ".s3m" -Value @("VLC media player", "VLC.s3m")
    $obj|Add-Member -MemberType NoteProperty -Name ".SND" -Value @("VLC media player", "VLC.snd")
    $obj|Add-Member -MemberType NoteProperty -Name ".voc" -Value @("VLC media player", "VLC.voc")
    $obj|Add-Member -MemberType NoteProperty -Name ".wav" -Value @("VLC media player", "VLC.wav")
    $obj|Add-Member -MemberType NoteProperty -Name ".wma" -Value @("VLC media player", "VLC.wma")
    $obj|Add-Member -MemberType NoteProperty -Name ".xm" -Value @("VLC media player", "VLC.xm")
$VLC_MusicSettings.Add($obj)|Out-Null


# WMP Music player Settings
$WMP_MusicSettings= New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".aac" -Value @("Windows media player", "WMP11.AssocFile.ADTS")
    $obj|Add-Member -MemberType NoteProperty -Name ".adts" -Value @("Windows media player", "WMP11.AssocFile.ADTS")
    $obj|Add-Member -MemberType NoteProperty -Name ".AIF" -Value @("Windows media player", "WMP11.AssocFile.aiff")
    $obj|Add-Member -MemberType NoteProperty -Name ".AIFC" -Value @("Windows media player", "WMP11.AssocFile.aifc")
    $obj|Add-Member -MemberType NoteProperty -Name ".AIFF" -Value @("Windows media player", "WMP11.AssocFile.aiff")
    $obj|Add-Member -MemberType NoteProperty -Name ".asx" -Value @("Windows media player", "WMP11.AssocFile.asx")
    $obj|Add-Member -MemberType NoteProperty -Name ".AU" -Value @("Windows media player", "WMP11.AssocFile.au")
    $obj|Add-Member -MemberType NoteProperty -Name ".cda" -Value @("Windows media player", "WMP11.AssocFile.cda")
    $obj|Add-Member -MemberType NoteProperty -Name ".flac" -Value @("Windows media player", "VLWMP11.AssocFile.flac")
    $obj|Add-Member -MemberType NoteProperty -Name ".m3u" -Value @("Windows media player", "WMP11.AssocFile.m3u")
    $obj|Add-Member -MemberType NoteProperty -Name ".m4a" -Value @("Windows media player", "WMP11.AssocFile.m4a")
    $obj|Add-Member -MemberType NoteProperty -Name ".mid" -Value @("Windows media player", "WMP11.AssocFile.midi")
    $obj|Add-Member -MemberType NoteProperty -Name ".midi" -Value @("Windows media player", "WMP11.AssocFile.midi")
    $obj|Add-Member -MemberType NoteProperty -Name ".MK3D" -Value @("Windows media player", "WMP11.AssocFile.MK3D")
    $obj|Add-Member -MemberType NoteProperty -Name ".mka" -Value @("Windows media player", "WMP11.AssocFile.MKA")
    $obj|Add-Member -MemberType NoteProperty -Name ".mp2" -Value @("Windows media player", "WMP11.AssocFile.mp3")
    $obj|Add-Member -MemberType NoteProperty -Name ".mp3" -Value @("Windows media player", "WMP11.AssocFile.mp3")
    $obj|Add-Member -MemberType NoteProperty -Name ".mpa" -Value @("Windows media player", "WMP11.AssocFile.mpeg")
    $obj|Add-Member -MemberType NoteProperty -Name ".RMI" -Value @("Windows media player", "WMP11.AssocFile.MIDI")
    $obj|Add-Member -MemberType NoteProperty -Name ".SND" -Value @("Windows media player", "WMP11.AssocFile.snd")
    $obj|Add-Member -MemberType NoteProperty -Name ".wav" -Value @("Windows media player", "WMP11.AssocFile.wav")
    $obj|Add-Member -MemberType NoteProperty -Name ".wax" -Value @("Windows media player", "WMP11.AssocFile.wax")
    $obj|Add-Member -MemberType NoteProperty -Name ".wma" -Value @("Windows media player", "WMP11.AssocFile.wma")
    $obj|Add-Member -MemberType NoteProperty -Name ".wmx" -Value @("Windows media player", "WMP11.AssocFile.wmx")
    $obj|Add-Member -MemberType NoteProperty -Name ".wpl" -Value @("Windows media player", "WMP11.AssocFile.wpl")
    $obj|Add-Member -MemberType NoteProperty -Name ".wvx" -Value @("Windows media player", "WMP11.AssocFile.wvx")
$WMP_MusicSettings.Add($obj)|Out-Null


# Outlook Mail client
$OutLook_MailSettings = New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name "mailto" -Value @("Outlook", "Outlook.URL.mailto.15")
$OutLook_MailSettings.Add($obj)|Out-Null


# Chrome Mail client
$Chrome_MailSettings = New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name "mailto" -Value @("Google Chrome", "ChromeHTML")
$Chrome_MailSettings.Add($obj)|Out-Null


# 7zip Archive manager
$7zip_ArchiverSettings = New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".001" -Value @("7-Zip File Manager", "7-Zip.001")
    $obj|Add-Member -MemberType NoteProperty -Name ".cab" -Value @("7-Zip File Manager", "7-Zip.cab")
    $obj|Add-Member -MemberType NoteProperty -Name ".gz" -Value @("7-Zip File Manager", "7-Zip.gz")
    $obj|Add-Member -MemberType NoteProperty -Name ".gzip" -Value @("7-Zip File Manager", "7-Zip.gzip")
    $obj|Add-Member -MemberType NoteProperty -Name ".tgz" -Value @("7-Zip File Manager", "7-Zip.tgz")
    $obj|Add-Member -MemberType NoteProperty -Name ".rar" -Value @("7-Zip File Manager", "7-Zip.rar")
    $obj|Add-Member -MemberType NoteProperty -Name ".tar" -Value @("7-Zip File Manager", "7-Zip.tar")
    $obj|Add-Member -MemberType NoteProperty -Name ".zip" -Value @("7-Zip File Manager", "7-Zip.zip")
    $obj|Add-Member -MemberType NoteProperty -Name ".7Z" -Value @("7-Zip File Manager", "7-Zip.7z")
$7zip_ArchiverSettings.Add($obj)|Out-Null


# Txt default viewer
$NPPP_TextSettings = New-Object System.Collections.ArrayList
    $obj = New-Object System.Object
    $obj|Add-Member -MemberType NoteProperty -Name ".txt" -Value @("Notepad++ : a free (GNU) source code editor", "Notepad++_file")
    $obj|Add-Member -MemberType NoteProperty -Name ".ini" -Value @("Notepad++ : a free (GNU) source code editor", "Notepad++_file")
    $obj|Add-Member -MemberType NoteProperty -Name ".nfo" -Value @("Notepad++ : a free (GNU) source code editor", "Notepad++_file")
    $obj|Add-Member -MemberType NoteProperty -Name ".inf" -Value @("Notepad++ : a free (GNU) source code editor", "Notepad++_file")
    $obj|Add-Member -MemberType NoteProperty -Name ".log" -Value @("Notepad++ : a free (GNU) source code editor", "Notepad++_file")
$NPPP_TextSettings.Add($obj)|Out-Null



#Function
Function New-AppAssociation
    {

	    Param (
                [parameter(Mandatory = $False)]
                [String]$AppName,

                [parameter(Mandatory = $true)]
                [System.Object]$Settings
			)
			
		$MoreSettingsRT = Set-MoreStuffs -App $AppName

        $settings| Get-Member -MemberType NoteProperty | foreach name | 
        foreach { 
                    #Parse Object
                    $fExtension = $_
                    $ExtProperties = $settings.$_
                    $fProgId = $ExtProperties[1]
                    $fAppName = $ExtProperties[0]
                    $fOverwriteApps = $ExtProperties[2]
                    
	                $xmlNode = $OEMXMLFile.DefaultAssociations.Association | Where Identifier -eq $fExtension
	                $newNode = $OEMXMLFile.CreateElement("Association")
   	                        
                    $attrIdentifier = $OEMXMLFile.CreateAttribute("Identifier")
	                $attrIdentifier.Value = "$($fExtension)"
	                $attrProgId = $OEMXMLFile.CreateAttribute("ProgId")
	                $attrProgId.Value = "$($fProgId)"
                    $AttrOnUpgrade = $OEMXMLFile.CreateAttribute("ApplyOnUpgrade")
                    $AttrOnUpgrade.Value = "true"


	                $attrAppName = $OEMXMLFile.CreateAttribute("ApplicationName")
                    If ($fAppName -eq "##LocalizedAppName##")
                        {$attrAppName.Value = $MoreSettingsRT}
                    Else
                        {$attrAppName.Value = "$($fAppName)"}



                    $newNode.Attributes.Append($attrIdentifier)|Out-Null
	                $newNode.Attributes.Append($attrProgId)|Out-Null
	                $newNode.Attributes.Append($attrAppName)|Out-Null
                    $newNode.Attributes.Append($AttrOnUpgrade)|Out-Null

                    If (![string]::IsNullOrWhiteSpace($xmlNode.OverwriteIfProgIdIs))
                        {
	                        $attrOverwriteIfProgIdIs = $OEMXMLFile.CreateAttribute("OverwriteIfProgIdIs")
                            $attrOverwriteIfProgIdIs.value = "$($xmlNode.OverwriteIfProgIdIs)"
                                    
                            If (![string]::IsNullOrWhiteSpace($fOverwriteAppss)){$attrOverwriteIfProgIdIs.value = $attrOverwriteIfProgIdIs.value + ";" + $fOverwriteApps}  
                            $newNode.Attributes.Append($attrOverwriteIfProgIdIs)|Out-Null
                        }
                    Else
                        {
                            If (![string]::IsNullOrWhiteSpace($fOverwriteAppss))
                                {
                                    $attrOverwriteIfProgIdIs = $OEMXMLFile.CreateAttribute("OverwriteIfProgIdIs")
                                    $attrOverwriteIfProgIdIs.value = $fOverwriteApps
                                    $newNode.Attributes.Append($attrOverwriteIfProgIdIs)|Out-Null
                                }  
                        }

                            

	                if (!([string]::IsNullOrEmpty($xmlNode)))
	                    {
		                    $currentApp = $xmlNode.ApplicationName
                            Write-host "Extension $fExtension is currently assigned to $($currentApp). Re-assigning to $($attrAppName.value)"
		                    $rootNode.ReplaceChild($newNode, $xmlNode)|Out-Null
		                    #$OEMXMLFile.save("C:\Temp\TestPNG.xml")
                            $OEMXMLFile.Save($Path)
	                    }
	                else
	                    {
		                    Write-host "Extension $fExtension is currently not assigned to an application. Assigning it to $fAppName."
		                    $rootNode.AppendChild($newNode)|Out-Null
		                    #$OEMXMLFile.save("C:\Temp\TestPNG.xml")
                            $OEMXMLFile.Save($Path)
	                    }

            }
    }


Function Set-MoreStuffs ($App)
    {
        # Additional config for legacy photoViewer
        If ($App -eq "PhotoViewer")
            {
                write-host "Processing additional stuff for $App"
                ForEach ($type in @("Paint.Picture", "giffile", "jpegfile", "pngfile")) 
                    {
		                New-Item -Path $("HKCR:\$type\shell\open") -Force | Out-Null
		                New-Item -Path $("HKCR:\$type\shell\open\command") | Out-Null
		                Set-ItemProperty -Path $("HKCR:\$type\shell\open") -Name "MuiVerb" -Type ExpandString -Value "@%ProgramFiles%\Windows Photo Viewer\photoviewer.dll,-3043"
		                Set-ItemProperty -Path $("HKCR:\$type\shell\open\command") -Name "(Default)" -Type ExpandString -Value "%SystemRoot%\System32\rundll32.exe `"%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll`", ImageView_Fullscreen %1"
	                }

                New-Item -Path "HKCR:\Applications\photoviewer.dll\shell\open\command" -Force | Out-Null
                New-Item -Path "HKCR:\Applications\photoviewer.dll\shell\open\DropTarget" -Force | Out-Null
                Set-ItemProperty -Path "HKCR:\Applications\photoviewer.dll\shell\open" -Name "MuiVerb" -Type String -Value "@photoviewer.dll,-3043"
                Set-ItemProperty -Path "HKCR:\Applications\photoviewer.dll\shell\open\command" -Name "(Default)" -Type ExpandString -Value "%SystemRoot%\System32\rundll32.exe `"%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll`", ImageView_Fullscreen %1"
                Set-ItemProperty -Path "HKCR:\Applications\photoviewer.dll\shell\open\DropTarget" -Name "Clsid" -Type String -Value "{FFE2A43C-56B9-4bf5-9A79-CC6D4285608A}"

                New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Force | Out-Null
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities" -Name "ApplicationDescription" -Type String -Value "@%ProgramFiles%\Windows Photo Viewer\photoviewer.dll,-3069"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities" -Name "ApplicationName" -Type String -Value "@%ProgramFiles%\Windows Photo Viewer\photoviewer.dll,-3009"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".cr2" -Type String -Value "PhotoViewer.FileAssoc.Tiff"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".tif" -Type String -Value "PhotoViewer.FileAssoc.Tiff"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".tiff" -Type String -Value "PhotoViewer.FileAssoc.Tiff"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".Jpg" -Type String -Value "PhotoViewer.FileAssoc.Jpeg"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".wdp" -Type String -Value "PhotoViewer.FileAssoc.Wdp"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".jfif" -Type String -Value "PhotoViewer.FileAssoc.Jfif"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".dib" -Type String -Value "PhotoViewer.FileAssoc.Bitmap"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".png" -Type String -Value "PhotoViewer.FileAssoc.Png"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".jxr" -Type String -Value "PhotoViewer.FileAssoc.Wdp"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".bmp" -Type String -Value "PhotoViewer.FileAssoc.Bitmap"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".jpe" -Type String -Value "PhotoViewer.FileAssoc.Jpeg"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".jpeg" -Type String -Value "PhotoViewer.FileAssoc.Jpeg"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Photo Viewer\Capabilities\FileAssociations" -Name ".gif" -Type String -Value "PhotoViewer.FileAssoc.Gif"


                #Localize String
                If((Get-WinSystemLocale).LCID -eq 1033) {$LocalizedAppName = 'Visionneuse de photos Windows'} Else {$LocalizedAppName = 'Windows Photo Viewer'}

                Set-ItemProperty -Path "HKCR:\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" -Name "C:\Program Files\Windows Photo Viewer\PhotoViewer.dll.ApplicationCompany" -Type String -Value "Microsoft Corporation"
                Set-ItemProperty -Path "HKCR:\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" -Name "C:\Program Files\Windows Photo Viewer\PhotoViewer.dll.FriendlyAppName" -Type String -Value $LocalizedAppName

                # Close and restart Explorer
                # Stop-Process -ProcessName explorer
                

                ## $LocalizedAppName = (Get-ItemProperty "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache")."C:\Program Files\Windows Photo Viewer\PhotoViewer.dll.FriendlyAppName"
                # $LocalizedAppName = (Get-ItemProperty 'HKCR:\Local Settings\Software\Microsoft\Windows\Shell\MuiCache')."C:\Program Files\Windows Photo Viewer\PhotoViewer.dll.FriendlyAppName"
                Return $LocalizedAppName
            }


        # Additional config for 7Zip
        If ($App.ToUpper() -eq "7ZIP")
            {

                write-host "Processing additional stuff for $App"

                Set-ItemProperty -Path "HKCR:\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" -Name "C:\Program Files\7-Zip\7zFM.exe.FriendlyAppName" -Type String -Value "7-Zip File Manager"
                Set-ItemProperty -Path "HKCR:\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" -Name "C:\Program Files\7-Zip\7zFM.exe.ApplicationCompany" -Type String -Value "Igor Pavlov"

                ForEach ($type in @(".7z", ".zip", ".rar", ".001", ".cab", ".gz", ".gzip", ".tgz", "tar")) 
                    {
		                New-Item -Path $("HKCR:\$type") -force | Out-Null
		                Set-ItemProperty -Path $("HKCR:\$type") -Name "(Default)" -Type String -Value "7-Zip$type"

		                New-Item -Path $("HKCR:\7-Zip$type\DefaultIcon") -force | Out-Null
		                New-Item -Path $("HKCR:\7-Zip$type\shell\open\command") -force | Out-Null
		                Set-ItemProperty -Path $("HKCR:\7-Zip$type\shell\open\command") -Name "(Default)" -Type String -Value '"C:\Program Files\7-Zip\7zFM.exe" "%1"'

                        Switch ($type) {

                                ".001" { Set-ItemProperty -Path $("HKCR:\7-Zip$type\DefaultIcon") -Name "(Default)" -Type String -Value 'C:\Program Files\7-Zip\7z.dll,9'; break}
                                ".7z" { Set-ItemProperty -Path $("HKCR:\7-Zip$type\DefaultIcon") -Name "(Default)" -Type String -Value 'C:\Program Files\7-Zip\7z.dll,0'; break}
                                ".cab" { Set-ItemProperty -Path $("HKCR:\7-Zip$type\DefaultIcon") -Name "(Default)" -Type String -Value 'C:\Program Files\7-Zip\7z.dll,7'; break}
                                ".gz" { Set-ItemProperty -Path $("HKCR:\7-Zip$type\DefaultIcon") -Name "(Default)" -Type String -Value 'C:\Program Files\7-Zip\7z.dll,14'; break}
                                ".gzip" { Set-ItemProperty -Path $("HKCR:\7-Zip$type\DefaultIcon") -Name "(Default)" -Type String -Value 'C:\Program Files\7-Zip\7z.dll,14'; break}
                                ".rar" { Set-ItemProperty -Path $("HKCR:\7-Zip$type\DefaultIcon") -Name "(Default)" -Type String -Value 'C:\Program Files\7-Zip\7z.dll,3'; break}
                                ".tar" { Set-ItemProperty -Path $("HKCR:\7-Zip$type\DefaultIcon") -Name "(Default)" -Type String -Value 'C:\Program Files\7-Zip\7z.dll,13'; break}
                                ".zip" { Set-ItemProperty -Path $("HKCR:\7-Zip$type\DefaultIcon") -Name "(Default)" -Type String -Value 'C:\Program Files\7-Zip\7z.dll,1'; break}
                                ".tgz" { Set-ItemProperty -Path $("HKCR:\7-Zip$type\DefaultIcon") -Name "(Default)" -Type String -Value 'C:\Program Files\7-Zip\7z.dll,14'; break}                                                                                                                                
                            }

	                }



            }

        # Additional config for Notepad++
        If ($App.ToUpper() -eq "NPPP")
            {
                write-host "Processing additional stuff for $App"

                Set-ItemProperty -Path "HKCR:\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" -Name "C:\Program Files (x86)\Notepad++\notepad++.exe.FriendlyAppName" -Type String -Value "Notepad++ : a free (GNU) source code editor"
                Set-ItemProperty -Path "HKCR:\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" -Name "C:\Program Files (x86)\Notepad++\notepad++.exe.ApplicationCompany" -Type String -Value "Don HO don.h@free.fr"

		        New-Item -Path "HKLM:\SOFTWARE\Classes\Notepad++_file\DefaultIcon" -Force | Out-Null
		        New-Item -Path "HKLM:\SOFTWARE\Classes\Notepad++_file\shell\open\command" -Force | Out-Null
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\Notepad++_file" -Name '(Default)' -Value "Notepad++ Document"
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\Notepad++_file\DefaultIcon" -Name '(Default)' -Value '"C:\Program Files (x86)\Notepad++\notepad++.exe",0'
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Classes\Notepad++_file\shell\open\command" -Name ‘(Default)’ -Value '"C:\Program Files (x86)\Notepad++\notepad++.exe" "%1"'

                ForEach ($type in @(".ini", ".inf", ".mak", ".nfo", ".txt", ".log")) 
                    {
		                Set-ItemProperty -Path $("HKCR:\$type") -Name ‘(Default)’ -Value "Notepad++_file"
		                Set-ItemProperty -Path $("HKCR:\$type") -Name "Notepad++_backup" -Value "inffile" -Type String
	                }
            }

    }

#Set New Default browzer
If (![string]::IsNullOrWhiteSpace($DefaultBrowzer))
	{
		Write-host "###################################"
		Write-Host "Processing New Default browzer - $DefaultBrowzer"
		Write-host "###################################"
		$DefaultSettings = Get-Variable -name "$DefaultBrowzer*_BrowzerSettings" -ValueOnly
		New-AppAssociation -settings $DefaultSettings -AppName $DefaultBrowzer
	}


#Set New Default Pdf Reader
If (![string]::IsNullOrWhiteSpace($DefaultPdfReader))
	{
		Write-host "###################################"
		Write-Host "Processing New Default Pdf Reader - $DefaultPdfReader"
		Write-host "###################################"
		$DefaultSettings = Get-Variable -name "$DefaultPdfReader*PDFReaderSettings" -ValueOnly
		New-AppAssociation -settings $DefaultSettings -AppName $DefaultPdfReader
	}


#Set New Default Image Viewer
If (![string]::IsNullOrWhiteSpace($DefaultImageViewer))
	{
		Write-host "###################################"
		Write-Host "Processing New Default Image Viewer - $DefaultImageViewer"
		Write-host "###################################"
		$DefaultSettings = Get-Variable -name "$DefaultImageViewer*_ViewerSettings" -ValueOnly
		New-AppAssociation -settings $DefaultSettings -AppName $DefaultImageViewer
	}


#Set New Default Music Player
If (![string]::IsNullOrWhiteSpace($DefaultMusicPlayer))
	{
		Write-host "###################################"
		Write-Host "Processing New Default Music Player - $DefaultMusicPlayer"
		Write-host "###################################"
		$DefaultSettings = Get-Variable -name "$DefaultMusicPlayer*_MusicSettings" -ValueOnly
		New-AppAssociation -settings $DefaultSettings -AppName $DefaultMusicPlayer
	}	


#Set New Default Video Player
If (![string]::IsNullOrWhiteSpace($DefaultMoviePlayer))
	{
		Write-host "###################################"
		Write-Host "Processing New Default Video Player - $DefaultMusicPlayer"
		Write-host "###################################"
		$DefaultSettings = Get-Variable -name "$DefaultMoviePlayer*_MovieSettings" -ValueOnly
		New-AppAssociation -settings $DefaultSettings -AppName $DefaultMoviePlayer
	}	


If (![string]::IsNullOrWhiteSpace($DefaultMailClient))
	{
		#Set New Default Mail Client
		Write-host "###################################"
		Write-Host "Processing New Default Mail Client - $DefaultMailClient"
		Write-host "###################################"
		$DefaultSettings = Get-Variable -name "$DefaultMailClient*_MailSettings" -ValueOnly
		New-AppAssociation -settings $DefaultSettings -AppName $DefaultMailClient
	}	


If (![string]::IsNullOrWhiteSpace($DefaultArchiver))
	{
		#Set New Default Archive Manager
		Write-host "#######################################"
		Write-Host "Processing New Default Archive Manager"
		Write-host "#######################################"
		$DefaultSettings = Get-Variable -name "$DefaultArchiver*_ArchiverSettings" -ValueOnly
		New-AppAssociation -settings $DefaultSettings -AppName $DefaultArchiver
	}


If (![string]::IsNullOrWhiteSpace($DefaulTxtViewer))
	{
		#Set New Default Text Viewer
		Write-host "###################################"
		Write-Host "Processing New Default Text Viewer"
		Write-host "###################################"
		$DefaultSettings = Get-Variable -name "$DefaulTxtViewer*_TextSettings" -ValueOnly
		New-AppAssociation -settings $DefaultSettings -AppName $DefaulTxtViewer
	}


##== Applying Additional Configuration
# Disable 'How do you want to open this file?' prompt
If (!(Test-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer")){New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" | Out-Null}
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoNewAppAlert" -Type DWord -Value 1

Write-Host "All settings commited to file $Path"
Write-Host "File Association finished!!!"