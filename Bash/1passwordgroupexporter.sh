#!/bin/sh
# 1passwordgroupexporter.sh v.1.0
# Written by Chris Ng
# This script is intended to export membership lists of 1PW groups for auditing purposes.

Check_Path() {
dir_path="$( cd -- "$(dirname "$0")" </dev/null 2>&1 ; pwd -P)"
OPFolderLocation="$dir_path/1PasswordGroupExport"

echo "Checking that 1PasswordGroupExport folder exists"
if [ -d "$OPFolderLocation" ]; then
	echo "Directory already exists: $OPFolderLocation"
else
	mkdir -p "$OPFolderLocation"
	echo "Directory created: $OPFolderLocation"
fi
}

OPCheck() { 
eval $(op signin)
# Need to make conditional to check for Error. If error, Exit and inform the user to sign in first
Grouplist=$(op group list)
array1=()
array2=()
firstline=true
	while read -r var1 var2; do
		if [ "$firstline" = true ]; then
			firstline=false
			continue
		fi
		array1+=("$var1")
		array2+=("$var2")
#		group=$(echo $line | cut -f 2 -d)
#		echo $group
	done <<< "$Grouplist"
#	echo "UUID: ${array1[@]}"
#	echo "Groups:"
#	for value in "${array2[@]}"
#	do
#		echo "$value"
#	done
}

Check_Path
OPCheck
# Ask if you need to export based on user or based on group?
#read -p "Are you looking to export by user or by group? (E/g) " UserGroupChoice

read -p "Would you like to do a Full Export or Single Group Export? (F/s) " ExportOption
case "$ExportOption" in
	[Ff] )
		for OPGrouplist in "${array2[@]}"
		do 
			OPGroupListUnderScore=$(echo "$OPGrouplist" | tr ' ' '_')
			echo "Attempting to Export Group Membership of $OPGrouplist"
			op group user list "$OPGrouplist" | awk -F '\t' '{gsub(/[[:space:]][[:space:]]+/,","); print}' > $OPFolderLocation/${OPGroupListUnderScore}_$(date +%Y-%m-%d-%H_%M_%S).csv
			echo "$OPGrouplist exported. Please review $OPFolderLocation to ensure file is accurate"
		done
		;;
	[Ss] )
		echo "Groups:"
		for list in "${array2[@]}"
		do
			echo "$list"
		done
		read -p "Please type in the name of the group you want to export from above: " groupname
		OPgroupnameUnderScore=$(echo "$groupname" | tr ' ' '_')
		echo "Attempting to Export Group Membership of $groupname"
		op group user list "$groupname" | awk -F '\t' '{gsub(/[[:space:]][[:space:]]+/,","); print}' > $OPFolderLocation/${OPgroupnameUnderScore}_$(date +%Y-%m-%d-%H_%M_%S).csv
		echo "$groupname exported. Please review current directory to ensure file is accurate"
		# Also, need to get rid of spacing in the $groupname/Turn it into _
		;;
	* ) echo "Invalid Response. Please answer with F or S. Exiting script."
		;;
esac
exit