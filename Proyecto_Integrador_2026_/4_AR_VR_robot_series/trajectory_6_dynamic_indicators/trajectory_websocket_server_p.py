#!/usr/bin/env python3
"""
Jetson Nano WebSocket Server - Robot Trajectory with Arduino Control
Generates commands from Quest 3 trajectory and sends to Arduino via serial at 5Hz
"""

import asyncio
import websockets
import ssl
import json
import os
import sys
import math
import csv
import serial
import time
import platform
import random
from datetime import datetime

# CONFIG
HOST = '0.0.0.0'
PORT = 8444  # Changed from 8443 to avoid conflict with HTTPS server
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'

# Arduino Serial Configuration
ARDUINO_PORT = '/dev/ttyACM0'  # Change to /dev/ttyUSB0 if needed
ARDUINO_BAUD = 115200

# Robot configuration
SERVO2_CENTER = 90   # degrees
SERVO2_MIN = 50      # degrees
SERVO2_MAX = 130     # degrees
MOTOR_MIN = 50       # MD22 power (0-128) - SAFETY: 50% minimum
MOTOR_MAX = 80       # MD22 power - SAFETY: 80% maximum (was 90)
MOTOR_STOP = 0
COMMAND_RATE = 5     # Hz (commands per second)
WHEELBASE = 0.34     # meters (34cm between front and rear wheels)

# STATE
connected_clients = set()
start_time = datetime.now()
arduino_serial = None

# CHARGER SIMULATION STATE
charger_update_tasks = {}  # websocket -> asyncio.Task mapping
CHARGER_UPDATE_INTERVAL = 15  # seconds

# M25 London Map Bounds (estimated)
MAP_BOUNDS = {
    'nw': {'lat': 51.7088, 'lon': -0.5500},
    'se': {'lat': 51.2600, 'lon': 0.2800},
    'center': {'lat': 51.4844, 'lon': -0.1350}
}

# ==============================================================================
# ARDUINO SERIAL FUNCTIONS
# ==============================================================================

def init_arduino():
    """Initialize serial connection to Arduino"""
    global arduino_serial
    
    # Skip Arduino on Windows
    if platform.system() == 'Windows':
        print("\n" + "="*80)
        print("  RUNNING ON WINDOWS - ARDUINO DISABLED")
        print("="*80)
        print("  Arduino serial connection skipped on Windows")
        print("  Server will receive Quest 3 data but NOT control robot")
        print("  To enable robot control: run on Linux/Jetson Nano")
        print("="*80 + "\n")
        arduino_serial = None
        return False
    
    try:
        arduino_serial = serial.Serial(ARDUINO_PORT, ARDUINO_BAUD, timeout=1)
        time.sleep(2)  # Wait for Arduino reset
        
        # Read startup messages
        print("\n" + "="*80)
        print("  ARDUINO INITIALIZATION")
        print("="*80)
        for _ in range(15):
            if arduino_serial.in_waiting:
                line = arduino_serial.readline().decode().strip()
                if line:
                    print(f"  {line}")
        
        print(f"\n✓ Arduino connected on {ARDUINO_PORT}")
        print(f"  Baud rate: {ARDUINO_BAUD}")
        print("="*80 + "\n")
        
        # Center servo and stop motors on startup
        send_command_to_arduino(SERVO2_CENTER, 0, 0)
        return True
        
    except serial.SerialException as e:
        print(f"\n✗ Arduino connection failed: {e}")
        print(f"  Make sure Arduino is connected to {ARDUINO_PORT}")
        print(f"  Try: ls /dev/ttyACM* /dev/ttyUSB*\n")
        arduino_serial = None
        return False

def send_command_to_arduino(servo2_angle, motor1_speed, motor2_speed):
    """Send command to Arduino via serial"""
    if not arduino_serial:
        return False
    
    try:
        # Clamp values to safe ranges
        servo2_angle = max(SERVO2_MIN, min(SERVO2_MAX, int(servo2_angle)))
        
        if motor1_speed <= 0:
            motor1_speed = 0
        else:
            motor1_speed = max(MOTOR_MIN, min(MOTOR_MAX, int(motor1_speed)))
        
        if motor2_speed <= 0:
            motor2_speed = 0
        else:
            motor2_speed = max(MOTOR_MIN, min(MOTOR_MAX, int(motor2_speed)))
        
        # Send SERVO2 command
        servo_cmd = f"SERVO2:{servo2_angle}\n"
        arduino_serial.write(servo_cmd.encode())
        time.sleep(0.005)
        
        # Send MOTORS command
        if motor1_speed == 0 and motor2_speed == 0:
            motor_cmd = "STOP_ALL_MOTORS\n"
        else:
            motor_cmd = f"MOTORS:{motor1_speed}\n"  # Both motors same speed
        
        arduino_serial.write(motor_cmd.encode())
        time.sleep(0.005)
        
        # Clear response buffer
        while arduino_serial.in_waiting:
            arduino_serial.readline()
        
        return True
        
    except Exception as e:
        print(f"✗ Arduino communication error: {e}")
        return False

