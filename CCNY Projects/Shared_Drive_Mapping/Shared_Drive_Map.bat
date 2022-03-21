@echo off
rem Map Users to Specified Share
@net use Z: \\134.74.74.29\csbackups\ /PERSISTENT:YES 

pushd %~dp0
rem Creates Shortcuts of all Network Drives
cscript /nologo Network_Drive_Shortcut.vbs

