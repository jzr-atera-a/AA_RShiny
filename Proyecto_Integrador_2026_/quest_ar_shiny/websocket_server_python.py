#!/usr/bin/env python3
"""
==============================================================================
PYTHON WEBSOCKET SERVER WITH SSL FOR QUEST 3 CONTROLLER DATA
==============================================================================
This server:
- Accepts WebSocket connections over SSL (WSS)
- Receives controller data from Quest 3
- Displays real-time metrics in terminal
- Saves data to file for other programs to read
- Can forward commands to Jetson Nano later

Usage:
    python3 websocket_server_python.py
==============================================================================
"""

import asyncio
import websockets
import ssl
import json
import sys
import os
from datetime import datetime
from pathlib import Path

# ==============================================================================
# CONFIGURATION
# ==============================================================================

HOST = '0.0.0.0'  # Listen on all interfaces
PORT = 8443       # SSL WebSocket port
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'
DATA_FILE = 'quest_data.json'

# ==============================================================================
# GLOBAL STATE
# ==============================================================================

connected_clients = set()
latest_data = {}
total_commands = 0
start_time = datetime.now()

# ==============================================================================
# TERMINAL DISPLAY
# ==============================================================================

def clear_screen():
    """Clear terminal screen"""
    os.system('cls' if os.name == 'nt' else 'clear')

