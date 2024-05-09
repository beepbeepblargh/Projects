<# EndpointManager-Backup.ps1
This Script is Intended to be paired with Task Scheduler to backup Intune policies
and settings frequently.
#>

Import-Module IntuneBackupAndRestore
Start-IntuneBackup -Path c:\users\testchris\documents