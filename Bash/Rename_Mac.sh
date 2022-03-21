#!/bin/bash

#Written by Chris Ng

ComputerName=`/usr/bin/osascript << EOT
tell application "System Events"
    activate 
    set ComputerName to text returned of (display dialog "Please Input New Computer Name" default answer "" with icon 2)
end tell
EOT`

#Set New Computer Name
echo $ComputerName
sudo scutil --set HostName $ComputerName
sudo scutil --set LocalHostName $ComputerName
sudo scutil --set ComputerName $ComputerName

echo "Rename Successful"

#If You Don't Want to Join to Domain, Quit (Work in Progress)
read -p "Do you want to add to the domain? (Y/N):" CONFIRMATION
if [ $CONFIRMATION != "Y" ]
then
	echo "Machine does not need to be on domain, Closing..."
	exit 1;
fi

#Join Computer to Domain
ComputerID=$( scutil --get ComputerName )
sudo dsconfigad -add itcs.ccny.lan -computer $ComputerID -username "helpdeskservice" -password "uruRIIu3oew7AjxazCBd" 
sudo dsconfigad -groups "domain admins,enterprise admins,AllComputerAdmins,It_clientservices_admin" 

echo "Computer joined to ITCS, please Confirm."