# ==============================================================================
# COMMAND GENERATION
# ==============================================================================

def calculate_curvature(p1, p2, p3):
    """Calculate curvature radius at p2 given three points"""
    a = math.sqrt((p2['x'] - p1['x'])**2 + (p2['z'] - p1['z'])**2)
    b = math.sqrt((p3['x'] - p2['x'])**2 + (p3['z'] - p2['z'])**2)
    c = math.sqrt((p3['x'] - p1['x'])**2 + (p3['z'] - p1['z'])**2)
    
    if a < 0.001 or b < 0.001 or c < 0.001:
        return float('inf')
    
    s = (a + b + c) / 2
    area_sq = s * (s - a) * (s - b) * (s - c)
    
    if area_sq <= 0:
        return float('inf')
    
    area = math.sqrt(area_sq)
    curvature = (4 * area) / (a * b * c)
    
    return float('inf') if curvature == 0 else 1 / curvature

def curvature_to_servo_angle(curvature_radius):
    """Convert curvature radius to servo angle using Ackerman geometry"""
    if curvature_radius > 100:  # Straight
        return SERVO2_CENTER
    
    # Ackerman: tan(steering_angle) = wheelbase / turning_radius
    steering_angle_rad = math.atan2(WHEELBASE, curvature_radius)
    steering_angle_deg = math.degrees(steering_angle_rad)
    
    # Map to servo range (negative = left, positive = right)
    servo_angle = SERVO2_CENTER + int(steering_angle_deg * 2)
    
    # Clamp to servo limits
    return max(SERVO2_MIN, min(SERVO2_MAX, servo_angle))

def calculate_motor_speed(distance_remaining, current_speed_cms):
    """Calculate motor power based on distance remaining"""
    # If close to end, slow down
    if distance_remaining < 0.5:  # Within 50cm of end
        return MOTOR_MIN
    elif distance_remaining < 1.0:  # Within 1m
        return int(MOTOR_MIN + (MOTOR_MAX - MOTOR_MIN) * 0.5)
    else:
        return MOTOR_MAX

def generate_commands(trajectory_points):
    """Generate robot commands from trajectory points at 5Hz"""
    if len(trajectory_points) < 2:
        return []
    
    commands = []
    
    # Calculate total distance
    total_distance = 0
    for i in range(1, len(trajectory_points)):
        p1 = trajectory_points[i - 1]
        p2 = trajectory_points[i]
        dist = math.sqrt((p2['x'] - p1['x'])**2 + (p2['z'] - p1['z'])**2)
        total_distance += dist
    
    print(f"\n{'='*80}")
    print(f"  GENERATING ROBOT COMMANDS")
    print(f"{'='*80}")
    print(f"  Total trajectory distance: {total_distance:.2f}m")
    print(f"  Total points: {len(trajectory_points)}")
    print(f"  Command rate: {COMMAND_RATE} Hz")
    print(f"  Motor range: {MOTOR_MIN}-{MOTOR_MAX}% (SAFETY LIMITED)")
    print(f"{'='*80}\n")
    
    # Interpolate trajectory to match command rate
    avg_speed = 0.13  # m/s (reduced from 0.15 for safety)
    total_time = total_distance / avg_speed
    num_commands = int(total_time * COMMAND_RATE)
    
    print(f"  Estimated time: {total_time:.1f}s")
    print(f"  Commands to generate: {num_commands}")
    print(f"\n{'='*80}\n")
    
    for cmd_index in range(num_commands):
        time_elapsed = cmd_index / COMMAND_RATE
        target_distance = (cmd_index / num_commands) * total_distance
        
        # Find which segment we're on
        segment_distance = 0
        current_point_index = 0
        
        for i in range(1, len(trajectory_points)):
            p1 = trajectory_points[i - 1]
            p2 = trajectory_points[i]
            seg_dist = math.sqrt((p2['x'] - p1['x'])**2 + (p2['z'] - p1['z'])**2)
            
            if segment_distance + seg_dist >= target_distance:
                current_point_index = i
                break
            
            segment_distance += seg_dist
        
        # Get three points for curvature calculation
        idx = min(current_point_index, len(trajectory_points) - 2)
        
        if idx >= 1:
            p1 = trajectory_points[idx - 1]
            p2 = trajectory_points[idx]
            p3 = trajectory_points[min(idx + 1, len(trajectory_points) - 1)]
            
            curvature_radius = calculate_curvature(p1, p2, p3)
            servo_angle = curvature_to_servo_angle(curvature_radius)
        else:
            servo_angle = SERVO2_CENTER
        
        distance_remaining = total_distance - target_distance
        motor_power = calculate_motor_speed(distance_remaining, avg_speed * 100)
        
        # Create command
        command = {
            'timestamp': time_elapsed,
            'distance_from_origin': target_distance,
            'distance_to_end': distance_remaining,
            'servo2': servo_angle,
            'motor1': motor_power,
            'motor2': motor_power
        }
        
        commands.append(command)
    
    # Final command: stop
    final_command = {
        'timestamp': total_time,
        'distance_from_origin': total_distance,
        'distance_to_end': 0,
        'servo2': SERVO2_CENTER,
        'motor1': MOTOR_STOP,
        'motor2': MOTOR_STOP
    }
    commands.append(final_command)
    
    return commands

