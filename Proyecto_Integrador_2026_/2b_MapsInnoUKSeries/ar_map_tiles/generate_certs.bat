@echo off
echo ================================================
echo SSL Certificate Generator
echo ================================================
echo.

where openssl >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: OpenSSL not found!
    echo Install Git for Windows or WSL
    pause
    exit /b 1
)

echo Generating certificate for 192.168.100.14...
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=192.168.100.14"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo SUCCESS! Certificates generated.
    echo Next: Run start_server.bat
) else (
    echo ERROR: Generation failed!
)

pause
