#!/bin/bash

# Written by Chris Ng
# This script will install all settings and programs below via Terminal.
echo "Please make sure you have a network connection, preferably wired."
Current_Directory=`pwd`
if [ $Current_Directory != ~/Desktop/Install ]; then
	mv $Current_Directory ~/Desktop/Install
	echo "Renamed Folder to Install"
else
	pwd
	echo "You are using the correct pathname. Excellent."
fi
sudo chmod +x ~/Desktop/Install/*

# Rename_Mac: General Renaming of Mac and adding it to the domain. Note that it does not add it to the correct OU...yet
function Rename_Mac {
	read -p "What is the name of this computer? " ComputerName 

	#Set New Computer Name
	echo $ComputerName
	sudo scutil --set HostName $ComputerName
	sudo scutil --set LocalHostName $ComputerName
	sudo scutil --set ComputerName $ComputerName

	echo "Rename Successful"

	#If You Don't Want to Join to Domain, Quit (Work in Progress)
	read -p "Do you want to add to the domain? (Y/N):" CONFIRMATION
	if [ $CONFIRMATION != "Y" ]; then
		echo "Machine does not need to be on domain, Closing..."
	elif [ $CONFIRMATION == "Y" ]; then
		#Join Computer to Domain
		ComputerID=$( scutil --get ComputerName )
		sudo dsconfigad -add itcs.ccny.lan -computer $ComputerID -username "helpdeskservice" -password "uruRIIu3oew7AjxazCBd" 
		sudo dsconfigad -groups "domain admins,enterprise admins,AllComputerAdmins,It_clientservices_admin" 
		echo "Computer joined to ITCS, please Confirm."
	fi
}

# Rename_Macbook: Renames macbook but DOES NOT add it to domain
function Rename_Macbook {
	read -p "What is the name of this computer? " ComputerName 

	#Set New Computer Name
	echo $ComputerName
	sudo scutil --set HostName $ComputerName
	sudo scutil --set LocalHostName $ComputerName
	sudo scutil --set ComputerName $ComputerName

	echo "Rename Successful"
}

# General Power Settings and various other System Preference things
function Sleep_Settings {
	# Close any open System Preferences panes, to prevent them from overriding

	# settings we’re about to change
	osascript -e 'tell application "System Preferences" to quit'
	# Ask for the administrator password upfront
	sudo -v
	# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
	###############################################################################
	
	# Trackpad, mouse, keyboard, Bluetooth accessories, and input #

	###############################################################################
	# Increase sound quality for Bluetooth headphones/headsets
	defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
	# Enable full keyboard access for all controls
	# (e.g. enable Tab in modal dialogs)
	defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
	# Set language and text formats
	# Note: if you’re in the US, replace `EUR` with `USD`, `Centimeters` with
	# `Inches`, `en_GB` with `en_US`, and `true` with `false`.
	defaults write NSGlobalDomain AppleLanguages -array "en" "nl"
	defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
	defaults write NSGlobalDomain AppleMeasurementUnits -string "inches"
	defaults write NSGlobalDomain AppleMetricUnits -bool false
	# Show language menu in the top right corner of the boot screen
	sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

	# Set the timezone; see `sudo systemsetup -listtimezones` for other values
	sudo systemsetup -settimezone "America/New_York" > /dev/null
	###############################################################################

	# Energy saving #

	###############################################################################
	# Enable lid wakeup

	sudo pmset -a lidwake 1
	# Restart automatically on power loss
	sudo pmset -a autorestart 1
	# Restart automatically if the computer freezes
	sudo systemsetup -setrestartfreeze on
	# Never Sleep the Display
	sudo pmset -a displaysleep 0
	# Disable machine sleep while charging
	sudo pmset -c sleep 0
	# Set machine sleep to 5 minutes on battery
	sudo pmset -b sleep 5
	# Set standby delay to 24 hours (default is 1 hour)
	sudo pmset -a standbydelay 86400
	# Never go into computer sleep mode
	sudo systemsetup -setcomputersleep Off > /dev/null
	# Hibernation mode
	# 0: Disable hibernation (speeds up entering sleep mode)
	# 3: Copy RAM to disk so the system state can still be restored in case of a
	# power failure.
	sudo pmset -a hibernatemode 0
	sudo pmset repeat wakeorpoweron MTWRFSU 0:00:00
	sudo pmset -a powernap 1
	sudo pmset -a womp 1
	sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0
}

# Macbook Specific Power Settings
function Sleep_Settings_Macbook {
	# Close any open System Preferences panes, to prevent them from overriding

	# settings we’re about to change
	osascript -e 'tell application "System Preferences" to quit'
	# Ask for the administrator password upfront
	sudo -v
	# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
	while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
	###############################################################################
	
	# Trackpad, mouse, keyboard, Bluetooth accessories, and input #

	###############################################################################
	# Increase sound quality for Bluetooth headphones/headsets
	defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
	# Enable full keyboard access for all controls
	# (e.g. enable Tab in modal dialogs)
	defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
	# Set language and text formats
	# Note: if you’re in the US, replace `EUR` with `USD`, `Centimeters` with
	# `Inches`, `en_GB` with `en_US`, and `true` with `false`.
	defaults write NSGlobalDomain AppleLanguages -array "en" "nl"
	defaults write NSGlobalDomain AppleLocale -string "en_US@currency=USD"
	defaults write NSGlobalDomain AppleMeasurementUnits -string "inches"
	defaults write NSGlobalDomain AppleMetricUnits -bool false
	# Show language menu in the top right corner of the boot screen
	sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

	# Set the timezone; see `sudo systemsetup -listtimezones` for other values
	sudo systemsetup -settimezone "America/New_York" > /dev/null
	###############################################################################

	# Energy saving #

	###############################################################################
	# Enable lid wakeup

	sudo pmset -a lidwake 1
	# Restart automatically on power loss
	sudo pmset -a autorestart 1
	# Restart automatically if the computer freezes
	sudo systemsetup -setrestartfreeze on
	# Never Sleep the Display
	sudo pmset -a displaysleep 0
	# Disable machine sleep while charging
	sudo pmset -c sleep 0
	# Set machine sleep to 10 minutes on battery
	sudo pmset -b sleep 10
	# Set standby delay to 24 hours (default is 1 hour)
	sudo pmset -a standbydelay 86400
	# Never go into computer sleep mode
	sudo systemsetup -setcomputersleep Off > /dev/null
	# Hibernation mode
	# 0: Disable hibernation (speeds up entering sleep mode)
	# 3: Copy RAM to disk so the system state can still be restored in case of a
	# power failure.
	sudo pmset -a hibernatemode 3
	sudo pmset -a powernap 0
	sudo pmset -a womp 1
	sudo defaults write /Library/Preferences/com.apple.screensaver loginWindowIdleTime 0
}
# Additional: Disables software update message, wifi adapter, and enables all access to printer changes.
function Additional {
	sudo /usr/sbin/softwareupdate --ignore "macOS Catalina"
	sudo /usr/sbin/softwareupdate --ignore "macOS Big Sur"
	sudo dseditgroup -o edit -n /Local/Default -a everyone -t group lpadmin
	sudo networksetup -setairportpower en1 off
	# This script will switch Display Login settings from List of Users to Name and Password
	sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true

	echo "MacOS Catalina will no longer show up and all users can change print settings"
}

# Additional_Macbook: Additional script but for macbooks.
function Additional_Macbook {
	sudo /usr/sbin/softwareupdate --ignore "macOS Catalina"
	sudo /usr/sbin/softwareupdate --ignore "macOS Big Sur"
	sudo dseditgroup -o edit -n /Local/Default -a everyone -t group lpadmin
	# This script will switch Display Login settings from List of Users to Name and Password
	sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool false

	echo "MacOS Catalina will no longer show up and all users can change print settings"
}

# Screen_Sharing_Enabled
function Screen_Sharing_Enabled {
	#This script will enable Screen Sharing and Remote Login

	sudo systemsetup -setremotelogin on
	sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -configure -access -off
	sudo defaults write /var/db/launch.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false
	/System/Library/LaunchDaemons/com.apple.screensharing.plist: Service is disabled
	sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist

	Echo "Ignore the lack of checkmark next to Screen Sharing"

}


# Chrome_Installer: Installs Chrome if you have a network connection.
function Chrome_Installer {
	pkgfile="GoogleChrome.pkg"
	logfile="/Library/Logs/GoogleChromeInstallScript.log"
	url='https://dl.google.com/chrome/mac/stable/gcem/GoogleChrome.pkg'

	/bin/echo "--" >> ${logfile}
	/bin/echo "`date`: Downloading latest version." >> ${logfile}
	/usr/bin/curl -s -o /tmp/${pkgfile} ${url}
	/bin/echo "`date`: Installing..." >> ${logfile}
	cd /tmp
	/usr/sbin/installer -pkg GoogleChrome.pkg -target /
	/bin/sleep 5
	/bin/echo "`date`: Deleting package installer." >> ${logfile}
	/bin/rm /tmp/"${pkgfile}"

}

#VLC_Player: Downloads and installs VLC player
function VLC_Player {
	temp=$TMPDIR$(uuidgen)

	mkdir -p $temp/mount

	vlcVersion=`expr "$(curl "get.videolan.org/vlc/last/macosx/")" : '.*\(vlc-.*.dmg\)'`

	curl -L get.videolan.org/vlc/last/macosx/$vlcVersion > $temp/vlc.dmg

	yes | hdiutil attach -noverify -nobrowse -mountpoint $temp/mount $temp/vlc.dmg

	cp -r $temp/mount/*.app /Applications

	hdiutil detach $temp/mount

	rm -r $temp
}

# Mcafee_Message: Tells you to manually install Mcafee via EPO.
function Mcafee_Message {
	echo "Install Mcafee Endpoint via EPO. Please make sure to enable necessary files via Full Disk Access"
	open 'x-apple.systempreferences:com.apple.preference.security?Privacy'
}

#Enable_Firewall: Enables Mac firewall instead of Mcafee
function Enable_Firewall {
	# enable firewall
	sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1

	# unload alf
	sudo launchctl unload /System/Library/LaunchDaemons/com.apple.alf.useragent.plist
	sudo launchctl unload /System/Library/LaunchDaemons/com.apple.alf.agent.plist

	# load alf
	sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist
	sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.useragent.plist

}

# Mac_OS_X_PKG_Install: installs all pkg files located in Install
function Mac_OS_X_PKG_Install {
	# Reads pkg files in the specified directory, ~/Desktop/Install, and runs through each one. 
	# Make sure you are on Helpdesk and that all pkg files are in the Install folder on the #desktop.
	# Script does NOT include VLC Player, Bomgar, McAfee, Ivanti/Landesk, VIA, Zoom, or Cisco Anyconnect)

	while read PKG; do
		installer -pkg "$PKG" -tgt / -verbose
	done < <(find ~/Desktop/Install -name *.pkg -o -name *.mpkg)
}

#Security_Updates: Installs necessary security updates but NOT OS upgrades.
function Security_Updates {
	sudo softwareupdate -l
	sudo softwareupdate -i -a -R

	echo "Updates are now complete. Computer May Restart."
}

OLDIFS=$IFS

IFS='.' read osvers_major osvers_minor osvers_dot_version <<< "$(/usr/bin/sw_vers -productVersion)"

# restore IFS to previous state

IFS=$OLDIFS

# Check to see if the Mac is reporting itself as running macOS 11

  if [[ ${osvers_major} -ge 11 ]]; then

    # Check to see if the Mac needs Rosetta installed by testing the processor

    processor=$(/usr/sbin/sysctl -n machdep.cpu.brand_string | grep -o "Intel")
  
    if [[ -n "$processor" ]]; then
      echo "$processor processor installed. No need to install Rosetta."
    else

    # Check Rosetta LaunchDaemon. If no LaunchDaemon is found,
    # perform a non-interactive install of Rosetta.
    
      if [[ ! -f "/Library/Apple/System/Library/LaunchDaemons/com.apple.oahd.plist" ]]; then
          /usr/sbin/softwareupdate --install-rosetta --agree-to-license
       
          if [[ $? -eq 0 ]]; then
        	 echo "Rosetta has been successfully installed."
          else
        	 echo "Rosetta installation failed!"
        	 exitcode=1
          fi
   
      else
    	 echo "Rosetta is already installed. Nothing to do."
      fi
    fi
  else
    echo "Mac is running macOS $osvers_major.$osvers_minor.$osvers_dot_version."
    echo "No need to install Rosetta on this version of macOS."
  fi

# Checks type of device and executes script based on type of device.
model=`sysctl -n hw.model`
modelno=`echo "$model"`
if [[ $modelno =~ "iMac" ]]; then
	echo "iMac detected"
	Rename_Mac
	Sleep_Settings
	Additional
	Screen_Sharing_Enabled
	Silicon_Rosetta
	sudo ./Firefox_installer
	Chrome_Installer
	VLC_Player
	sudo ./install.sh -i
	Mcafee_Message
	Enable_Firewall
	sudo ./Ivanti_Landesk_Installer
	Mac_OS_X_PKG_Install
	Security_Updates


elif [[ $modelno =~ "MacBook" ]]; then
	echo "Macbook Detected"
	Rename_Macbook
	Sleep_Settings_Macbook
	Additional_Macbook
	Silicon_Rosetta
	sudo ./Firefox_Installer
	Chrome_Installer
	VLC_Player
	sudo ./install.sh -i
	sudo sh product_deployment.sh TP WC
	Enable_Firewall
	sudo ./Ivanti_Landesk_Installer
	Mac_OS_X_PKG_Install
	Security_Updates

else
	echo "Invalid Respond"
	exit 1
fi

echo "Script Execution Has Completed"

read -p "Do you want to restart the computer? (Y/N):" CONFIRM
if [ $CONFIRM == "Y" ]; then
	sudo shutdown -r now
else
	echo "Please Restart Computer At Your Earliest Convenience"
fi

exit 0