def save_commands_to_csv(commands):
    """Save commands to CSV file"""
    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f'robot_commands_{timestamp_str}.csv'
    
    with open(filename, 'w', newline='') as csvfile:
        fieldnames = ['timestamp', 'distance_from_origin', 'distance_to_end', 
                     'SERVO2', 'MOTOR1', 'MOTOR2']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        
        writer.writeheader()
        for cmd in commands:
            writer.writerow({
                'timestamp': f"{cmd['timestamp']:.3f}",
                'distance_from_origin': f"{cmd['distance_from_origin']:.3f}",
                'distance_to_end': f"{cmd['distance_to_end']:.3f}",
                'SERVO2': cmd['servo2'],
                'MOTOR1': cmd['motor1'],
                'MOTOR2': cmd['motor2']
            })
    
    print(f"\n✓ Commands saved to: {filename}\n")
    return filename

# ==============================================================================
# EV CHARGER SIMULATION
# ==============================================================================

def generate_random_chargers(count=3):
    """Generate random EV charger data within map bounds"""
    chargers = []
    statuses = ['available', 'in_use', 'offline', 'reserved']
    conditions = ['Good', 'Fair', 'Poor']
    capacities = ['50 kW', '150 kW', '350 kW']
    connector_types = ['CCS', 'CHAdeMO', 'Tesla Supercharger', 'Type 2']
    prices = ['£0.35/kWh', '£0.45/kWh', '£0.55/kWh', 'Free (members)']
    
    lat_range = MAP_BOUNDS['nw']['lat'] - MAP_BOUNDS['se']['lat']
    lon_range = MAP_BOUNDS['se']['lon'] - MAP_BOUNDS['nw']['lon']
    
    for i in range(count):
        # Random GPS within bounds
        lat = MAP_BOUNDS['se']['lat'] + random.random() * lat_range
        lon = MAP_BOUNDS['nw']['lon'] + random.random() * lon_range
        
        charger = {
            'id': f'CHG_{random.randint(1000, 9999)}',
            'lat': round(lat, 6),
            'lon': round(lon, 6),
            'status': random.choice(statuses),
            'condition': random.choice(conditions),
            'capacity': random.choice(capacities),
            'connector_type': random.choice(connector_types),
            'price': random.choice(prices),
            'queue_length': random.randint(0, 5)
        }
        chargers.append(charger)
    
    return chargers

async def charger_update_loop(websocket):
    """Send charger updates every 15 seconds"""
    try:
        while True:
            # Generate 3 random chargers
            chargers = generate_random_chargers(3)
            
            # Send to Quest
            message = {
                'type': 'CHARGER_UPDATE',
                'chargers': chargers,
                'timestamp': time.time()
            }
            
            await websocket.send(json.dumps(message))
            print(f"\n[CHARGER UPDATE] Sent 3 chargers:")
            for c in chargers:
                print(f"  • {c['id']} @ ({c['lat']:.4f}, {c['lon']:.4f}) - {c['status']}")
            
            # Wait 15 seconds before next update
            await asyncio.sleep(CHARGER_UPDATE_INTERVAL)
            
    except asyncio.CancelledError:
        print("\n[CHARGER UPDATE] Loop cancelled")
    except Exception as e:
        print(f"\n[CHARGER UPDATE] Error: {e}")

