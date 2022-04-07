#!/bin/sh
# Written by Chris Ng
# v.1.0.0- Test Install.sh script for Ubuntu/Linux.

scriptPath="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P)"
ninjaRMM="userdevices*"
ciscoAMP="amp*"
sudo apt install net-tools

#The below function for is verifying ninjarmm and Cisco AMP are within
#the Ubuntu_Install folder and Installing them after.
InstallUbuntu () {
#Ninjarmm Install
#Note that this would be more effective as a for/foreach with an array for
#the names
	if [ -f $scriptPath/$ninjaRMM ]; then
		echo "ninjarmm deb found, verifying now..."
		dpkg --get-selections | grep -s userdevices
		if [ $? -eq 0 ]; then
			echo "ninjarmm is already installed. Skipping..."
		elif [ $? -eq 1 ]; then
			ninjaPath="$(ls $scriptPath | grep $ninjaRMM)"
			echo "ninjaPath is $ninjaPath"
			echo "ninjarmm is installing now..."
			sudo dpkg -i $scriptPath/$ninjaPath
		fi
	else
		echo "ninjarmm deb file not found. Skipping..."
		exit 1
	fi
#Cisco AMP Install
	if [ -f $scriptPath/$ciscoAMP ]; then
		ampPath="$(ls $scriptPath | grep $ciscoAMP)"
		echo "Cisco amp found, installing now..."
		echo "ampPath is $ampPath"
		sudo dpkg -i $scriptPath/$ampPath
	else
		echo "Cisco amp deb file not found. Skipping..."
		exit 1
	fi
}

InstallUbuntu
