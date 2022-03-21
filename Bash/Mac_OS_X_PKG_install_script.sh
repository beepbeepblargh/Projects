#!/bin/sh

# Reads pkg files in the specified directory, ~/Desktop/Install, and runs through each one. 
# Make sure you are on Helpdesk and that all pkg files are in the Install folder on the #desktop.
# Script does NOT include VLC Player, Bomgar, McAfee, Ivanti/Landesk, VIA, Zoom, or Cisco Anyconnect)

while read PKG; do
	installer -pkg "$PKG" -tgt / -verbose
done < <(find /Users/helpdesk/Desktop/Install -name *.pkg -o -name *.mpkg)

#Written by Chris Ng