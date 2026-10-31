@echo off
rem Install zapret (winws) as an auto-start Windows service "winws-opencode".
rem Strategy: fake,fakedsplit + badseq for TLS, fake for QUIC - the one proven
rem against the post-quantum ClientHello drop (issue #60399 discussion).
rem Run this from the install dir (contains winws.exe + files\).
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

set "BIN=%~dp0winws.exe"
set "LIST=%~dp0files\list-opencode.txt"
set "QUIC=%~dp0files\quic_initial_www_google_com.bin"

if not exist "%BIN%" (
  echo ERROR: winws.exe not found next to this script.
  echo Run install.cmd first or copy this script into the zapret-winws folder.
  pause
  exit /b 1
)
if not exist "%LIST%" (
  echo ERROR: files\list-opencode.txt not found.
  pause
  exit /b 1
)

rem If a manually-started winws.exe is running, stop it to avoid two
rem WinDivert filters fighting each other.
sc query "winws-opencode" | findstr /C:"RUNNING" >nul
if %errorlevel% equ 0 goto :already
taskkill /IM winws.exe /F >nul 2>&1

:already
rem (Re)create the service - idempotent, safe to run repeatedly
sc stop "winws-opencode" >nul 2>&1
sc delete "winws-opencode" >nul 2>&1
timeout /t 2 /nobreak >nul

sc create "winws-opencode" binPath= "\"%BIN%\" --wf-tcp=80,443 --wf-udp=443 --filter-tcp=443 --hostlist=\"%LIST%\" --dpi-desync=fake,fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=6 --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new --filter-udp=443 --filter-l7=quic --hostlist=\"%LIST%\" --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic=\"%QUIC%\"" DisplayName= "zapret DPI bypass: opencode" start= auto
sc description "winws-opencode" "DPI-bypass (zapret) for opencode.ai / models.dev / npmjs"
sc start "winws-opencode"
timeout /t 3 /nobreak >nul
sc query "winws-opencode"
echo.
echo Done. Service "winws-opencode" installed and started (start type: auto).
pause
