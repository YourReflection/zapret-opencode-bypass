@echo off
rem Manual one-shot start (until reboot) - only if the SERVICE is not used.
rem If the service is installed (normal case), it is already running:
rem check with: sc query winws-opencode
sc query "winws-opencode" | findstr /C:"RUNNING" >nul
if %errorlevel% equ 0 (
  echo Service "winws-opencode" is already RUNNING - nothing to do.
  exit /b 0
)
start "zapret: opencode" /min "%~dp0winws.exe" --wf-tcp=80,443 --wf-udp=443 --filter-tcp=443 --hostlist="%~dp0files\list-opencode.txt" --dpi-desync=fake,fakedsplit --dpi-desync-split-pos=1 --dpi-desync-fooling=badseq --dpi-desync-repeats=6 --dpi-desync-fake-tls-mod=rnd,dupsid,sni=www.google.com --new --filter-udp=443 --filter-l7=quic --hostlist="%~dp0files\list-opencode.txt" --dpi-desync=fake --dpi-desync-repeats=11 --dpi-desync-fake-quic="%~dp0files\quic_initial_www_google_com.bin"
