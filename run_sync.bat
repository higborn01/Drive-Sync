@echo off
REM Runs one sync. Used by Task Scheduler; safe to double-click.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync.ps1" %*
