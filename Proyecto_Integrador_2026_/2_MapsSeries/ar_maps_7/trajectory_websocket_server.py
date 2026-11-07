#!/usr/bin/env python3
"""
Jetson Nano WebSocket Server - Robot Trajectory Command Generator
Generates Arduino commands from Quest 3 trajectory at 5Hz
"""

import asyncio
import websockets
import ssl
import json
import os
import sys
import math
import csv
from datetime import datetime

# CONFIG
HOST = '0.0.0.0'
PORT = 8443
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'

# Robot configuration
SERVO2_CENTER = 90  # degrees
SERVO2_MIN = 50     # degrees
SERVO2_MAX = 130    # degrees
MOTOR_MIN = 50      # MD22 power (0-128)
MOTOR_MAX = 90      # MD22 power
MOTOR_STOP = 0
COMMAND_RATE = 5    # Hz (commands per second)
WHEELBASE = 0.34    # meters (34cm between front and rear wheels)

# STATE
connected_clients = set()
start_time = datetime.now()

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
    print(f"{'='*80}\n")
    
    # Interpolate trajectory to match command rate
    # Assume robot moves at average 15cm/s
    avg_speed = 0.15  # m/s
    total_time = total_distance / avg_speed
    num_commands = int(total_time * COMMAND_RATE)
    
    print(f"  Estimated time: {total_time:.1f}s")
    print(f"  Commands to generate: {num_commands}")
    print(f"\n{'='*80}\n")
    
    current_distance = 0
    
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

def save_commands_to_csv(commands, prefix='robot_commands'):
    """Save commands to CSV file"""
    timestamp_str = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f'{prefix}_{timestamp_str}.csv'
    
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

def display_commands(commands):
    """Display commands in terminal"""
    print(f"\n{'='*100}")
    print(f"  ROBOT COMMANDS (5 Hz)")
    print(f"{'='*100}")
    print(f"{'Time':>8} {'DistOrg':>8} {'DistEnd':>8} {'SERVO2':>8} {'MOTOR1':>8} {'MOTOR2':>8}")
    print(f"{'-'*100}")
    
    # Display first 10 commands
    for i, cmd in enumerate(commands[:10]):
        print(f"{cmd['timestamp']:8.3f} {cmd['distance_from_origin']:8.3f} "
              f"{cmd['distance_to_end']:8.3f} {cmd['servo2']:8d} "
              f"{cmd['motor1']:8d} {cmd['motor2']:8d}")
    
    if len(commands) > 20:
        print(f"{'...':^100}")
        # Display last 10 commands
        for cmd in commands[-10:]:
            print(f"{cmd['timestamp']:8.3f} {cmd['distance_from_origin']:8.3f} "
                  f"{cmd['distance_to_end']:8.3f} {cmd['servo2']:8d} "
                  f"{cmd['motor1']:8d} {cmd['motor2']:8d}")
    
    print(f"{'='*100}")
    print(f"  Total commands: {len(commands)}")
    print(f"{'='*100}\n")

# ==============================================================================
# WEBSOCKET HANDLER
# ==============================================================================

