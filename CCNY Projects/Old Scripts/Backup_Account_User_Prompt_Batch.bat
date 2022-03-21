@echo off
REM Mounts Csbackups network share
net use Z: \\134.74.74.29\csbackups /PERSISTENT:YES 
REM Prompt technician for folder name you want to make in csbackups
set /P _folder= "What is the folder name you're trying to make in csbackups?":
mkdir \\134.74.74.29\csbackups\%_folder%
REM Asks for User Account and searchs for it under C:\. Then robocopy entire folder to earlier named folder.
set /P _User= "What is the account you are trying to backup?"
if exist C:\Users\%_User% (robocopy "C:\Users\%_User%" "//134.74.74.29/CSBACKUPS/%_folder%" /e /XJ /XD "appdata" /copy:dat /efsraw /r:3 /w:1 /reg) else (echo "User does not exist on this computer. Please check again")

net use Z: /delete
Pause
	
Exit
