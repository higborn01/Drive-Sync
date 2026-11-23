# drive-sync

Keeps one folder (by default `Grad School`) the same in OneDrive and Google Drive, both ways, on a schedule. It is a thin, safe wrapper around [rclone bisync](https://rclone.org/bisync/) (MIT licensed) for Windows Task Scheduler.

## What it does

- Adds, edits and deletes on either side are copied to the other side each run.
- If the same file changed on both sides, the newer one wins and the older one is kept as `name.conflict1`.
- Anything a sync overwrites or deletes is moved to a `drive-sync backups` folder on that drive, so nothing is lost.
- A run stops instead of acting if it would delete more than 25 files, or if either folder looks missing.
- Native Google Docs, Sheets and Slides are skipped (they have no file to copy to OneDrive).

## Setup (once)

1. **Install rclone 1.66 or newer**
   ```
   winget install Rclone.Rclone
   ```
2. **Connect your two drives.** Run `rclone config` and add two remotes. Each opens a browser to sign in.
   - `n` → name `onedrive` → storage `onedrive` → accept defaults → pick **OneDrive Personal**.
   - `n` → name `gdrive` → storage `drive` → accept defaults → scope `1` (full access).

   Your sign-in tokens are stored in rclone's own config file on your PC, never in this repo.
3. **Check the settings** in `config.ps1` (folder names, remote names, how often it runs).
4. **Preview, then do the first sync**
   ```
   run_sync.bat -FirstRun -DryRun
   run_sync.bat -FirstRun
   ```
   The first run copies everything that is missing on either side and deletes nothing. It also adds a small `RCLONE_TEST` file to both folders, which later runs use to check both sides are there.
5. **Schedule it**
   ```
   powershell -ExecutionPolicy Bypass -File install_task.ps1
   ```

## Day to day

- Logs: `logs\sync-YYYY-MM.log`.
- Run by hand any time: `run_sync.bat` (add `-DryRun` to preview).
- If a run stops because of too many deletes, preview with `run_sync.bat -DryRun`, and if it's what you meant, run `rclone bisync ... --force` once or raise `MaxDelete`.
- If rclone says a resync is needed, run `run_sync.bat -FirstRun` again. It only adds, never deletes.
- Stop syncing: `Unregister-ScheduledTask -TaskName "drive-sync" -Confirm:$false`.

## Files

| File | Purpose |
|---|---|
| `config.ps1` | Remote names, folders, delete limit, schedule |
| `sync.ps1` | Runs rclone bisync with safe defaults |
| `run_sync.bat` | Double-click or Task Scheduler entry point |
| `install_task.ps1` | Registers the scheduled task |
