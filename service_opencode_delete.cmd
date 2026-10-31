@echo off
rem Remove the "winws-opencode" service, the watchdog task and (optionally)
rem the install folder. Requires Administrator (auto-elevates).
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
sc stop "winws-opencode" >nul 2>&1
timeout /t 2 /nobreak >nul
sc delete "winws-opencode" >nul 2>&1
schtasks /Delete /TN "zapret-opencode-watchdog" /F >nul 2>&1
taskkill /IM winws.exe /F >nul 2>&1
echo Service and watchdog removed.
echo.
set /p "DEL=Also delete the install folder (C:\zapret-opencode)? [y/N] "
if /i "%DEL%"=="y" (
  rmdir /S /Q "C:\zapret-opencode"
  echo Folder deleted. Note: this script lived there too - nothing remains.
) else (
  echo Folder kept. Remove it manually later if you want.
)
