#!/usr/bin/env bash
# Two-way sync of one folder between OneDrive and Google Drive with rclone bisync.
# Settings come from environment variables set in .github/workflows/sync.yml.
# Output goes to a log file that is saved to OneDrive, not to the public Actions log,
# so file names never show up on GitHub.
set -euo pipefail

: "${ONEDRIVE_REMOTE:=onedrive}"
: "${GDRIVE_REMOTE:=gdrive}"
: "${ONEDRIVE_PATH:=Grad School}"
: "${GDRIVE_PATH:=Grad School}"
: "${BACKUP_PATH:=drive-sync backups}"   # on each drive; outside the synced folder
: "${STATE_PATH:=drive-sync state}"      # on OneDrive; bisync's memory between runs
: "${LOG_PATH:=drive-sync logs}"         # on OneDrive
: "${MAX_DELETE:=25}"
: "${FIRST_RUN:=false}"
: "${DRY_RUN:=false}"

P1="${ONEDRIVE_REMOTE}:${ONEDRIVE_PATH}"
P2="${GDRIVE_REMOTE}:${GDRIVE_PATH}"
STATE="${ONEDRIVE_REMOTE}:${STATE_PATH}"
WORKDIR="${RUNNER_TEMP:-/tmp}/bisync-state"
LOG="${RUNNER_TEMP:-/tmp}/sync-$(date -u +%Y-%m-%dT%H%MZ).log"
mkdir -p "$WORKDIR"

# Restore bisync's state from the last run (missing on the very first run).
rclone copy "$STATE" "$WORKDIR" -q 2>/dev/null || true

if [[ "$FIRST_RUN" == "true" && "$DRY_RUN" != "true" ]]; then
  rclone mkdir "$P1" -q
  rclone mkdir "$P2" -q
  rclone touch "$P1/RCLONE_TEST" -q
  rclone touch "$P2/RCLONE_TEST" -q
fi

args=(
  bisync "$P1" "$P2"
  --workdir "$WORKDIR"
  --check-access                    # stop if either folder looks missing
  --resilient --recover             # recover from interrupted runs
  --max-lock 2h
  --compare size,modtime            # the two drives use different hashes
  --conflict-resolve newer          # keep the newer edit...
  --conflict-loser num              # ...and keep the older one as name.conflict1
  --create-empty-src-dirs
  --drive-skip-gdocs                # leave native Google Docs/Sheets/Slides alone
  --max-delete "$MAX_DELETE"
  --backup-dir1 "${ONEDRIVE_REMOTE}:${BACKUP_PATH}"
  --backup-dir2 "${GDRIVE_REMOTE}:${BACKUP_PATH}"
  --log-file "$LOG" --log-level INFO
)
if [[ "$FIRST_RUN" == "true" ]]; then
  args+=(--resync)
  # The access-check files only exist after a real first run.
  if [[ "$DRY_RUN" == "true" ]]; then
    kept=(); for a in "${args[@]}"; do [[ "$a" == "--check-access" ]] || kept+=("$a"); done
    args=("${kept[@]}")
  fi
fi
[[ "$DRY_RUN" == "true" ]] && args+=(--dry-run)

set +e
rclone "${args[@]}"
code=$?
set -e

if [[ "$DRY_RUN" != "true" ]]; then
  rclone copy "$WORKDIR" "$STATE" -q
fi
rclone copy "$LOG" "${ONEDRIVE_REMOTE}:${LOG_PATH}" -q || true

if [[ $code -eq 0 ]]; then
  echo "Sync finished. Log saved to OneDrive: ${LOG_PATH}/$(basename "$LOG")"
else
  echo "Sync failed (rclone exit code $code). Log saved to OneDrive: ${LOG_PATH}/$(basename "$LOG")"
fi
exit $code
