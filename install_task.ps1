# Registers a Windows scheduled task that runs run_sync.bat every $IntervalMinutes minutes.
# Run once after the first sync has worked. Remove with:
#   Unregister-ScheduledTask -TaskName "drive-sync" -Confirm:$false

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here "config.ps1")

$action  = New-ScheduledTaskAction -Execute (Join-Path $here "run_sync.bat") -WorkingDirectory $here
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) `
           -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopIfGoingOnBatteries `
            -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 2)

Register-ScheduledTask -TaskName "drive-sync" -Action $action -Trigger $trigger `
    -Settings $settings -Description "Two-way sync OneDrive <-> Google Drive (rclone bisync)" -Force | Out-Null

Write-Host "Scheduled task 'drive-sync' runs every $IntervalMinutes minutes."
