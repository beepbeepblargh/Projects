#!/bin/bash

# Written by Chris Ng

# ~/.macos — https://mths.be/macos



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

