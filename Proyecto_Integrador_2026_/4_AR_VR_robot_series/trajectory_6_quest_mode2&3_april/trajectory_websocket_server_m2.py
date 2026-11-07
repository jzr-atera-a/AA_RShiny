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
from collections import deque

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

# Debug statistics
command_count = 0
error_count = 0
last_command_time = None
command_history = deque(maxlen=10)  # Keep last 10 commands
start_time = time.time()

def get_timestamp():
    """Get formatted timestamp"""
    return datetime.now().strftime("%H:%M:%S.%f")[:-3]

def print_stats():
    """Print connection statistics"""
    uptime = time.time() - start_time
    print(f"\n{'='*60}")
    print(f"STATISTICS (Uptime: {uptime:.1f}s)")
    print(f"{'='*60}")
    print(f"Commands sent: {command_count}")
    print(f"Errors: {error_count}")
    if last_command_time:
        time_since_last = time.time() - last_command_time
        print(f"Time since last command: {time_since_last:.2f}s")
    print(f"Recent commands:")
    for i, (ts, cmd) in enumerate(command_history):
        print(f"  {i+1}. [{ts}] {cmd}")
    print(f"{'='*60}\n")

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
        arduino_serial = serial.Serial(port, SERIAL_BAUD, timeout=SERIAL_TIMEOUT, write_timeout=1)
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
    """Send command to Arduino via serial with timeout and detailed logging"""
    global arduino_serial, command_count, error_count, last_command_time, command_history
    
    if not arduino_serial or not arduino_serial.is_open:
        error_count += 1
        timestamp = get_timestamp()
        print(f"[{timestamp}] ❌ ERROR: Arduino not connected - command dropped: {command}")
        print(f"[{timestamp}] Serial state: arduino_serial={'None' if arduino_serial is None else 'closed'}")
        return False
    
    try:
        # Check if serial is still healthy
        if not arduino_serial.is_open:
            error_count += 1
            timestamp = get_timestamp()
            print(f"[{timestamp}] ❌ ERROR: Serial port closed unexpectedly")
            return False
        
        # Send command with newline (timeout handled by pyserial)
        bytes_sent = arduino_serial.write(f"{command}\n".encode('utf-8'))
        arduino_serial.flush()  # Force immediate send
        
        # Try to read Arduino ACK response (non-blocking, short timeout)
        arduino_serial.timeout = 0.05  # 50ms timeout for ACK
        arduino_response = None
        try:
            if arduino_serial.in_waiting > 0:
                arduino_response = arduino_serial.readline().decode('utf-8').strip()
        except:
            pass  # No response is OK
        finally:
            arduino_serial.timeout = SERIAL_TIMEOUT  # Restore normal timeout
        
        # Update statistics
        command_count += 1
        last_command_time = time.time()
        timestamp = get_timestamp()
        command_history.append((timestamp, command))
        
        # Log command with Arduino response (throttled - every 10th command)
        if command_count % 10 == 0:
            if arduino_response:
                print(f"[{timestamp}] ✓ Quest → Arduino: {command} (#{command_count})")
                print(f"[{timestamp}]   Arduino → Quest: {arduino_response}")
            else:
                print(f"[{timestamp}] ✓ Quest → Arduino: {command} (#{command_count}, {bytes_sent} bytes)")
        
        # Check for errors in Arduino response
        if arduino_response and arduino_response.startswith("ERR:"):
            error_count += 1
            print(f"[{timestamp}] ⚠️  Arduino error response: {arduino_response}")
        
        # Check for errors every 50 commands
        if command_count % 50 == 0:
            print_stats()
        
        return True
        
    except serial.SerialTimeoutException as e:
        error_count += 1
        timestamp = get_timestamp()
        print(f"[{timestamp}] ❌ SERIAL TIMEOUT: {command}")
        print(f"[{timestamp}] Details: {str(e)}")
        print(f"[{timestamp}] Total errors: {error_count}, Success rate: {((command_count-error_count)/command_count*100):.1f}%")
        return False
        
    except serial.SerialException as e:
        error_count += 1
        timestamp = get_timestamp()
        print(f"[{timestamp}] ❌ SERIAL EXCEPTION: {str(e)}")
        print(f"[{timestamp}] Command was: {command}")
        print(f"[{timestamp}] Serial port state: {arduino_serial.port if arduino_serial else 'None'}")
        return False
        
    except Exception as e:
        error_count += 1
        timestamp = get_timestamp()
        print(f"[{timestamp}] ❌ UNEXPECTED ERROR: {type(e).__name__}: {str(e)}")
        print(f"[{timestamp}] Command was: {command}")
        import traceback
        traceback.print_exc()
        return False

