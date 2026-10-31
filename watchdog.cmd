@echo off
rem Watchdog: if the winws-opencode service is not RUNNING, start it.
rem Runs every 5 minutes as SYSTEM via scheduled task "zapret-opencode-watchdog".
sc query "winws-opencode" | findstr /C:"RUNNING" >nul
if %errorlevel% neq 0 (
  sc start "winws-opencode" >nul 2>&1
)
exit /b 0
