#!/bin/bash
# Device_HostName_Rename_v.1.0.sh
# Written by Chris Ng

# Gather device name
devicename="hostname"
# Define the log file location
LOG_FILE="/var/log/hostname.log"

# Check if the dmidecode command is available
if ! command -v dmidecode &> /dev/null
then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - dmidecode command not found, cannot retrieve serial number" | sudo tee -a "$LOG_FILE"
    exit 1
fi

# Retrieve the serial number of the machine
FULL_SERIAL_NUMBER=$(sudo dmidecode -s system-serial-number)

if [ "$devicename" != "BW-$SERIAL_NUMBER" ]; then
	# Set the hostname
	sudo hostnamectl set-hostname "BW-$SERIAL_NUMBER"
	echo "Device name changed to BW-$SERIAL_NUMBER"
fi

# Log the outcome
if [ $? -eq 0 ]; then
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Successfully changed hostname to LT-$SERIAL_NUMBER" | sudo tee -a "$LOG_FILE"
else
    echo "$(date "+%Y-%m-%d %H:%M:%S") - Failed to change hostname" | sudo tee -a "$LOG_FILE"
fi