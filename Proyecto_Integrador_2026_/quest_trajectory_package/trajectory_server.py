#!/usr/bin/env python3
"""
Jetson Nano WebSocket Server for Quest 3 Trajectory Drawing
Receives trajectory data and controller states from Quest 3
"""

import asyncio
import websockets
import ssl
import json
import os
from datetime import datetime

# Configuration
HOST = '0.0.0.0'
PORT = 8443
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'
DATA_FILE = 'trajectory_data.json'

# Global state
connected_clients = set()
latest_trajectory = None
total_commands = 0
trajectory_updates = 0

def display_trajectory_info():
    """Display trajectory information in terminal"""
    os.system('clear' if os.name == 'posix' else 'cls')
    
    print("=" * 80)
    print(" QUEST 3 TRAJECTORY DRAWING - JETSON NANO SERVER")
    print("=" * 80)
    print(f" Connected Clients: {len(connected_clients)}")
    print(f" Total Commands: {total_commands}")
    print(f" Trajectory Updates: {trajectory_updates}")
    print("=" * 80)
    
    if latest_trajectory:
        points = latest_trajectory.get('points', [])
        distance = latest_trajectory.get('totalDistance', 0)
        floor_y = latest_trajectory.get('floorY', 0)
        
        print(f"\n TRAJECTORY DATA:")
        print(f"   Points: {len(points)}")
        print(f"   Total Distance: {distance:.2f} meters")
        print(f"   Floor Level (Y): {floor_y:.3f}")
        
        if len(points) > 0:
            print(f"\n   First Point: X={points[0]['x']:.3f}, Y={points[0]['y']:.3f}, Z={points[0]['z']:.3f}")
            if len(points) > 1:
                print(f"   Last Point:  X={points[-1]['x']:.3f}, Y={points[-1]['y']:.3f}, Z={points[-1]['z']:.3f}")
    
    print("\n" + "=" * 80)
    print(" Press Ctrl+C to stop server")
    print("=" * 80)

async def handle_client(websocket, path):
    """Handle WebSocket client connection"""
    global total_commands, trajectory_updates, latest_trajectory
    
    connected_clients.add(websocket)
    client_ip = websocket.remote_address[0] if hasattr(websocket, 'remote_address') else 'Unknown'
    print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Client connected: {client_ip}")
    display_trajectory_info()
    
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                total_commands += 1
                
                # Check if this is trajectory data
                if 'trajectory' in data:
                    latest_trajectory = data['trajectory']
                    trajectory_updates += 1
                    
                    # Save to file
                    save_data = {
                        'timestamp': datetime.now().isoformat(),
                        'trajectory': latest_trajectory,
                        'total_updates': trajectory_updates
                    }
                    
                    with open(DATA_FILE, 'w') as f:
                        json.dump(save_data, f, indent=2)
                    
                    display_trajectory_info()
                
                # Send acknowledgment
                await websocket.send(json.dumps({
                    'type': 'ack',
                    'commands_received': total_commands,
                    'trajectory_updates': trajectory_updates,
                    'timestamp': int(datetime.now().timestamp() * 1000)
                }))
                
            except json.JSONDecodeError as e:
                print(f"JSON decode error: {e}")
            except Exception as e:
                print(f"Error processing message: {e}")
                
    except websockets.exceptions.ConnectionClosed:
        print(f"\n[{datetime.now().strftime('%H:%M:%S')}] Client disconnected: {client_ip}")
    finally:
        connected_clients.discard(websocket)
        display_trajectory_info()

async def main():
    """Start WebSocket server with SSL"""
    
    # Check for SSL certificates
    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print("=" * 80)
        print("ERROR: SSL certificates not found!")
        print("=" * 80)
        print(f"Expected files: {CERT_FILE} and {KEY_FILE}")
        print("\nGenerate them with:")
        print("  openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \\")
        print("          -days 365 -nodes -subj '/CN=192.168.100.10'")
        print("=" * 80)
        return
    
    # SSL context
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain(CERT_FILE, KEY_FILE)
    
    print("=" * 80)
    print(" STARTING TRAJECTORY DRAWING SERVER")
    print("=" * 80)
    print(f" Host: {HOST}")
    print(f" Port: {PORT}")
    print(f" SSL Cert: {CERT_FILE}")
    print(f" SSL Key: {KEY_FILE}")
    print("=" * 80)
    print("\n Waiting for Quest 3 connection...")
    print(" Server ready!\n")
    
    async with websockets.serve(handle_client, HOST, PORT, ssl=ssl_context):
        await asyncio.Future()  # Run forever

if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n Server stopped by user")
        print(" Goodbye!\n")
