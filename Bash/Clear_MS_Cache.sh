#!/bin/sh
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )

# Specify the base directory path
basepath="/Users/$loggedInUser/Library"
#groupcontainers="$basepath/Group\ Containers"
preferences="$basepath/Preferences"
#appsupport="$basepath/Application\ Support/Microsoft"
# Specify the file prefix to match
#file_prefix="UBF"
#IFS=$'\n' read -r -d '' -a my_array < <( my_command && printf '\0' )
# Specify the array of directories
officeprocesses=('Microsoft Word' 'Microsoft Outlook' 'Microsoft Excel' 'Microsoft Powerpoint' 'Microsoft Teams')
#directories=('$basepath/Group Containers\UBF*' '/$basepath/Application Support/Microsoft')
directories=$(ls -d $basepath/Group\ Containers/UBF8T346G9*) #or directories=$(ls -d $Users/$loggedinUser/Library/Group\ Containers/UBF8T346G9*)
# Check if the script is running with root privileges
#if [[ $EUID -ne 0 ]]; then
#    echo "This script requires root privileges. Please run as root or using sudo."
#    exit 1
#fi
for process in "${officeprocesses[@]}"; do
	pkill -9 $process
	echo "$Process is killed"
done

# Iterate through the directories and remove folders with the specified prefix
for dir in "${directories[@]}"; do
    # Check if the directory exists
    if [ -d "$dir" ]; then
        # Use find to locate and delete folders with the specified prefix
        rm -rf $dir
        echo "$dir successfully deleted."
    else
        echo "Directory not found: $dir"
    fi
done

# for the preferences directory, find com.microsoft* files, and then delete
find $preferences -type f -name 'com.microsoft*' -exec rm -rf {} \;

defaults write com.microsoft.Word ResetOneAuthCreds -bool YES