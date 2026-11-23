# Settings for drive-sync. Edit these to match your rclone remotes and folders.
# Remote names are the names you gave them in `rclone config`.

$OneDriveRemote = "onedrive"
$GDriveRemote   = "gdrive"

# Folder to keep in sync, relative to each drive's root.
$OneDrivePath = "Grad School"
$GDrivePath   = "Grad School"

# Files that are changed or deleted by a sync are moved here instead of being lost.
# Must be outside the synced folder.
$OneDriveBackup = "drive-sync backups"
$GDriveBackup   = "drive-sync backups"

# Abort if a run would delete more than this many files on either side.
$MaxDelete = 25

# How often the scheduled task runs, in minutes.
$IntervalMinutes = 60
