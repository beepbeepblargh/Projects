@echo off
start C:\Users\helpdesk\Desktop\SurfaceGO\anyconnect-win-4.7.04056-core-vpn-webdeploy-k9.exe /norestart /passive
start C:\Users\Helpdesk\Desktop\SurfaceGO\McAfee\setupEP.exe ADDLOCAL="tp,wc" INSTALLDIR="C:\Program Files\McAfee" /qn /qb
start C:\Users\Helpdesk\Desktop\SurfaceGO\Deploy_Office2019\setup.exe /configure C:\Users\Helpdesk\Desktop\SurfaceGO\Deploy_Office2019\configuration_x64_from_web.xml
start C:\Users\Helpdesk\Desktop\SurfaceGO\Adobe_NUL_Installer_2020.01.23\Build\setup.exe --silent --ADOBEINSTALLDIR="C:\Program Files (x86)\Adobe" --INSTALLLANGUAGE=en_US
rem Script by Chris Ng