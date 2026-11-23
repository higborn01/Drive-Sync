# drive-sync

Keeps one folder (by default `Grad School`) the same in OneDrive and Google Drive, both ways, once a day. It runs on GitHub Actions, so no computer has to be on. It's a thin, safe wrapper around [rclone bisync](https://rclone.org/bisync/) (MIT licensed).

## What it does

- Adds, edits and deletes on either side are copied to the other side each day at 3 AM Eastern.
- If the same file changed on both sides, the newer one wins and the older one is kept as `name.conflict1`.
- Anything a sync overwrites or deletes is moved to a `drive-sync backups` folder on that drive, so nothing is lost.
- A run stops instead of acting if it would delete more than 25 files, or if either folder looks missing.
- Native Google Docs, Sheets and Slides are skipped (they have no file to copy to OneDrive).
- File names never appear in the GitHub log. Each run's log is saved to `drive-sync logs` in OneDrive. GitHub emails you if a run fails.

## Setup (once)

1. **Sign in to both drives with rclone, on any computer.** Install rclone (`winget install Rclone.Rclone` on Windows), then run `rclone config` and add two remotes. Each opens a browser to sign in.
   - `n` → name `onedrive` → storage `onedrive` → accept defaults → pick **OneDrive Personal**.
   - `n` → name `gdrive` → storage `drive` → accept defaults → scope `1` (full access).
2. **Give GitHub the sign-in.** Run `rclone config file` to see where the config is, open that file, and copy all of it. In this repo go to **Settings → Secrets and variables → Actions → New repository secret**, name it `RCLONE_CONF`, and paste. It is encrypted and never shown in logs. Never commit that file.
3. **Do the first sync.** Go to **Actions → Sync drives → Run workflow**. Tick *First run* and *Dry run* to preview (the result is in the OneDrive log), then run again with only *First run* ticked. The first run copies everything that is missing on either side and deletes nothing. It also adds a small `RCLONE_TEST` file to both folders, which later runs use to check both sides are there.

After that it runs by itself every day.

## Keeping it running

- **Sign-in expiry:** rclone refreshes its sign-ins as it runs, but on GitHub the refreshed copy is thrown away, so the stored one can expire (Microsoft sign-ins can lapse after about 90 days). If a run fails with an auth error, redo steps 1 and 2. To avoid that, add a second secret `GH_PAT`: a [fine-grained token](https://github.com/settings/personal-access-tokens/new) for this repo only, with **Secrets: Read and write**. The workflow then saves the refreshed sign-in back to `RCLONE_CONF` each run.
- **Keep the repo private.** On public repos GitHub turns off scheduled workflows after 60 days with no commits. A daily run uses about 30 minutes of the 2,000 free private-repo minutes a month.
- If a run stops because of too many deletes, run it with *Dry run* to see why. If the deletes are what you meant, raise `MAX_DELETE` in `.github/workflows/sync.yml`.
- If rclone says a resync is needed, run it again with *First run* ticked. That only adds, never deletes.
- Stop syncing: **Actions → Sync drives → ⋯ → Disable workflow**.

## Files

| File | Purpose |
|---|---|
| `.github/workflows/sync.yml` | Daily schedule, rclone install, sign-in handling |
| `scripts/sync.sh` | Runs rclone bisync with safe defaults; settings at the top |
