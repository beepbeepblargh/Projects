Dim WSHShell 
Dim MyShortcut 
Dim DesktopPath

Set WSHShell = CreateObject("WScript.Shell") 
If not WSHShell Is Nothing Then 
DesktopPath = WSHShell.SpecialFolders("Desktop") 
Set MyShortcut = WSHShell.CreateShortCut(DesktopPath & "\HRFiles$" & ".lnk") 
MyShortcut.TargetPath = "\\134.74.216.71\hrfiles$" 
MyShortcut.WorkingDirectory = "%USERPROFILE%\Desktop" 
MyShortcut.WindowStyle = 1 
MyShortcut.Arguments = "" 
MyShortcut.Save 
Set MyShortcut = Nothing 
end if 