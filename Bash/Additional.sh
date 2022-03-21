#!/bin/sh

# Written by Chris Ng

sudo /usr/sbin/softwareupdate --ignore "macOS Catalina"
sudo dseditgroup -o edit -n /Local/Default -a everyone -t group lpadmin
sudo networksetup -setairportpower en1 off
# This script will switch Display Login settings from List of Users to Name and Password
sudo defaults write /Library/Preferences/com.apple.loginwindow SHOWFULLNAME -bool true

echo "MacOS Catalina will no longer show up and all users can change print settings"