async def handle_client(websocket, path):
    """Handle WebSocket client"""
    client_ip = websocket.remote_address[0] if hasattr(websocket, 'remote_address') else 'Unknown'
    connected_clients.add(websocket)
    
    print(f"\n✓ Quest 3 connected: {client_ip}")
    
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                
                if data.get('command') == 'EXECUTE_M25':
                    print(f"\n{'='*80}")
                    print(f"  M25 TRAJECTORY EXECUTION REQUEST")
                    print(f"{'='*80}")
                    print(f"  Start Location: {data.get('start_location', 'Sevenoaks')}")
                    print(f"  Direction: {data.get('direction', 'clockwise')}")
                    print(f"{'='*80}\n")
                    
                    # Load M25 coordinates from GeoJSON
                    try:
                        with open('sample_campus_map.geojson', 'r') as f:
                            geojson = json.load(f)
                        
                        # Find M25 feature
                        m25_feature = next((f for f in geojson['features'] 
                                          if f['properties'].get('heatmap')), None)
                        
                        if not m25_feature:
                            print("⚠ M25 feature not found in GeoJSON!")
                            continue
                        
                        coords = m25_feature['geometry']['coordinates']
                        
                        # Find Sevenoaks index (closest point to Sevenoaks coordinates)
                        sevenoaks_coord = [0.00009, -0.00125]  # From GeoJSON
                        min_dist = float('inf')
                        start_idx = 0
                        
                        for i, coord in enumerate(coords):
                            dist = math.sqrt((coord[0] - sevenoaks_coord[0])**2 + 
                                           (coord[1] - sevenoaks_coord[1])**2)
                            if dist < min_dist:
                                min_dist = dist
                                start_idx = i
                        
                        # Reorder coordinates to start from Sevenoaks (clockwise)
                        m25_coords = coords[start_idx:] + coords[:start_idx]
                        
                        # Convert GeoJSON coords to 3D points (scale to 3×3m AR space)
                        # GeoJSON: ±0.0015 range → AR: ±1.5m range
                        scale_factor = 1.5 / 0.0015
                        points = []
                        for coord in m25_coords:
                            points.append({
                                'x': coord[0] * scale_factor,
                                'y': 0.0,  # Floor level
                                'z': coord[1] * scale_factor
                            })
                        
                        print(f"✓ M25 trajectory loaded: {len(points)} points")
                        print(f"  Starting from index {start_idx} (Sevenoaks)")
                        print(f"  Direction: Clockwise\n")
                        
                        # Generate commands
                        commands = generate_commands(points)
                        
                        # Save to CSV
                        csv_file = save_commands_to_csv(commands, prefix='m25')
                        
                        print(f"✓ M25 commands generated!\n")
                        print(f"\n{'='*100}")
                        print(f"  M25 TRAJECTORY COMMANDS (every 0.2 seconds at 5Hz)")
                        print(f"{'='*100}")
                        print(f"{'Time':>8} {'DistOrg':>10} {'DistEnd':>10}  Command")
                        print(f"{'-'*100}")
                        
                        # Display ALL commands at 0.2s intervals
                        for i, cmd in enumerate(commands):
                            time_at_cmd = i * 0.2  # 0.2 seconds per command
                            print(f"{time_at_cmd:8.1f} {cmd['distance_from_origin']:10.3f} "
                                  f"{cmd['distance_to_end']:10.3f}  SERVO2:{cmd['servo2']} "
                                  f"MOTOR1:{cmd['motor1']} MOTOR2:{cmd['motor2']}")
                        
                        print(f"{'='*100}")
                        print(f"  Total commands: {len(commands)}")
                        print(f"  Total duration: {len(commands) * 0.2:.1f} seconds ({len(commands) * 0.2 / 60:.1f} minutes)")
                        print(f"{'='*100}\n")
                        
                        # Send acknowledgment
                        await websocket.send(json.dumps({
                            'type': 'm25_ready',
                            'command_count': len(commands),
                            'csv_file': csv_file
                        }))
                        
                    except FileNotFoundError:
                        print("⚠ GeoJSON file not found!")
                    except Exception as e:
                        print(f"⚠ Error loading M25: {e}")
                        import traceback
                        traceback.print_exc()
                
                elif data.get('command') == 'MODE_SELECTED':
                    mode = data.get('mode')
                    mode_name = data.get('mode_name', 'Unknown')
                    timestamp = data.get('timestamp', 0)
                    
                    print(f"\n{'='*80}")
                    print(f"  🎮 CONTROL MODE APPROVED")
                    print(f"{'='*80}")
                    print(f"  Mode Number: {mode}")
                    print(f"  Mode Name: {mode_name}")
                    print(f"  Timestamp: {timestamp}")
                    print(f"{'='*80}\n")
                    
                    # Log to file
                    with open('mode_selections.log', 'a') as f:
                        f.write(f"{datetime.now().isoformat()} - Mode {mode}: {mode_name}\n")
                
                elif data.get('command') == 'GENERATE_COMMANDS':
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
                        
                        # Send acknowledgment with command count
                        await websocket.send(json.dumps({
                            'type': 'commands_ready',
                            'command_count': len(commands),
                            'csv_file': csv_file
                        }))
                        
                        print(f"✓ Commands generated and saved!\n")
                        print(f"\n{'='*100}")
                        print(f"  STREAMING COMMANDS TO ARDUINO (5 Hz)")
                        print(f"{'='*100}")
                        print(f"{'Time':>8} {'DistOrg':>8} {'DistEnd':>8} {'SERVO2':>8} {'MOTOR1':>8} {'MOTOR2':>8}")
                        print(f"{'-'*100}")
                        
                        # Stream commands in real-time at 5Hz
                        for cmd in commands:
                            # Display command
                            print(f"{cmd['timestamp']:8.3f} {cmd['distance_from_origin']:8.3f} "
                                  f"{cmd['distance_to_end']:8.3f} {cmd['servo2']:8d} "
                                  f"{cmd['motor1']:8d} {cmd['motor2']:8d}")
                            
                            # Send command to Quest 3 (for monitoring)
                            await websocket.send(json.dumps({
                                'type': 'command_execute',
                                'timestamp': cmd['timestamp'],
                                'servo2': cmd['servo2'],
                                'motor1': cmd['motor1'],
                                'motor2': cmd['motor2'],
                                'distance_remaining': cmd['distance_to_end']
                            }))
                            
                            # TODO: Send to Arduino via serial here
                            # Example: serial_port.write(f"S{cmd['servo2']},M1:{cmd['motor1']},M2:{cmd['motor2']}\n".encode())
                            
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
        print(f"\n✗ Quest 3 disconnected: {client_ip}")

# ==============================================================================
# MAIN SERVER
# ==============================================================================

async def main():
    """Start server"""
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
    
    print("=" * 80)
    print("  ROBOT COMMAND SERVER")
    print("=" * 80)
    print(f"\n  Server: wss://{HOST}:{PORT}")
    print(f"  Quest 3: https://192.168.100.10:8000/trajectory_commands.html")
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
        loop = asyncio.get_event_loop()
        loop.run_until_complete(main())
    except KeyboardInterrupt:
        print("\n\n" + "=" * 80)
        print("  SERVER STOPPED")
        print("=" * 80)
        sys.exit(0)
