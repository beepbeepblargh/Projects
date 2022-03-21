strComputer = "."

Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
Set colItems = objWMIService.ExecQuery("Select * From Win32_LogicalDisk Where DriveType = 4")
set WshShell = WScript.CreateObject("WScript.Shell" )
strDesktop = WshShell.SpecialFolders("Desktop" )

For Each objItem in colItems
Dim strProviderName
strProviderName = objItem.ProviderName
trimNameStart = instrRev(strProviderName,"\")
trimNameEnd = Len(strProviderName)

trimServerStart = instr(strProviderName,"\\")
trimServerEnd = instrRev(strProviderName,"\")

shareName = Mid(strProviderName,trimNameStart+1,trimNameEnd)
serverName = Mid(strProviderName,trimServerStart+2,trimServerEnd-3)

'Creates Desktop Shortcut
set oShellLink = WshShell.CreateShortcut(strDesktop & "\" & shareName & " (" & serverName & ") " & "(" & Replace(objItem.Name,":","") & ") - Shortcut.lnk" )
oShellLink.TargetPath = objItem.Name & "\"
oShellLink.WindowStyle = 1
oShellLink.IconLocation = "%SystemRoot%\system32\SHELL32.dll, 9"
oShellLink.Description = shareName & " (" & serverName & ") " & "(" & Replace(objItem.Name,":","") & ")"
oShellLink.Save

Next