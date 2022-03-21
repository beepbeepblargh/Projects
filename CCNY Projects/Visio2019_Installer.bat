@echo off
If exist C:\Users\Helpdesk\Desktop\Project_and_Visio\setup.exe (
    Echo File exists
	start C:\Users\Helpdesk\Desktop\Project_and_Visio\setup.exe /configure C:\Users\Helpdesk\Desktop\Project_and_Visio\configuration_from_web_visio2019_MAK_KEY_NOKMS.xml
) Else (
	Echo "Please move setup.exe and .xml to C:\Users\Helpdesk\Desktop\Project & Visio\"
	)
TIMEOUT /T 10
Exit
