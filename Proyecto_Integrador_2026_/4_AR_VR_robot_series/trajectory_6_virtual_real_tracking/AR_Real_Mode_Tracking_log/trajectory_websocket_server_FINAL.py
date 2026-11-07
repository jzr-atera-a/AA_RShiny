#!/usr/bin/env python3
"""
WebSocket Server for Meta Quest 3 Robot Control
WITH MODE 2 PATH TRACKING AND DEVIATION ANALYSIS

Receives commands from AR application and forwards to Arduino via serial
Tracks planned path vs actual execution for Mode 2 autonomous following

Port: 8444 (WebSocket Secure - WSS)
Serial: /dev/ttyACM0 (Linux) or COM3 (Windows) at 115200 baud

Usage:
    python trajectory_websocket_server_tracking_path.py

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
import json
import math
from datetime import datetime
from collections import deque

# Configuration
WEBSOCKET_PORT = 8444
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'

# Serial port configuration
SERIAL_PORT_LINUX = '/dev/ttyACM0'
SERIAL_PORT_WINDOWS = 'COM3'
SERIAL_BAUD = 115200
SERIAL_TIMEOUT = 1

# Global serial connection
arduino_serial = None

# Debug statistics
command_count = 0
error_count = 0
last_command_time = None
command_history = deque(maxlen=10)
start_time = time.time()
current_mode = "NONE"  # Track active mode: "MODE1", "MODE2", or "NONE"

# MODE 2 PATH TRACKING
mode2_active = False
mode2_waypoints = []  # List of (x, z, heading) tuples
mode2_current_waypoint = 0
mode2_total_deviation = 0.0
mode2_max_deviation = 0.0
mode2_deviation_samples = 0
mode2_start_time = None
differential_mode = 0.25  # Default
mode2_log_file = None  # CSV log file handle

def get_timestamp():
    """Get formatted timestamp"""
    return datetime.now().strftime("%H:%M:%S.%f")[:-3]

def start_csv_logging():
    """Start CSV logging for Mode 2 data"""
    global mode2_log_file
    
    timestamp_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"mode2_tracking_{timestamp_str}.csv"
    
    try:
        mode2_log_file = open(filename, 'w')
        # Write CSV header
        mode2_log_file.write("timestamp,waypoint,target_x,target_z,target_heading,actual_x,actual_z,actual_heading,")
        mode2_log_file.write("position_error,cross_track_error,heading_error,")
        mode2_log_file.write("m1_speed,m2_speed,s1_angle,s2_angle\n")
        mode2_log_file.flush()
        
        print(f"✓ CSV logging started: {filename}\n")
        return filename
    except Exception as e:
        print(f"⚠️  Failed to start CSV logging: {e}\n")
        mode2_log_file = None
        return None

def log_to_csv(analysis, actuators):
    """Log tracking data to CSV file"""
    global mode2_log_file
    
    if not mode2_log_file:
        return
    
    try:
        timestamp = get_timestamp()
        line = f"{timestamp},"
        line += f"{analysis['waypoint']},{analysis['target_pos'][0]:.2f},{analysis['target_pos'][1]:.2f},{analysis['target_heading']:.1f},"
        line += f"{analysis['actual_pos'][0]:.2f},{analysis['actual_pos'][1]:.2f},{analysis['actual_heading']:.1f},"
        line += f"{analysis['position_error']:.2f},{analysis['cross_track_error']:.2f},{analysis['heading_error']:.1f},"
        line += f"{actuators['m1']},{actuators['m2']},{actuators['s1']},{actuators['s2']}\n"
        
        mode2_log_file.write(line)
        mode2_log_file.flush()  # Ensure data is written immediately
    except Exception as e:
        print(f"⚠️  CSV logging error: {e}")

def stop_csv_logging():
    """Close CSV log file"""
    global mode2_log_file
    
    if mode2_log_file:
        try:
            mode2_log_file.close()
            print("✓ CSV logging stopped\n")
        except:
            pass
        mode2_log_file = None

def calculate_distance(x1, z1, x2, z2):
    """Calculate Euclidean distance in cm"""
    return math.sqrt((x2 - x1)**2 + (z2 - z1)**2)

def calculate_cross_track_error(pos_x, pos_z, wp1_x, wp1_z, wp2_x, wp2_z):
    """Calculate perpendicular distance from position to line segment"""
    # Vector from wp1 to wp2
    dx = wp2_x - wp1_x
    dz = wp2_z - wp1_z
    
    if abs(dx) < 0.01 and abs(dz) < 0.01:
        # Waypoints too close, just return distance to wp1
        return calculate_distance(pos_x, pos_z, wp1_x, wp1_z)
    
    # Vector from wp1 to position
    px = pos_x - wp1_x
    pz = pos_z - wp1_z
    
    # Project position onto line
    line_length_sq = dx*dx + dz*dz
    t = max(0, min(1, (px*dx + pz*dz) / line_length_sq))
    
    # Closest point on line segment
    closest_x = wp1_x + t * dx
    closest_z = wp1_z + t * dz
    
    # Distance from position to closest point
    return calculate_distance(pos_x, pos_z, closest_x, closest_z)

def normalize_angle(angle_deg):
    """Normalize angle to -180 to +180 range"""
    while angle_deg > 180:
        angle_deg -= 360
    while angle_deg < -180:
        angle_deg += 360
    return angle_deg

def analyze_path_deviation(pos_x, pos_z, heading_deg):
    """Analyze current position vs planned path"""
    global mode2_current_waypoint, mode2_total_deviation, mode2_max_deviation, mode2_deviation_samples
    
    if not mode2_active or not mode2_waypoints:
        return None
    
    # Find closest waypoint ahead
    min_dist = float('inf')
    closest_wp_idx = mode2_current_waypoint
    
    for i in range(mode2_current_waypoint, len(mode2_waypoints)):
        wp_x, wp_z, wp_heading = mode2_waypoints[i]
        dist = calculate_distance(pos_x, pos_z, wp_x, wp_z)
        if dist < min_dist:
            min_dist = dist
            closest_wp_idx = i
    
    # Update current waypoint if we've passed it
    if closest_wp_idx > mode2_current_waypoint:
        mode2_current_waypoint = closest_wp_idx
    
    # Get target waypoint
    if mode2_current_waypoint >= len(mode2_waypoints):
        mode2_current_waypoint = len(mode2_waypoints) - 1
    
    target_x, target_z, target_heading = mode2_waypoints[mode2_current_waypoint]
    
    # Calculate position deviation
    position_error = calculate_distance(pos_x, pos_z, target_x, target_z)
    
    # Calculate cross-track error if there's a next waypoint
    cross_track_error = position_error
    if mode2_current_waypoint < len(mode2_waypoints) - 1:
        next_x, next_z, _ = mode2_waypoints[mode2_current_waypoint + 1]
        cross_track_error = calculate_cross_track_error(pos_x, pos_z, target_x, target_z, next_x, next_z)
    
    # Calculate heading error
    heading_error = normalize_angle(target_heading - heading_deg)
    
    # Update statistics
    mode2_total_deviation += position_error
    mode2_deviation_samples += 1
    if position_error > mode2_max_deviation:
        mode2_max_deviation = position_error
    
    return {
        'waypoint': mode2_current_waypoint + 1,
        'total_waypoints': len(mode2_waypoints),
        'target_pos': (target_x, target_z),
        'actual_pos': (pos_x, pos_z),
        'position_error': position_error,
        'cross_track_error': cross_track_error,
        'target_heading': target_heading,
        'actual_heading': heading_deg,
        'heading_error': heading_error,
        'avg_deviation': mode2_total_deviation / mode2_deviation_samples if mode2_deviation_samples > 0 else 0,
        'max_deviation': mode2_max_deviation
    }

def print_path_analysis(analysis, actuators=None):
    """Print formatted path tracking analysis with actuator commands"""
    if not analysis:
        return
    
    timestamp = get_timestamp()
    print(f"\n{'─'*70}")
    print(f"[{timestamp}] 📊 MODE 2 PATH TRACKING")
    print(f"{'─'*70}")
    print(f"Waypoint: {analysis['waypoint']}/{analysis['total_waypoints']}")
    print(f"Target:   ({analysis['target_pos'][0]:.1f}, {analysis['target_pos'][1]:.1f}) cm @ {analysis['target_heading']:.0f}°")
    print(f"Actual:   ({analysis['actual_pos'][0]:.1f}, {analysis['actual_pos'][1]:.1f}) cm @ {analysis['actual_heading']:.0f}°")
    print(f"")
    print(f"Deviation Analysis:")
    print(f"  Position Error:    {analysis['position_error']:.1f} cm")
    print(f"  Cross-Track Error: {analysis['cross_track_error']:.1f} cm")
    print(f"  Heading Error:     {analysis['heading_error']:.0f}°")
    print(f"")
    if actuators:
        print(f"Actuator Commands:")
        print(f"  Motors: M1={actuators['m1']}% (RIGHT), M2={actuators['m2']}% (LEFT)")
        print(f"  Servos: S1={actuators['s1']}° (GRIPPER), S2={actuators['s2']}° (STEERING)")
        servo2_dir = "STRAIGHT" if 85 <= actuators['s2'] <= 95 else ("LEFT" if actuators['s2'] > 95 else "RIGHT")
        print(f"  Steering: {servo2_dir} ({actuators['s2'] - 90:+d}° from center)")
        print(f"")
    print(f"Running Statistics:")
    print(f"  Avg Deviation: {analysis['avg_deviation']:.1f} cm")
    print(f"  Max Deviation: {analysis['max_deviation']:.1f} cm")
    print(f"{'─'*70}\n")

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
    print(f"🎮 CURRENT MODE: {current_mode}")
    print(f"Autonomous (Mode 2): {'ACTIVE' if mode2_active else 'INACTIVE'}")
    print(f"Differential mode: {differential_mode}x")
    if mode2_active:
        print(f"Path progress: {mode2_current_waypoint}/{len(mode2_waypoints)} waypoints")
    print(f"Recent commands:")
    for i, (ts, cmd) in enumerate(command_history):
        print(f"  {i+1}. [{ts}] {cmd}")
    print(f"{'='*60}\n")

def detect_serial_port():
    """Auto-detect Arduino serial port"""
    import platform
    
    if platform.system() == 'Linux':
        possible_ports = ['/dev/ttyACM0', '/dev/ttyACM1', '/dev/ttyUSB0', '/dev/ttyUSB1']
    elif platform.system() == 'Windows':
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

def init_arduino():
    """Initialize serial connection to Arduino"""
    global arduino_serial
    
    print("\nConnecting to Arduino...")
    
    # Detect port
    port = detect_serial_port()
    if not port:
        print("❌ ERROR: Arduino not found on any serial port")
        print("   Please check USB connection and try again")
        return False
    
    # Open connection
    try:
        arduino_serial = serial.Serial(port, SERIAL_BAUD, timeout=SERIAL_TIMEOUT)
        time.sleep(2)  # Wait for Arduino hardware reset
        
        # FIX A: Flush OS-level serial buffers BEFORE reading anything.
        # Previous sessions may leave hundreds of stacked commands in the
        # OS UART buffer (up to 4096 bytes). Without this flush, those corrupt
        # the Arduino's parser and block all valid commands until drained.
        arduino_serial.reset_input_buffer()   # discard incoming OS buffer
        arduino_serial.reset_output_buffer()  # discard outgoing OS buffer
        time.sleep(0.1)
        
        # FIX A2: Send a newline to flush any partial command stuck in Arduino's
        # own 64-byte receive buffer, then wait for it to respond with an error
        # (which we discard). This clears the Arduino-side parser state.
        arduino_serial.write(b'\n')
        time.sleep(0.15)
        arduino_serial.reset_input_buffer()  # discard the error response
        
        # FIX A3: Active drain — keep reading until truly quiet for 500ms.
        # The while arduino_serial.in_waiting > 0 loop exits as soon as the
        # immediate buffer is empty, but Arduino may still be sending more.
        print(f"  Draining Arduino serial buffer (clearing previous session)...")
        drain_start = time.time()
        last_data_time = time.time()
        line_count = 0
        while time.time() - last_data_time < 0.5:  # quiet for 500ms = done
            if arduino_serial.in_waiting > 0:
                line = arduino_serial.readline().decode('utf-8', errors='ignore').strip()
                last_data_time = time.time()
                line_count += 1
                if line and line_count <= 5:  # show first 5 lines only
                    print(f"  Arduino: {line}")
                elif line_count == 6:
                    print(f"  Arduino: ... (draining {line_count} lines)")
            if time.time() - drain_start > 5.0:  # safety: don't drain for >5s
                print(f"  WARNING: Drain timeout after 5s ({line_count} lines)")
                break
            time.sleep(0.01)
        
        arduino_serial.reset_input_buffer()  # final flush of anything arrived during drain
        print(f"  Drained {line_count} lines in {time.time()-drain_start:.1f}s")
        print(f"\n✓ Arduino connected successfully on {port}\n")
        return True
        
    except serial.SerialException as e:
        print(f"❌ ERROR: Could not open {port}: {e}")
        return False

def send_to_arduino(command):
    """Send command to Arduino via serial"""
    global command_count, last_command_time, error_count
    
    if not arduino_serial or not arduino_serial.is_open:
        return False
    
    try:
        command_count += 1
        last_command_time = time.time()
        
        # Add to history
        timestamp = get_timestamp()
        command_history.append((timestamp, command))
        
        # FIX B: Rate limiter — enforce minimum 20ms between serial writes.
        # At 115200 baud, a 26-byte command takes ~2.3ms to transmit.
        # Enforcing 20ms spacing prevents OS buffer saturation even if the
        # JavaScript side fires a burst (e.g. Quest headset resume storm).
        now = time.time()
        if hasattr(send_to_arduino, '_last_write_time'):
            elapsed = now - send_to_arduino._last_write_time
            if elapsed < 0.020:  # 20ms minimum spacing = max 50Hz
                time.sleep(0.020 - elapsed)
        send_to_arduino._last_write_time = time.time()
        
        # Send to Arduino
        arduino_serial.write(f"{command}\n".encode('utf-8'))
        arduino_serial.flush()
        
        # Print every 10th command
        if command_count % 10 == 0:
            print(f"[{timestamp}] ✓ Quest → Arduino: {command} (#{command_count})")
            
            # Read response
            if arduino_serial.in_waiting > 0:
                response = arduino_serial.readline().decode('utf-8', errors='ignore').strip()
                print(f"[{timestamp}]   Arduino → Quest: {response}")
        
        # Print stats every 50 commands
        if command_count % 50 == 0:
            print_stats()
        
        return True
        
    except serial.SerialTimeoutException as e:
        error_count += 1
        timestamp = get_timestamp()
        print(f"[{timestamp}] ❌ SERIAL TIMEOUT: {command}")
        return False
        
    except Exception as e:
        error_count += 1
        timestamp = get_timestamp()
        print(f"[{timestamp}] ❌ ERROR: {type(e).__name__}: {str(e)}")
        return False

async def handle_websocket(websocket):
    """Handle WebSocket connection from Quest 3"""
    global mode2_active, mode2_waypoints, mode2_current_waypoint
    global mode2_total_deviation, mode2_max_deviation, mode2_deviation_samples
    global mode2_start_time, differential_mode, current_mode
    
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
            command = message.strip()
            
            # DEBUG: Log all incoming messages
            timestamp = get_timestamp()
            if not command.startswith('TRACK:') and messages_received % 10 == 1:
                print(f"[{timestamp}] 📨 RECEIVED: {command[:80]}...")
            
            # Handle MODE2_PATH message (receive planned waypoints)
            if command.startswith('MODE2_PATH:'):
                print(f"\n[{timestamp}] 🔍 MODE2_PATH message detected!")
                try:
                    # Format: MODE2_PATH:{"waypoints":[[x,z,heading],...], "differential":0.25}
                    json_data = command[11:]  # Remove "MODE2_PATH:" prefix
                    print(f"[{timestamp}] 📝 JSON data length: {len(json_data)} chars")
                    
                    data = json.loads(json_data)
                    
                    # CRITICAL: Convert waypoints from meters to centimeters to match position data
                    mode2_waypoints = [(wp[0] * 100, wp[1] * 100, wp[2]) for wp in data['waypoints']]
                    differential_mode = data.get('differential', 0.25)
                    mode2_active = True
                    mode2_current_waypoint = 0
                    mode2_total_deviation = 0.0
                    mode2_max_deviation = 0.0
                    mode2_deviation_samples = 0
                    mode2_start_time = time.time()
                    current_mode = "MODE2"
                    
                    # Start CSV logging
                    csv_filename = start_csv_logging()
                    
                    timestamp = get_timestamp()
                    print(f"\n{'='*60}")
                    print(f"[{timestamp}] 🎯 MODE 2 PATH RECEIVED")
                    print(f"{'='*60}")
                    print(f"Waypoints: {len(mode2_waypoints)}")
                    print(f"Differential: {differential_mode}x")
                    print(f"Start: ({mode2_waypoints[0][0]:.1f}, {mode2_waypoints[0][1]:.1f}) cm @ {mode2_waypoints[0][2]:.0f}°")
                    print(f"End:   ({mode2_waypoints[-1][0]:.1f}, {mode2_waypoints[-1][1]:.1f}) cm @ {mode2_waypoints[-1][2]:.0f}°")
                    if csv_filename:
                        print(f"CSV Log: {csv_filename}")
                    print(f"{'='*60}\n")
                    
                except Exception as e:
                    timestamp = get_timestamp()
                    print(f"[{timestamp}] ❌ Error parsing MODE2_PATH: {e}")
                    import traceback
                    traceback.print_exc()
                
                continue
            
            # Handle MODE2_STOP message
            if command == 'MODE2_STOP':
                if mode2_active:
                    duration = time.time() - mode2_start_time if mode2_start_time else 0
                    timestamp = get_timestamp()
                    print(f"\n{'='*60}")
                    print(f"[{timestamp}] 🏁 MODE 2 COMPLETE")
                    print(f"{'='*60}")
                    print(f"Duration: {duration:.1f}s")
                    print(f"Waypoints reached: {mode2_current_waypoint}/{len(mode2_waypoints)}")
                    if mode2_deviation_samples > 0:
                        print(f"Avg Deviation: {mode2_total_deviation/mode2_deviation_samples:.1f} cm")
                        print(f"Max Deviation: {mode2_max_deviation:.1f} cm")
                    print(f"{'='*60}\n")
                    
                    # Stop CSV logging
                    stop_csv_logging()
                
                mode2_active = False
                mode2_waypoints = []
                current_mode = "NONE"
                continue
            
            # Detect mode changes from JSON
            if command.startswith('{'):
                try:
                    data = json.loads(command)
                    if 'mode' in data:
                        old_mode = current_mode
                        if data['mode'] == 1:
                            current_mode = "MODE1"
                        elif data['mode'] == 2:
                            current_mode = "MODE2"
                        
                        if old_mode != current_mode:
                            timestamp = get_timestamp()
                            print(f"[{timestamp}] 🎮 MODE CHANGE: {old_mode} → {current_mode}")
                except:
                    pass
                continue
            
            # Handle MODE2_TRACK: position data from Mode 2 - log only, do NOT forward to Arduino
            # (Mode 2 already sends ALL: directly; forwarding TRACK would triple-write the serial port)
            if command.startswith('MODE2_TRACK:'):
                try:
                    parts = command.split(':')
                    if len(parts) >= 10:
                        pos_x = float(parts[2])  # Already in cm (converted by HTML)
                        pos_z = float(parts[4])  # Already in cm
                        heading_deg = float(parts[7])
                        if mode2_active and command_count % 10 == 0:
                            analysis = analyze_path_deviation(pos_x, pos_z, heading_deg)
                            if analysis:
                                log_tracking_data(analysis, parts)
                                print_tracking_analysis(analysis)
                except Exception as e:
                    print(f"[{get_timestamp()}] ⚠️ MODE2_TRACK parse error: {e}")
                # Do NOT forward to Arduino
            
            # Handle TRACK commands with position/heading data (Mode 1 only)
            elif command.startswith('TRACK:'):
                # TRACK format: TRACK:timestamp:x:y:z:heading1:heading2:heading3:M1:speed:M2:speed:S1:angle:S2:angle
                try:
                    parts = command.split(':')
                    if len(parts) >= 10:
                        # Extract position and heading
                        pos_x = float(parts[2]) * 100  # Convert m to cm
                        pos_z = float(parts[4]) * 100  # Convert m to cm
                        heading_deg = float(parts[7])  # Final heading in degrees
                        
                        # Extract motor/servo values
                        m1_idx = command.find(':M1:')
                        m2_idx = command.find(':M2:')
                        s1_idx = command.find(':S1:')
                        s2_idx = command.find(':S2:')
                        
                        if m1_idx != -1 and m2_idx != -1 and s1_idx != -1 and s2_idx != -1:
                            m1_val = command[m1_idx+4:m2_idx]
                            m2_val = command[m2_idx+4:s1_idx]
                            s1_val = command[s1_idx+4:s2_idx]
                            s2_val = command[s2_idx+4:]
                            
                            # Build Arduino command
                            arduino_cmd = f"ALL:M1:{m1_val}:M2:{m2_val}:S1:{s1_val}:S2:{s2_val}"
                            
                            # Forward to Arduino
                            success = send_to_arduino(arduino_cmd)
                            
                            # Analyze path deviation if Mode 2 is active
                            if mode2_active and command_count % 10 == 0:
                                analysis = analyze_path_deviation(pos_x, pos_z, heading_deg)
                                if analysis:
                                    actuators = {
                                        'm1': int(m1_val),
                                        'm2': int(m2_val),
                                        's1': int(s1_val),
                                        's2': int(s2_val)
                                    }
                                    
                                    # Log to CSV
                                    log_to_csv(analysis, actuators)
                                    
                                    timestamp = get_timestamp()
                                    print(f"[{timestamp}]   📍 Position: ({pos_x:.1f}, {pos_z:.1f}) cm")
                                    print(f"[{timestamp}]   🧭 Heading: {heading_deg:.1f}°")
                                    print(f"[{timestamp}]   🚗 Motors: M1:{m1_val}% M2:{m2_val}% | Steer: S2:{s2_val}°")
                                    
                                    # Print detailed analysis every 30 commands
                                    if command_count % 30 == 0:
                                        print_path_analysis(analysis, actuators)
                
                except Exception as e:
                    timestamp = get_timestamp()
                    print(f"[{timestamp}] ❌ Error parsing TRACK command: {e}")
                
                continue
            
            # Handle regular commands
            if command.startswith('MOTORS:') or \
               command.startswith('SERVO1:') or \
               command.startswith('SERVO2:') or \
               command.startswith('ALL:'):
                send_to_arduino(command)
                
    except websockets.exceptions.ConnectionClosed:
        timestamp = get_timestamp()
        print(f"[{timestamp}] ⚠️  Quest 3 disconnected")
        duration = time.time() - connection_start
        print(f"[{timestamp}] Connection lasted {duration:.1f}s, {messages_received} messages")
    except Exception as e:
        timestamp = get_timestamp()
        print(f"[{timestamp}] ❌ WebSocket error: {type(e).__name__}: {str(e)}")

async def main():
    """Main server function"""
    
    # Print header
    print("\n" + "="*70)
    print("Meta Quest 3 Robot Control - WebSocket Server")
    print("WITH AUTONOMOUS PATH FOLLOWING")
    print("="*70 + "\n")
    
    # Initialize Arduino
    if not init_arduino():
        print("\n❌ Failed to initialize Arduino. Exiting.")
        return
    
    # Set up SSL context
    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print(f"❌ ERROR: SSL certificates not found")
        print(f"   Missing: {CERT_FILE} or {KEY_FILE}")
        print(f"   Generate with: openssl req -x509 -newkey rsa:4096 -nodes -keyout key.pem -out cert.pem -days 365")
        return
    
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain(CERT_FILE, KEY_FILE)
    
    # Get local IP
    import socket
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    
    print("✓ WebSocket server starting...\n")
    print("Server Details:")
    print(f"  - Port: {WEBSOCKET_PORT}")
    print(f"  - Protocol: WSS")
    print(f"  - Local IP: {local_ip}")
    print(f"  - Autonomous: ENABLED")
    print(f"\nQuest 3 URL: wss://{local_ip}:{WEBSOCKET_PORT}")
    print(f"\nPress Ctrl+C to stop\n")
    print("="*70 + "\n")
    print("Waiting for Quest 3 connection...\n")
    
    # Start WebSocket server
    async with websockets.serve(handle_websocket, "0.0.0.0", WEBSOCKET_PORT, ssl=ssl_context):
        await asyncio.Future()  # Run forever

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n" + "="*70)
        print("SHUTTING DOWN SERVER")
        print("="*70 + "\n")
        
        print_stats()
        
        # Emergency stop
        if arduino_serial and arduino_serial.is_open:
            print("\nSending emergency stop...")
            try:
                arduino_serial.write(b"ALL:M1:0:M2:0:S1:90:S2:90\n")
                arduino_serial.flush()
                print("✓ Stop command sent")
                time.sleep(0.5)
                arduino_serial.close()
                print("✓ Arduino closed")
            except:
                pass
        
        print("\n✓ Server stopped")
        print("="*70 + "\n")
