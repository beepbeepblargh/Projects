#!/bin/bash
#Written by Chris Ng

#This will auto-mount SPSS silent install.bin and attempt to run it. Does NOT work without Java installed.

hdiutil attach ~/Desktop/Install/SPSS_Statistics_25_mac_silent.dmg

cp /Volumes/SPSS_Statistics_Installer/SPSS_Statistics_Installer.bin ~/Desktop/Bash
cp /Volumes/SPSS_Statistics_Installer/installer.properties ~/Desktop/Bash
sudo ./SPSS_Statistics_Installer.bin -f "~/installer.properties"

hdiutil detach /Volumes/SPSS_Statistics_Installer