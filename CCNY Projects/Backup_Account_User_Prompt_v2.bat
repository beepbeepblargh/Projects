@echo off
REM Written by Chris Ng
REM Mounts Csbackups network share
net use Z: \\134.74.74.29\csbackups /PERSISTENT:YES 
set /P Decide= "Is this a backup or a restore? (Answer only Backup or Restore)"
if %Decide% == Backup goto :Backup1
if %Decide% == Restore goto :Restore1
:Backup1
Echo Backup Prompt
REM Prompt technician for folder name you want to make in csbackups
set /P folder= "What is the folder name you're trying to make in csbackups?":
mkdir \\134.74.74.29\csbackups\%folder%
REM Asks for User Account and searchs for it under C:\. Then robocopy entire folder to earlier named folder.
set /P User= "What is the account you are trying to backup?"
if exist C:\Users\%User% (robocopy "C:\Users\%User%" "//134.74.74.29/CSBACKUPS/%folder%" /b /e /XJ /XD "appdata" /copy:dat /efsraw /r:3 /w:1 /reg) else (echo "User does not exist on this computer. Please check again")
goto :end

:Restore1
Echo Restore Prompt
set /P _folder= "What is the name of the folder you're trying to copy?"
if exist \\134.74.74.29\csbackups\%_folder% set /P _where= "Where are you restoring the data to? (full path)"
robocopy "\\134.74.74.29\csbackups\%_folder%" "%_where%" /e /reg /r:3 /w:3
goto :end

:end
net use Z: /delete
Pause

Exit