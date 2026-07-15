@echo off
REM ===== Mission Control - local server launcher (Windows) =====
REM Double-click from inside the project folder. Serves it at
REM http://localhost:8000 and opens the dashboard. Leave the
REM window open while using it; close it to stop the server.
cd /d "%~dp0"
echo.
echo  Serving %cd%
echo  Dashboard: http://localhost:8000/dashboard.html
echo  (Leave this window open. Close it to stop the server.)
echo.
start "" "http://localhost:8000/dashboard.html"
where py >nul 2>nul
if %errorlevel%==0 ( py -m http.server 8000 ) else ( python -m http.server 8000 )
