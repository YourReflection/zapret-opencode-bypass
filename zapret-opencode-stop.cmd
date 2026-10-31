@echo off
rem Stop the zapret DPI-bypass for opencode (service first, then stray processes)
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
sc stop "winws-opencode" >nul 2>&1
timeout /t 2 /nobreak >nul
taskkill /IM winws.exe /F >nul 2>&1
taskkill /IM winws2.exe /F >nul 2>&1
echo zapret stopped. Start again: service_opencode_create.cmd
