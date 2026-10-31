@echo off
setlocal EnableExtensions
rem ==============================================================
rem  zapret-opencode-bypass installer
rem
rem  Downloads bol-van/zapret-win-bundle, installs the "winws-opencode"
rem  Windows service (auto-start before logon) + a 5-min watchdog task
rem  that restarts it if it ever dies (e.g. antivirus removed it).
rem
rem  Requires Administrator - the script auto-elevates (UAC prompt).
rem ==============================================================

rem --- auto-elevate ---
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

set "DEST=C:\zapret-opencode"
set "SRCD=%~dp0"
set "ZIP=%TEMP%\zapret-win-bundle-master.zip"
set "EXT=%TEMP%\zapret-bundle-extract"
set "URL=https://codeload.github.com/bol-van/zapret-win-bundle/zip/refs/heads/master"
set "LISTBAK=%TEMP%\opencode-hostlist.bak"

echo [1/6] Downloading zapret-win-bundle from GitHub...
curl.exe -fsSL -o "%ZIP%" "%URL%"
if errorlevel 1 goto :no_download

echo [2/6] Extracting...
if exist "%EXT%" rmdir /S /Q "%EXT%"
powershell -NoProfile -Command "Expand-Archive -Force -Path '%ZIP%' -DestinationPath '%EXT%'" >nul 2>&1
if not exist "%EXT%\zapret-win-bundle-master\zapret-winws\winws.exe" goto :no_extract

echo [3/6] Stopping previous instance (if any)...
sc stop "winws-opencode" >nul 2>&1
timeout /t 2 /nobreak >nul
taskkill /IM winws.exe /F >nul 2>&1

echo [4/6] Installing to %DEST% ...
rem preserve a user-edited hostlist across reinstall
if exist "%DEST%\files\list-opencode.txt" copy /Y "%DEST%\files\list-opencode.txt" "%LISTBAK%" >nul
if exist "%DEST%" rmdir /S /Q "%DEST%"
mkdir "%DEST%"
xcopy /E /I /Y "%EXT%\zapret-win-bundle-master\zapret-winws\*" "%DEST%\" >nul
if not exist "%DEST%\winws.exe" goto :no_extract

copy /Y "%SRCD%files\list-opencode.txt" "%DEST%\files\list-opencode.txt" >nul
if exist "%LISTBAK%" (
  copy /Y "%LISTBAK%" "%DEST%\files\list-opencode.txt" >nul
  echo       Your previous hostlist was preserved.
)
copy /Y "%SRCD%service_opencode_create.cmd" "%DEST%\" >nul
copy /Y "%SRCD%service_opencode_delete.cmd" "%DEST%\" >nul
copy /Y "%SRCD%watchdog.cmd"                "%DEST%\" >nul
copy /Y "%SRCD%zapret-opencode.cmd"         "%DEST%\" >nul
copy /Y "%SRCD%zapret-opencode-stop.cmd"    "%DEST%\" >nul

echo [5/6] Installing service "winws-opencode"...
call "%DEST%\service_opencode_create.cmd"

echo [6/6] Installing watchdog task (every 5 min)...
schtasks /Create /TN "zapret-opencode-watchdog" /TR "%DEST%\watchdog.cmd" /SC MINUTE /MO 5 /RU SYSTEM /RL HIGHEST /F >nul
if errorlevel 1 (
  echo       WARNING: watchdog task was not created, service still works.
) else (
  echo       Watchdog task: OK
)

echo.
echo === Verification ===
sc query "winws-opencode" | findstr /C:"RUNNING" >nul
if errorlevel 1 (
  echo   Service: NOT RUNNING - check your antivirus / WinDivert64.sys
) else (
  echo   Service: RUNNING
)
curl.exe -s -o NUL -w "  opencode.ai: %%{http_code}\n" --connect-timeout 10 https://opencode.ai/
echo.
echo Done. Stop: zapret-opencode-stop.cmd   Remove: service_opencode_delete.cmd
pause
exit /b 0

:no_download
echo.
echo ERROR: cannot download zapret-win-bundle.
echo Check internet, or download https://github.com/bol-van/zapret-win-bundle
echo manually, copy the "zapret-winws" folder to %DEST% and run
echo service_opencode_create.cmd from there.
pause
exit /b 1

:no_extract
echo.
echo ERROR: archive extracted but winws.exe not found - corrupted download?
echo Retry, or install manually per README.md.
pause
exit /b 1
