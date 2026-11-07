#!/usr/bin/env python3
"""
WebSocket Server for Meta Quest 3 Robot Control
Receives commands from AR application and forwards to Arduino via serial

Port: 8444 (WebSocket Secure - WSS)
Serial: /dev/ttyACM0 (Linux) or COM3 (Windows) at 115200 baud

Commands forwarded directly:
    MOTORS:0-80     - Motor speed percentage
    SERVO1:40-140   - Gripper servo angle
    SERVO2:50-130   - Steering servo angle

Usage:
    python trajectory_websocket_server.py

Requirements:
    - Python 3.6+
    - pip install websockets pyserial
    - cert.pem and key.pem (SSL certificates)
    - Arduino connected via USB
"""

import asyncio
import websockets
import serial
import ssl
import sys
import os
import time
from datetime import datetime

# Configuration
WEBSOCKET_PORT = 8444
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'

# Serial port configuration (update for your system)
SERIAL_PORT_LINUX = '/dev/ttyACM0'  # Arduino on Linux/Jetson
SERIAL_PORT_WINDOWS = 'COM3'        # Arduino on Windows
SERIAL_BAUD = 115200
SERIAL_TIMEOUT = 1

# Global serial connection
arduino_serial = None

def detect_serial_port():
    """Auto-detect Arduino serial port"""
    import platform
    
    if platform.system() == 'Linux':
        # Try common Linux ports
        possible_ports = ['/dev/ttyACM0', '/dev/ttyACM1', '/dev/ttyUSB0', '/dev/ttyUSB1']
    elif platform.system() == 'Windows':
        # Try common Windows ports
        possible_ports = [f'COM{i}' for i in range(1, 20)]
    else:
        print("ERROR: Unsupported platform")
        return None
    
    for port in possible_ports:
        if os.path.exists(port) if platform.system() == 'Linux' else True:
            try:
                ser = serial.Serial(port, SERIAL_BAUD, timeout=SERIAL_TIMEOUT)
                ser.close()
                print(f"✓ Found Arduino on {port}")
                return port
            except (OSError, serial.SerialException):
                continue
    
    return None

def connect_arduino():
    """Establish serial connection to Arduino"""
    global arduino_serial
    
    print("\nConnecting to Arduino...")
    
    # Detect port
    port = detect_serial_port()
    if not port:
        print("ERROR: Could not find Arduino on any serial port")
        print("Please check:")
        print("  1. Arduino is connected via USB")
        print("  2. Arduino drivers are installed")
        print("  3. Port permissions (Linux: sudo usermod -a -G dialout $USER)")
        return False
    
    try:
        arduino_serial = serial.Serial(port, SERIAL_BAUD, timeout=SERIAL_TIMEOUT)
        time.sleep(2)  # Wait for Arduino reset
        
        # Clear any startup messages
        while arduino_serial.in_waiting:
            line = arduino_serial.readline().decode('utf-8', errors='ignore').strip()
            print(f"  Arduino: {line}")
        
        # Send test ping
        arduino_serial.write(b'PING\n')
        time.sleep(0.1)
        
        if arduino_serial.in_waiting:
            response = arduino_serial.readline().decode('utf-8', errors='ignore').strip()
            if 'PONG' in response:
                print(f"✓ Arduino connected successfully on {port}")
                return True
        
        print(f"✓ Arduino connected on {port} (no ping response)")
        return True
        
    except serial.SerialException as e:
        print(f"ERROR: Could not connect to Arduino: {e}")
        return False

def send_to_arduino(command):
    """Send command to Arduino via serial"""
    global arduino_serial
    
    if not arduino_serial or not arduino_serial.is_open:
        print(f"ERROR: Arduino not connected - command dropped: {command}")
        return False
    
    try:
        # Send command with newline
        arduino_serial.write(f"{command}\n".encode('utf-8'))
        
        # Log command
        timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
        print(f"[{timestamp}] Quest → Arduino: {command}")
        
        # Try to read response (non-blocking)
        time.sleep(0.01)  # Small delay for Arduino to respond
        if arduino_serial.in_waiting:
            response = arduino_serial.readline().decode('utf-8', errors='ignore').strip()
            print(f"[{timestamp}] Arduino → Quest: {response}")
        
        return True
        
    except Exception as e:
        print(f"ERROR: Failed to send command: {e}")
        return False

async def handle_websocket(websocket, path):
    """Handle WebSocket connection from Quest 3"""
    
    client_address = websocket.remote_address
    print(f"\n{'='*60}")
    print(f"Quest 3 connected from {client_address[0]}:{client_address[1]}")
    print(f"{'='*60}\n")
    
    try:
        async for message in websocket:
            # Quest sends simple string commands
            command = message.strip()
            
            # Validate command format
            if command.startswith('MOTORS:') or \
               command.startswith('SERVO1:') or \
               command.startswith('SERVO2:'):
                
                # Forward directly to Arduino
                send_to_arduino(command)
                
            else:
                print(f"WARNING: Unknown command format: {command}")
    
    except websockets.exceptions.ConnectionClosed:
        print(f"\nQuest 3 disconnected from {client_address[0]}:{client_address[1]}")
    except Exception as e:
        print(f"ERROR: WebSocket error: {e}")

async def main():
    """Start WebSocket server"""
    
    print("=" * 70)
    print("Meta Quest 3 Robot Control - WebSocket Server")
    print("=" * 70)
    
    # Check SSL certificates
    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print("\nERROR: SSL certificates not found!")
        print("Generate with:")
        print("  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes")
        sys.exit(1)
    
    # Connect to Arduino
    if not connect_arduino():
        print("\nWARNING: Starting without Arduino connection")
        print("Commands will be logged but not sent to robot\n")
    
    # Setup SSL context
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain(certfile=CERT_FILE, keyfile=KEY_FILE)
    
    # Get local IP
    import socket
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
    except:
        local_ip = "UNKNOWN"
    
    print(f"\n✓ WebSocket server starting...")
    print(f"\nServer Details:")
    print(f"  - Port: {WEBSOCKET_PORT}")
    print(f"  - Protocol: WSS (WebSocket Secure)")
    print(f"  - Local IP: {local_ip}")
    print(f"\nQuest 3 will connect to:")
    print(f"  wss://{local_ip}:{WEBSOCKET_PORT}")
    print(f"\nCommand Format:")
    print(f"  MOTORS:0-80   (motor speed percentage)")
    print(f"  SERVO1:40-140 (gripper angle)")
    print(f"  SERVO2:50-130 (steering angle)")
    print(f"\nPress Ctrl+C to stop\n")
    print("=" * 70)
    print("\nWaiting for Quest 3 connection...\n")
    
    # Start server
    async with websockets.serve(
        handle_websocket,
        "0.0.0.0",
        WEBSOCKET_PORT,
        ssl=ssl_context
    ):
        await asyncio.Future()  # Run forever

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\nShutting down server...")
        if arduino_serial and arduino_serial.is_open:
            # Send stop command before closing
            arduino_serial.write(b'MOTORS:0\n')
            arduino_serial.write(b'SERVO2:90\n')
            time.sleep(0.1)
            arduino_serial.close()
            print("Arduino connection closed.")
        print("Server stopped.")