def display_header():
    """Display server header"""
    print("=" * 80)
    print("  QUEST 3 CONTROLLER DATA - PYTHON WEBSOCKET SERVER")
    print("=" * 80)
    print(f"  Server: wss://YOUR_IP:{PORT}")
    print(f"  Started: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"  Data saved to: {DATA_FILE}")
    print("=" * 80)
    print()

def display_status():
    """Display current connection and data status"""
    uptime = (datetime.now() - start_time).total_seconds()
    rate = total_commands / uptime if uptime > 0 else 0
    
    print(f"┌{'─' * 78}┐")
    print(f"│ STATUS: {'🟢 CONNECTED' if connected_clients else '🔴 WAITING'}".ljust(79) + "│")
    print(f"│ Clients Connected: {len(connected_clients)}".ljust(79) + "│")
    print(f"│ Total Commands: {total_commands}".ljust(79) + "│")
    print(f"│ Commands/sec: {rate:.1f}".ljust(79) + "│")
    print(f"│ Uptime: {int(uptime)}s".ljust(79) + "│")
    print(f"└{'─' * 78}┘")
    print()

def display_controller_data():
    """Display controller data"""
    if not latest_data:
        print("⏳ Waiting for controller data...")
        return
    
    # Right Controller
    print("┌─── RIGHT CONTROLLER ─────────────────────────────────────────────────────┐")
    if 'controller1' in latest_data:
        c1 = latest_data['controller1']
        pos = c1.get('position', {})
        rot = c1.get('rotation', {})
        
        print(f"│ Position: X={pos.get('x', 0):7.3f}  Y={pos.get('y', 0):7.3f}  Z={pos.get('z', 0):7.3f}".ljust(79) + "│")
        print(f"│ Rotation: X={rot.get('x', 0):7.3f}  Y={rot.get('y', 0):7.3f}  Z={rot.get('z', 0):7.3f}".ljust(79) + "│")
        
        if 'joystick' in c1:
            joy = c1['joystick']
            print(f"│ 🕹️  Joystick: X={joy.get('x', 0):+6.3f}  Y={joy.get('y', 0):+6.3f}".ljust(80) + "│")
        
        if 'buttons' in c1:
            btns = c1['buttons']
            trigger_icon = "●" if btns.get('trigger', 0) > 0.5 else "○"
            grip_icon = "●" if btns.get('grip', 0) > 0.5 else "○"
            a_icon = "●" if btns.get('a_x', False) else "○"
            b_icon = "●" if btns.get('b_y', False) else "○"
            stick_icon = "●" if btns.get('thumbstick', False) else "○"
            
            print(f"│ Trigger: {trigger_icon} {btns.get('trigger', 0):.2f}  Grip: {grip_icon} {btns.get('grip', 0):.2f}".ljust(79) + "│")
            print(f"│ Buttons: A:{a_icon}  B:{b_icon}  Stick:{stick_icon}".ljust(79) + "│")
    else:
        print("│ No data".ljust(79) + "│")
    print("└──────────────────────────────────────────────────────────────────────────┘")
    print()
    
    # Left Controller
    print("┌─── LEFT CONTROLLER ──────────────────────────────────────────────────────┐")
    if 'controller2' in latest_data:
        c2 = latest_data['controller2']
        pos = c2.get('position', {})
        rot = c2.get('rotation', {})
        
        print(f"│ Position: X={pos.get('x', 0):7.3f}  Y={pos.get('y', 0):7.3f}  Z={pos.get('z', 0):7.3f}".ljust(79) + "│")
        print(f"│ Rotation: X={rot.get('x', 0):7.3f}  Y={rot.get('y', 0):7.3f}  Z={rot.get('z', 0):7.3f}".ljust(79) + "│")
        
        if 'joystick' in c2:
            joy = c2['joystick']
            print(f"│ 🕹️  Joystick: X={joy.get('x', 0):+6.3f}  Y={joy.get('y', 0):+6.3f}".ljust(80) + "│")
        
        if 'buttons' in c2:
            btns = c2['buttons']
            trigger_icon = "●" if btns.get('trigger', 0) > 0.5 else "○"
            grip_icon = "●" if btns.get('grip', 0) > 0.5 else "○"
            x_icon = "●" if btns.get('a_x', False) else "○"
            y_icon = "●" if btns.get('b_y', False) else "○"
            stick_icon = "●" if btns.get('thumbstick', False) else "○"
            
            print(f"│ Trigger: {trigger_icon} {btns.get('trigger', 0):.2f}  Grip: {grip_icon} {btns.get('grip', 0):.2f}".ljust(79) + "│")
            print(f"│ Buttons: X:{x_icon}  Y:{y_icon}  Stick:{stick_icon}".ljust(79) + "│")
    else:
        print("│ No data".ljust(79) + "│")
    print("└──────────────────────────────────────────────────────────────────────────┘")
    print()
    
    # Velocity (if calculated)
    if 'velocity' in latest_data:
        vel = latest_data['velocity']
        print("┌─── CALCULATED VELOCITY ──────────────────────────────────────────────────┐")
        print(f"│ Linear:  {vel.get('linear', 0):+7.3f} m/s".ljust(79) + "│")
        print(f"│ Angular: {vel.get('angular', 0):+7.3f} rad/s".ljust(79) + "│")
        print("└──────────────────────────────────────────────────────────────────────────┘")
        print()

def refresh_display():
    """Refresh the entire display"""
    clear_screen()
    display_header()
    display_status()
    display_controller_data()
    print("Press Ctrl+C to stop")

# ==============================================================================
# WEBSOCKET HANDLERS
# ==============================================================================

async def handle_client(websocket):
    """Handle a WebSocket client connection"""
    global total_commands, latest_data
    
    client_ip = websocket.remote_address[0] if hasattr(websocket, 'remote_address') else 'Unknown'
    connected_clients.add(websocket)
    
    print(f"\n✓ Client connected: {client_ip}")
    refresh_display()
    
    try:
        async for message in websocket:
            try:
                # Parse JSON data
                data = json.loads(message)
                
                # Update latest data
                latest_data = data
                total_commands += 1
                
                # Save to file
                with open(DATA_FILE, 'w') as f:
                    json.dump({
                        'data': data,
                        'timestamp': datetime.now().isoformat(),
                        'total_commands': total_commands
                    }, f, indent=2)
                
                # Refresh display every 3 commands (to avoid flickering)
                if total_commands % 3 == 0:
                    refresh_display()
                
            except json.JSONDecodeError:
                print(f"⚠ Invalid JSON received: {message[:100]}")
            except Exception as e:
                print(f"⚠ Error processing message: {e}")
    
    except websockets.exceptions.ConnectionClosed:
        pass
    finally:
        connected_clients.remove(websocket)
        print(f"\n✗ Client disconnected: {client_ip}")
        refresh_display()

# ==============================================================================
# SSL SETUP
# ==============================================================================

def setup_ssl():
    """Setup SSL context for secure WebSocket"""
    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print("=" * 80)
        print("  ERROR: SSL certificates not found!")
        print("=" * 80)
        print()
        print("  You need cert.pem and key.pem in the current directory.")
        print()
        print("  Generate them with:")
        print("  openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \\")
        print("          -days 365 -nodes -subj '/CN=localhost'")
        print()
        print("  OR use the generate_cert.py script from earlier.")
        print("=" * 80)
        sys.exit(1)
    
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain(CERT_FILE, KEY_FILE)
    
    return ssl_context

# ==============================================================================
# MAIN SERVER
# ==============================================================================

async def main():
    """Main server loop"""
    global start_time
    start_time = datetime.now()
    
    # Setup SSL
    ssl_context = setup_ssl()
    
    # Get local IP for display
    import socket
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    
    clear_screen()
    print("=" * 80)
    print("  STARTING PYTHON WEBSOCKET SERVER WITH SSL")
    print("=" * 80)
    print()
    print(f"  ✓ SSL certificates loaded")
    print(f"  ✓ Server starting on {HOST}:{PORT}")
    print(f"  ✓ Local IP: {local_ip}")
    print()
    print("  Quest 3 should connect to:")
    print(f"  wss://{local_ip}:{PORT}")
    print()
    print("  Waiting for connections...")
    print("=" * 80)
    print()
    
    # Start WebSocket server
    async with websockets.serve(handle_client, HOST, PORT, ssl=ssl_context):
        await asyncio.Future()  # Run forever

# ==============================================================================
# ENTRY POINT
# ==============================================================================

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n" + "=" * 80)
        print("  SERVER STOPPED")
        print("=" * 80)
        print(f"  Total commands received: {total_commands}")
        print(f"  Session duration: {(datetime.now() - start_time).total_seconds():.1f}s")
        print("=" * 80)
        sys.exit(0)