# ==============================================================================
# WEBSOCKET HANDLER
# ==============================================================================

async def handle_client(websocket):
    """Handle WebSocket client"""
    client_ip = websocket.remote_address[0] if hasattr(websocket, 'remote_address') else 'Unknown'
    connected_clients.add(websocket)
    
    print(f"\n✓ Quest 3 connected: {client_ip}")
    
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                
                if data.get('command') == 'GENERATE_COMMANDS':
                    trajectory = data.get('trajectory')
                    
                    if trajectory and 'points' in trajectory:
                        points = trajectory['points']
                        
                        print(f"\n{'='*80}")
                        print(f"  TRAJECTORY RECEIVED FROM QUEST 3")
                        print(f"{'='*80}")
                        print(f"  Points: {len(points)}")
                        print(f"  Distance: {trajectory.get('distance', 0):.2f}m")
                        print(f"  Floor Y: {trajectory.get('floorY', 0):.3f}m")
                        print(f"{'='*80}\n")
                        
                        # Generate commands
                        commands = generate_commands(points)
                        
                        # Save to CSV
                        csv_file = save_commands_to_csv(commands)
                        
                        # Send acknowledgment
                        await websocket.send(json.dumps({
                            'type': 'commands_ready',
                            'command_count': len(commands),
                            'csv_file': csv_file
                        }))
                        
                        print(f"✓ Commands generated and saved!")
                        
                        if not arduino_serial:
                            print(f"\n⚠ WARNING: Arduino not connected!")
                            print(f"  Commands will be displayed but NOT sent to robot\n")
                        
                        print(f"\n{'='*100}")
                        print(f"  EXECUTING TRAJECTORY ON ROBOT (5 Hz)")
                        print(f"{'='*100}")
                        print(f"{'Time':>8} {'DistOrg':>8} {'DistEnd':>8} {'SERVO2':>8} {'MOTOR1':>8} {'MOTOR2':>8}")
                        print(f"{'-'*100}")
                        
                        # Stream commands in real-time at 5Hz
                        for cmd in commands:
                            # Display command
                            print(f"{cmd['timestamp']:8.3f} {cmd['distance_from_origin']:8.3f} "
                                  f"{cmd['distance_to_end']:8.3f} {cmd['servo2']:8d} "
                                  f"{cmd['motor1']:8d} {cmd['motor2']:8d}")
                            
                            # Send to Arduino
                            if arduino_serial:
                                send_command_to_arduino(cmd['servo2'], cmd['motor1'], cmd['motor2'])
                            
                            # Send to Quest 3 for monitoring
                            await websocket.send(json.dumps({
                                'type': 'command_execute',
                                'timestamp': cmd['timestamp'],
                                'servo2': cmd['servo2'],
                                'motor1': cmd['motor1'],
                                'motor2': cmd['motor2'],
                                'distance_remaining': cmd['distance_to_end']
                            }))
                            
                            # Wait 200ms (5Hz rate)
                            await asyncio.sleep(0.2)
                        
                        print(f"{'='*100}")
                        print(f"  TRAJECTORY EXECUTION COMPLETE!")
                        print(f"{'='*100}\n")
                        
                        # Send completion notification
                        await websocket.send(json.dumps({
                            'type': 'execution_complete',
                            'total_commands': len(commands)
                        }))
                
                # ── MODE 4: CONTROLLER TRACKING ──────────────────────────────────
                elif data.get('command') == 'ROBOT_POSITION':
                    # Controller tracking data from Mode 4
                    pos_data = data.get('data', {})
                    print(f"[MODE 4 TRACKING] "
                          f"X: {pos_data.get('x_cm', 0):>7.1f}cm  "
                          f"Z: {pos_data.get('z_cm', 0):>7.1f}cm  "
                          f"Heading: {pos_data.get('heading_deg', 0):>6.1f}°  "
                          f"Dist: {pos_data.get('distance_from_center_cm', 0):>6.1f}cm")
                
                # ── MODE 4: TRACKING STOPPED ─────────────────────────────────────
                elif data.get('command') == 'TRACKING_STOPPED':
                    print(f"\n[MODE 4] Controller tracking stopped\n")
                
                # ── MODE SELECTION ────────────────────────────────────────────────
                elif data.get('command') == 'MODE_SELECTED':
                    mode = data.get('mode', 0)
                    mode_name = data.get('mode_name', 'Unknown')
                    print(f"\n{'='*80}")
                    print(f"  MODE {mode} ACTIVATED: {mode_name}")
                    print(f"{'='*80}\n")
                
                # ── MODE 3: M25 EXECUTION ─────────────────────────────────────────
                elif data.get('command') == 'EXECUTE_M25':
                    start_loc = data.get('start_location', 'Sevenoaks')
                    direction = data.get('direction', 'clockwise')
                    print(f"\n{'='*80}")
                    print(f"  MODE 3: M25 AUTO-DRIVE")
                    print(f"{'='*80}")
                    print(f"  Start: {start_loc}")
                    print(f"  Direction: {direction}")
                    print(f"{'='*80}\n")
                
                # ── MODE 6: START CHARGER UPDATES ─────────────────────────────────
                elif data.get('command') == 'START_CHARGER_UPDATES':
                    print(f"\n{'='*80}")
                    print(f"  MODE 6: EV CHARGER STATUS - STARTING")
                    print(f"{'='*80}\n")
                    
                    # Cancel existing task if any
                    if websocket in charger_update_tasks:
                        charger_update_tasks[websocket].cancel()
                    
                    # Start new charger update loop
                    task = asyncio.create_task(charger_update_loop(websocket))
                    charger_update_tasks[websocket] = task
                
                # ── MODE 6: STOP CHARGER UPDATES ──────────────────────────────────
                elif data.get('command') == 'STOP_CHARGER_UPDATES':
                    print(f"\n[MODE 6] Stopping charger updates\n")
                    
                    if websocket in charger_update_tasks:
                        charger_update_tasks[websocket].cancel()
                        del charger_update_tasks[websocket]
                
            except json.JSONDecodeError:
                pass
            except Exception as e:
                print(f"⚠ Error: {e}")
                import traceback
                traceback.print_exc()
                
    except websockets.exceptions.ConnectionClosed:
        pass
    except Exception as e:
        print(f"⚠ Connection error: {e}")
    finally:
        connected_clients.discard(websocket)
        
        # Cancel charger update task if exists
        if websocket in charger_update_tasks:
            charger_update_tasks[websocket].cancel()
            del charger_update_tasks[websocket]
        
        print(f"\n✗ Quest 3 disconnected: {client_ip}")

