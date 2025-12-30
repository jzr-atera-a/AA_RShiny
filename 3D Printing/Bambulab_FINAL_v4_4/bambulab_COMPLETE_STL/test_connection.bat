@echo off
setlocal EnableDelayedExpansion
echo ================================================
echo Bambulab MQTT Connection Test
echo ================================================
echo.

set /p IP=Enter Printer IP Address: 
set /p CODE=Enter Access Code (8 digits): 
set /p SERIAL=Enter Serial Number: 

echo.
echo Testing connection to !IP!...
echo.

python test_mqtt_connection.py !IP! !CODE! !SERIAL!

echo.
echo ================================================
echo Press any key to close...
pause >nul
