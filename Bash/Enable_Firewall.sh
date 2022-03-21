#!/bin/sh

## Description
# This is an example to always enforce the Application layer Firewall on startup

# enable firewall
sudo defaults write /Library/Preferences/com.apple.alf globalstate -int 1

# unload alf
sudo launchctl unload /System/Library/LaunchDaemons/com.apple.alf.useragent.plist
sudo launchctl unload /System/Library/LaunchDaemons/com.apple.alf.agent.plist

# load alf
sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.agent.plist
sudo launchctl load /System/Library/LaunchDaemons/com.apple.alf.useragent.plist

exit 0