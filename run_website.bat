@echo off
REM ============================================================
REM  SpendWise - one-click website + ngrok tunnel launcher
REM  Starts:
REM    1. Local web server  -> http://127.0.0.1:8421
REM    2. ngrok tunnel      -> public https URL (printed below)
REM  Keep this window open while sharing the link.
REM  Close the window to stop everything.
REM ============================================================
title SpendWise Website Launcher
cd /d "C:\Users\sivap\OneDrive\Documents\Default Project"

echo [1/3] Stopping any old instances...
taskkill /f /im ngrok.exe >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8421 ^| findstr LISTENING') do taskkill /f /pid %%a >nul 2>&1

echo [2/3] Starting local web server on port 8421...
start "SpendWise Web Server" /min cmd /c "python serve_web.py"

timeout /t 3 /nobreak >nul

echo [3/3] Starting ngrok tunnel...
start "SpendWise ngrok" /min cmd /c "D:\ngrok\ngrok.exe http 8421 --log=stdout > %TEMP%\ngrok_log.txt 2>&1"

timeout /t 6 /nobreak >nul

echo.
echo ============================================================
echo   SpendWise is starting up...
echo   Local:    http://127.0.0.1:8421
echo   Public:   check the URL below (ngrok assigns a random name)
echo ============================================================
powershell -NoProfile -Command "try { (Invoke-RestMethod 'http://127.0.0.1:4040/api/tunnels').tunnels | ForEach-Object { Write-Host ('  SHARE THIS LINK: ' + $_.public_url) -ForegroundColor Green } } catch { Write-Host '  ngrok URL not ready yet - reopen this file in a few seconds' -ForegroundColor Yellow }"
echo.
echo To stop: close this window and the two minimized windows.
pause
