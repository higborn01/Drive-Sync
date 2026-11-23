<#
.SYNOPSIS
  Two-way sync of one folder between OneDrive and Google Drive using rclone bisync.

.PARAMETER FirstRun
  Set up both sides and do the initial merge (--resync). Run this once.
  Nothing is deleted on a first run; files on either side are copied to the other.

.PARAMETER DryRun
  Show what would change without changing anything.
#>
param(
    [switch]$FirstRun,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $here "config.ps1")

if (-not (Get-Command rclone -ErrorAction SilentlyContinue)) {
    Write-Error "rclone is not installed or not on PATH. Install it with: winget install Rclone.Rclone"
}

$logDir = Join-Path $here "logs"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
$logFile = Join-Path $logDir ("sync-{0}.log" -f (Get-Date -Format "yyyy-MM"))

$path1 = "${OneDriveRemote}:${OneDrivePath}"
$path2 = "${GDriveRemote}:${GDrivePath}"

if ($FirstRun -and -not $DryRun) {
    # Make sure both folders and their access-check files exist.
    rclone mkdir $path1
    rclone mkdir $path2
    rclone touch "$path1/RCLONE_TEST"
    rclone touch "$path2/RCLONE_TEST"
}

$rcArgs = @(
    "bisync", $path1, $path2,
    "--check-access",                 # stop if either side looks missing or unmounted
    "--resilient", "--recover",       # recover from interrupted runs without a full resync
    "--max-lock", "2h",
    "--compare", "size,modtime",      # OneDrive and Google Drive use different hashes
    "--conflict-resolve", "newer",    # keep the newer edit...
    "--conflict-loser", "num",        # ...and keep the older one as "name.conflict1"
    "--create-empty-src-dirs",
    "--drive-skip-gdocs",             # leave native Google Docs/Sheets/Slides alone
    "--max-delete", "$MaxDelete",
    "--backup-dir1", "${OneDriveRemote}:${OneDriveBackup}",
    "--backup-dir2", "${GDriveRemote}:${GDriveBackup}",
    "--log-level", "INFO"
)
if ($FirstRun) { $rcArgs += "--resync" }
if ($FirstRun -and $DryRun) {
    # The access-check files are only created on the real first run.
    $rcArgs = $rcArgs | Where-Object { $_ -ne "--check-access" }
}
if ($DryRun)   { $rcArgs += "--dry-run" } else { $rcArgs += @("--log-file", $logFile) }

Write-Host ("rclone " + ($rcArgs -join " "))
& rclone @rcArgs
$code = $LASTEXITCODE

if ($code -ne 0) {
    Write-Warning "rclone exited with code $code. See $logFile"
}
exit $code
