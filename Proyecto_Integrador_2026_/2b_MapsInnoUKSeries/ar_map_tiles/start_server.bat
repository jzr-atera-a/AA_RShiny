@echo off
echo ================================================
echo HTTPS Server for AR Map Viewer
echo ================================================
echo.

if not exist "cert.pem" (
    echo ERROR: cert.pem not found!
    echo Run generate_certs.bat first
    pause
    exit /b 1
)

if not exist "key.pem" (
    echo ERROR: key.pem not found!
    echo Run generate_certs.bat first
    pause
    exit /b 1
)

where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Python not found!
    echo Install Python 3.7+ from python.org
    pause
    exit /b 1
)

echo Starting server...
python https_server.py

pause
