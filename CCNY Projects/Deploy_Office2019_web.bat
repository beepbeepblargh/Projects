@echo off
If exist C:\Users\Helpdesk\Desktop\Deploy_Office2019\setup.exe (
    Echo File exists
	start C:\Users\Helpdesk\Desktop\Deploy_Office2019\setup.exe /configure C:\Users\Helpdesk\Desktop\Deploy_Office2019\configuration_x64_from_web.xml
) Else (
	Echo "Please move setup.exe and .xml to C:\Users\Helpdesk\Desktop\Deploy_Office2019\"
	)
TIMEOUT /T 10
rem Script by Chris Ng
Exit
