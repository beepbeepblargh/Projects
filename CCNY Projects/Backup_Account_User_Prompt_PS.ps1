$Backup = Read-Host -Prompt "What is the folder name you're trying to make in csbackups?"
#Places foldername in a variable
$User = Read-Host -Prompt "What is the username of account you want to back up?"
#Places user's username in a variable
New-PSDrive -Name "CSBackups" -PSProvider "FileSystem" -Root "\\134.74.74.29\Csbackups\"
New-Item -ItemType directory -Path \\134.74.74.29\csbackups\$Backup
