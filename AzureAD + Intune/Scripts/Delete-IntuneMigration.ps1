<# Delete-IntuneMigration.ps1
This script checks if IntuneMigration folder exists
and deletes the contents except the migration logs for review.
#>
# Set the path to the folder you want to clean
$folderPath = "C:\ProgramData\IntuneMigration"

# Set the names of the items you want to keep
$itemsToKeep = @("Migration.log", "Post-Migration.log")

try {
	Write-Host "Checking if Intune Migration Folder exists"
	$folder = Test-Path -Path $folderPath
	
}
catch {
	Write-Host "Error. Unable to check for a folder path."
}

if ($($folder) -eq "True"){
	# Get all items in the folder
	$allItems = Get-ChildItem -Path $folderPath -Exclude *.log
	$allItems = $allItems.Name
	#Write-Host "$allItems"
	# Iterate through each item
	foreach ($item in $allItems) {
		# Check if the item should be kept
		#Write-Host "$item"
		Remove-Item -Path "C:\ProgramData\IntuneMigration\$item" -Force -Confirm:$false
		Write-Host "Deleted item: $($item)"
		}
	}

Write-Host "Cleanup completed. All relevant Migration files have been deleted"
