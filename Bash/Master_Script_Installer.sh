#!/bin/sh

# Written by Chris Ng
# This script will install all settings and programs below via Terminal.

sudo chmod +x ~/Desktop/Bash/*
sudo ./Sleep_Settings_Test1.sh
sudo ./Rename_Mac.sh
sudo ./Additional.sh
sudo ./Screen_Sharing_Enabled.sh
sudo ./Firefox_installer.sh
sudo ./Chrome_Installer.sh
sudo ./install.sh -i
sudo sh product_deployment.sh TP WC
sudo ./Enable_Firewall.sh
sudo ./Ivanti_Landesk_Installer.sh
sudo ./Mac_OS_X_PKG_install_script.sh
sudo ./Security_Updates.sh

echo "Script Execution Has Completed"

read -p "Do you want to restart the computer? (Y/N):" CONFIRM
if [ $CONFIRM == "Y" ]
then
	sudo shutdown -r now
else
	echo "Please Restart Computer At Your Earliest Convenience"
	exit 1;
fi

exit 0