async def handle_websocket(websocket):
    """Handle WebSocket connection from Quest 3 with detailed logging"""
    
    client_address = websocket.remote_address
    connection_start = time.time()
    messages_received = 0
    
    timestamp = get_timestamp()
    print(f"\n{'='*60}")
    print(f"[{timestamp}] ✓ Quest 3 CONNECTED from {client_address[0]}:{client_address[1]}")
    print(f"{'='*60}\n")
    
    try:
        async for message in websocket:
            messages_received += 1
            
            # Quest sends simple string commands or JSON
            command = message.strip()
            
            # Ignore JSON commands (mode switches, etc.)
            if command.startswith('{'):
                # Silently ignore JSON - these are mode notifications
                continue
            
            # Handle MODE2_TRACK commands - comprehensive diagnostics
            if command.startswith('MODE2_TRACK:'):
                # FORMAT: MODE2_TRACK:timestamp:posX_cm:0:posZ_cm:headingDeg:targetHeadingDeg:distNext_cm:pathDev_cm:WP:index/total:M1:speed:M2:speed:S2:angle
                try:
                    parts = command.split(':')
                    
                    # Extract position and metrics
                    timestamp_ms = parts[1]
                    pos_x = float(parts[2])
                    pos_z = float(parts[4])
                    heading = float(parts[5])
                    target_heading = float(parts[6])
                    dist_next = float(parts[7])
                    path_dev = float(parts[8])
                    wp_info = parts[10]  # "index/total"
                    
                    # Extract motor/servo commands
                    m1_idx = command.find(':M1:')
                    m2_idx = command.find(':M2:')
                    s2_idx = command.find(':S2:')
                    
                    if m1_idx != -1 and m2_idx != -1 and s2_idx != -1:
                        m1_val = command[m1_idx+4:m2_idx]
                        m2_val = command[m2_idx+4:s2_idx]
                        s2_val = command[s2_idx+4:]
                        
                        # Build Arduino command (no S1 in new system)
                        arduino_cmd = f"ALL:M1:{m1_val}:M2:{m2_val}:S1:90:S2:{s2_val}"
                        
                        # Forward to Arduino
                        success = send_to_arduino(arduino_cmd)
                        
                        # Display comprehensive diagnostics in compact format
                        timestamp = get_timestamp()
                        status = "✓" if success else "✗"
                        print(f"[{timestamp}] {status} Mode2: WP {wp_info} | Pos({pos_x:.1f},{pos_z:.1f})cm | Hdg:{heading:.0f}° | Dev:{path_dev:.1f}cm | Next:{dist_next:.1f}cm | M1:{m1_val} M2:{m2_val} S2:{s2_val}")
                        
                        if not success:
                            print(f"[{timestamp}] ⚠️  Failed to forward MODE2_TRACK command to Arduino")
                    else:
                        timestamp = get_timestamp()
                        print(f"[{timestamp}] ⚠️  MODE2_TRACK missing motor/servo data")
                        
                except Exception as e:
                    timestamp = get_timestamp()
                    print(f"[{timestamp}] ❌ Error parsing MODE2_TRACK: {e}")
                
                continue  # Don't process as regular command
            
            # Handle MODE2_STOP command
            if command.startswith('MODE2_STOP'):
                timestamp = get_timestamp()
                print(f"[{timestamp}] 🛑 MODE 2 STOPPED - Path following halted")
                continue
            
            # Handle MODE2_PATH command (path upload)
            if command.startswith('MODE2_PATH:'):
                timestamp = get_timestamp()
                try:
                    import json
                    path_json = command[11:]  # Remove "MODE2_PATH:" prefix
                    path_data = json.loads(path_json)
                    waypoint_count = len(path_data.get('waypoints', []))
                    differential = path_data.get('differential', 0.25)
                    print(f"[{timestamp}] 📍 MODE 2 PATH UPLOADED: {waypoint_count} waypoints, differential={differential}")
                except Exception as e:
                    print(f"[{timestamp}] ⚠️  Error parsing MODE2_PATH: {e}")
                continue
            
            # Handle TRACK commands - extract motor/servo data and forward to Arduino
            if command.startswith('TRACK:'):
                # TRACK format: TRACK:timestamp:x:y:z:heading1:heading2:heading3:M1:speed:M2:speed:S1:angle:S2:angle
                # Extract motor and servo values
                try:
                    # Find M1, M2, S1, S2 positions in the command
                    m1_idx = command.find(':M1:')
                    m2_idx = command.find(':M2:')
                    s1_idx = command.find(':S1:')
                    s2_idx = command.find(':S2:')
                    
                    if m1_idx != -1 and m2_idx != -1 and s1_idx != -1 and s2_idx != -1:
                        # Extract values
                        m1_val = command[m1_idx+4:m2_idx]
                        m2_val = command[m2_idx+4:s1_idx]
                        s1_val = command[s1_idx+4:s2_idx]
                        s2_val = command[s2_idx+4:]
                        
                        # Build Arduino command
                        arduino_cmd = f"ALL:M1:{m1_val}:M2:{m2_val}:S1:{s1_val}:S2:{s2_val}"
                        
                        # Forward to Arduino
                        success = send_to_arduino(arduino_cmd)
                        
                        if not success:
                            timestamp = get_timestamp()
                            print(f"[{timestamp}] ⚠️  Failed to forward TRACK command to Arduino")
                    else:
                        timestamp = get_timestamp()
                        print(f"[{timestamp}] ⚠️  TRACK command missing motor/servo data: {command[:80]}")
                except Exception as e:
                    timestamp = get_timestamp()
                    print(f"[{timestamp}] ❌ Error parsing TRACK command: {e}")
                
                continue  # Don't process as regular command
            
            # Validate command format
            if command.startswith('MOTORS:') or \
               command.startswith('SERVO1:') or \
               command.startswith('SERVO2:') or \
               command.startswith('ALL:'):
                
                # Forward directly to Arduino
                success = send_to_arduino(command)
                
                if not success:
                    # Log failure details
                    timestamp = get_timestamp()
                    print(f"[{timestamp}] ⚠️  Failed to send command after {messages_received} messages")
                    print(f"[{timestamp}] Connection duration: {time.time() - connection_start:.1f}s")
                
            else:
                # Only log unknown non-JSON commands
                if not command.startswith('{'):
                    timestamp = get_timestamp()
                    print(f"[{timestamp}] ⚠️  WARNING: Unknown command format: {command}")
    
    except websockets.exceptions.ConnectionClosed as e:
        connection_duration = time.time() - connection_start
        timestamp = get_timestamp()
        print(f"\n{'='*60}")
        print(f"[{timestamp}] ❌ Quest 3 DISCONNECTED from {client_address[0]}:{client_address[1]}")
        print(f"[{timestamp}] Connection duration: {connection_duration:.1f}s")
        print(f"[{timestamp}] Messages received: {messages_received}")
        print(f"[{timestamp}] Close code: {e.code}, Reason: {e.reason}")
        print(f"{'='*60}\n")
        print_stats()
        
    except Exception as e:
        connection_duration = time.time() - connection_start
        timestamp = get_timestamp()
        print(f"\n{'='*60}")
        print(f"[{timestamp}] ❌ WebSocket ERROR: {type(e).__name__}")
        print(f"[{timestamp}] Details: {str(e)}")
        print(f"[{timestamp}] Connection duration: {connection_duration:.1f}s")
        print(f"[{timestamp}] Messages received: {messages_received}")
        print(f"{'='*60}\n")
        import traceback
        traceback.print_exc()
        print_stats()