# ==============================================================================
# MAIN SERVER
# ==============================================================================

async def main():
    """Start server"""
    # Detect platform
    current_platform = platform.system()
    
    # Initialize Arduino (skipped on Windows)
    arduino_connected = init_arduino()
    
    if not arduino_connected and current_platform != 'Windows':
        print("\n⚠ WARNING: Starting server WITHOUT Arduino connection")
        print("  Commands will be generated but NOT sent to robot")
        print("  Connect Arduino and restart server for robot control\n")
    
    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print("=" * 80)
        print("  ERROR: SSL certificates not found!")
        print("=" * 80)
        print("\n  Generate with:")
        print("  openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \\")
        print("          -days 365 -nodes -subj '/CN=192.168.100.10'")
        print("=" * 80)
        sys.exit(1)
    
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain(CERT_FILE, KEY_FILE)
    
    arduino_status = 'CONNECTED ✓' if arduino_connected else 'NOT CONNECTED ✗'
    if current_platform == 'Windows':
        arduino_status = 'DISABLED (Windows)'
    
    print("=" * 80)
    print("  ROBOT TRAJECTORY COMMAND SERVER")
    print("=" * 80)
    print(f"\n  Platform: {current_platform}")
    print(f"  Server: wss://{HOST}:{PORT}")
    print(f"  Quest 3: Connect via AR app")
    print(f"  Arduino: {arduino_status}")
    print(f"\n  Motor Safety: {MOTOR_MIN}-{MOTOR_MAX}% power")
    print(f"\n  Waiting for Quest 3...")
    print("=" * 80)
    print()
    
    async with websockets.serve(handle_client, HOST, PORT, ssl=ssl_context):
        await asyncio.Future()

# ==============================================================================
# ENTRY POINT
# ==============================================================================

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n" + "=" * 80)
        print("  SERVER STOPPED")
        print("=" * 80)
        
        # Stop robot on exit
        if arduino_serial:
            print("  Stopping robot...")
            send_command_to_arduino(SERVO2_CENTER, 0, 0)
            arduino_serial.close()
            print("  ✓ Robot stopped and Arduino disconnected")
        
        print("=" * 80)
        sys.exit(0)
