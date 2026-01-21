#!/bin/bash
echo "================================================"
echo "Installing paho-mqtt for Python"
echo "================================================"
echo ""

echo "Checking Python installation..."
python3 --version
echo ""

echo "Installing paho-mqtt..."
python3 -m pip install paho-mqtt
echo ""

echo "Verifying installation..."
python3 -c "import paho.mqtt.client; print('SUCCESS: paho-mqtt is installed!')"
echo ""

echo "================================================"
echo "Installation complete!"
echo "================================================"
