#!/bin/bash

#written by Chris Ng

#This Script will ask if you need to backup or restore a folder.
#If backup, will auto backup to csbackups.
#If restore, after providing the folder name, it will automatically attempt to restore.

#Script for Mounting Share Drive Goes Here:
mountDir=$( mount | grep csbackups | awk -F' on ' '{print $2}' | awk -F' ' '{print $1}' )
if [ -z $mountDir ]; then
	echo "CSbackups was not found. Please try again"
	open smb://administrator@134.74.74.29/csbackups
	echo "Launching csbackups and exiting..."
	exit 1
fi
#Backup
read -p "Is this a Backup or Restore (Backup/Restore) " CONTEXT
if [ $CONTEXT == "Backup" ]; then
	name="$(osascript -e 'Tell application "System Events" to display dialog "Enter the folder name you would like to make in CSbackups:" default answer ""' -e 'text returned of result' 2>/dev/null)"
	if [ $? -ne 0 ]; then
    	# The user pressed Cancel
    	exit 1 # exit with an error status
	elif [ -z "$name" ]; then
    	# The user left the project name blank
    	osascript -e 'Tell application "System Events" to display alert "You must enter a folder name; cancelling..." as warning'
    	exit 1 # exit with an error status
	fi

	mkdir -p /$mountDir/$name

	read -p "What is the User’s folder name? " FOLDER
	echo "Folder is: $FOLDER"
	Username=$(find /Users -maxdepth 1 -type d -name "*$FOLDER*" -print -quit)
	sudo chown -R helpdesk $Username
	sudo rsync -av --exclude 'Applications' --exclude 'Caches' --exclude '.Trash' $Username /$mountDir/$name
	sudo chown -R $FOLDER $Username
	exit 0

#Restore
elif [ $CONTEXT == "Restore" ]; then
	echo "Preparing Restore Option"
	read -p "What is the folder name you're restoring from? " SHARE
	echo "SHARE Folder is: $SHARE"
	read -p "What is the account name (exclude ITCS)? " name
	sudo rsync -av --exclude 'Applications' --exclude 'Caches' --exclude '.Trash' /$mountDir/$SHARE/$name /Users

	read -p "Is this computer on the domain? (Y/N) " DOMAIN
	if [ $DOMAIN == "Y" ]; then
		sudo chown -R $name:"ITCS\domain users" /Users/$name
	#If not. chown -R $name /Users/$name. Maybe create account beforehand?
	# Create user; needs work because the dscl command causes a library issue. 
	elif [ $DOMAIN == "N" ]; then
		echo "Making sure the account exists locally."
		if id "$1" &>/dev/null; then
			echo "user found"
			sudo chown -R $name /Users/$name
		else
			echo "Create Local Account First and Then Try Again Later"
			sudo chown -R $name /Users/$name
		fi
	fi

	read -p "Reboot now? (Y/N) " RESTART
	if [ $RESTART == "Y" ]; then
		sudo reboot
	elif [ $RESTART == "N" ]; then
		echo "User will restart at earliest convenience"
		exit 1
	fi
	exit 0
fi
exit 0