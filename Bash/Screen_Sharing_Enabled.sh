#!/bin/bash

#Written by Chris Ng
#This script will enable Screen Sharing and Remote Login

sudo systemsetup -setremotelogin on
sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -deactivate -configure -access -off
sudo defaults write /var/db/launch.db/com.apple.launchd/overrides.plist com.apple.screensharing -dict Disabled -bool false
/System/Library/LaunchDaemons/com.apple.screensharing.plist: Service is disabled
sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.screensharing.plist

Echo "Ignore the lack of checkmark next to Screen Sharing"

exit 1