async def main():
    """Start WebSocket server with comprehensive debugging"""
    
    global start_time
    start_time = time.time()
    
    print("=" * 70)
    print("Meta Quest 3 Robot Control - WebSocket Server (DEBUG MODE)")
    print("=" * 70)
    
    # Check SSL certificates
    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print("\n❌ ERROR: SSL certificates not found!")
        print("Generate with:")
        print("  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes")
        sys.exit(1)
    
    # Connect to Arduino
    if not connect_arduino():
        print("\n⚠️  WARNING: Starting without Arduino connection")
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
    print(f"  - Debug: ENABLED")
    print(f"\nQuest 3 will connect to:")
    print(f"  wss://{local_ip}:{WEBSOCKET_PORT}")
    print(f"\nCommand Format:")
    print(f"  ALL:M1:{{0-80}}:M2:{{0-80}}:S1:{{40-140}}:S2:{{50-130}}  (differential - RECOMMENDED)")
    print(f"  ALL:M{{0-80}}:S1:{{40-140}}:S2:{{50-130}}  (same speed both motors - legacy)")
    print(f"  MOTORS:0-80   (motor speed - legacy)")
    print(f"  SERVO1:40-140 (gripper - legacy)")
    print(f"  SERVO2:50-130 (steering - legacy)")
    print(f"\nDebug Features:")
    print(f"  ✓ Command counting and statistics")
    print(f"  ✓ Error rate tracking")
    print(f"  ✓ Connection duration monitoring")
    print(f"  ✓ Automatic health checks every 50 commands")
    print(f"  ✓ Detailed error logging with stack traces")
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
        print("\n\n" + "="*70)
        print("SHUTTING DOWN SERVER")
        print("="*70)
        print_stats()
        
        if arduino_serial and arduino_serial.is_open:
            # Send stop command before closing
            try:
                print("\nSending emergency stop to Arduino...")
                arduino_serial.write(b'ALL:M1:0:M2:0:S1:90:S2:90\n')
                time.sleep(0.1)
                print("✓ Stop command sent")
            except:
                print("⚠️  Could not send stop command")
            
            arduino_serial.close()
            print("✓ Arduino connection closed")
        
        print("\n✓ Server stopped cleanly")
        print("="*70 + "\n")
