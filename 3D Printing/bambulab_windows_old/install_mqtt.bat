@echo off
echo ================================================
echo Installing paho-mqtt for Python
echo ================================================
echo.

echo Checking Python installation...
python --version
echo.

echo Installing paho-mqtt...
python -m pip install paho-mqtt
echo.

echo Verifying installation...
python -c "import paho.mqtt.client; print('SUCCESS: paho-mqtt is installed!')"
echo.

echo ================================================
echo Installation complete!
echo ================================================
pause
