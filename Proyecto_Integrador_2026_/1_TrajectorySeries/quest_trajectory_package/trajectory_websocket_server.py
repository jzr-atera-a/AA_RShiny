#!/usr/bin/env python3
"""
Jetson Nano WebSocket Server for Quest 3 Trajectory Drawing
Python 3.6 compatible - WITH NULL SAFETY
"""

import asyncio
import websockets
import ssl
import json
import os
import sys
from datetime import datetime

# ==============================================================================
# CONFIGURATION
# ==============================================================================

HOST = '0.0.0.0'
PORT = 8443
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'
DATA_FILE = 'trajectory_data.json'

# ==============================================================================
# GLOBAL STATE
# ==============================================================================

connected_clients = set()
latest_data = {}
latest_trajectory = None
total_commands = 0
trajectory_updates = 0
start_time = datetime.now()
is_approved = False

# ==============================================================================
# DISPLAY FUNCTIONS
# ==============================================================================

def clear_screen():
    os.system('clear' if os.name == 'posix' else 'cls')

def display_header():
    print("=" * 80)
    print("  QUEST 3 TRAJECTORY DRAWING - JETSON NANO SERVER")
    print("=" * 80)

def display_status():
    status = "APPROVED" if is_approved else "DRAWING"
    status_color = "ORANGE" if is_approved else "GREEN"
    
    print(f"  Connected Clients: {len(connected_clients)}")
    print(f"  Total Commands: {total_commands}")
    print(f"  Trajectory Updates: {trajectory_updates}")
    print(f"  Status: {status} ({status_color})")
    uptime = (datetime.now() - start_time).total_seconds()
    print(f"  Uptime: {int(uptime)}s")
    print("=" * 80)
    print()

def display_trajectory_info():
    """Display trajectory data"""
    if latest_trajectory:
        points = latest_trajectory.get('points', [])
        distance = latest_trajectory.get('totalDistance', 0)
        floor_y = latest_trajectory.get('floorY', 0)
        loops = latest_trajectory.get('loopCount', 0)
        approved = latest_trajectory.get('approved', False)
        
        status_text = "APPROVED" if approved else "Drawing"
        
        print("┌─── TRAJECTORY DATA ────────────────────────────────────────────────────────┐")
        print(f"│ Status: {status_text}".ljust(79) + "│")
        print(f"│ Points: {len(points):4d}  |  Distance: {distance:6.2f}m  |  Loops: {loops}  |  Floor Y: {floor_y:7.3f}".ljust(79) + "│")
        
        if len(points) >= 2:
            p0 = points[0]
            pN = points[-1]
            print(f"│ Start: X={p0['x']:6.2f} Y={p0['y']:6.2f} Z={p0['z']:6.2f}".ljust(79) + "│")
            print(f"│ End:   X={pN['x']:6.2f} Y={pN['y']:6.2f} Z={pN['z']:6.2f}".ljust(79) + "│")
        
        print("└────────────────────────────────────────────────────────────────────────────┘")
    else:
        print("┌─── TRAJECTORY DATA ────────────────────────────────────────────────────────┐")
        print("│ No trajectory - Hold RIGHT TRIGGER on floor to draw".ljust(79) + "│")
        print("└────────────────────────────────────────────────────────────────────────────┘")
    print()

def display_controller_data():
    """Display controller data WITH NULL SAFETY"""
    if not latest_data:
        print("⏳ Waiting for Quest 3 controller data...")
        return
    
    # LEFT Controller - WITH NULL CHECKS
    print("┌─── LEFT CONTROLLER ────────────────────────────────────────────────────────┐")
    if 'controller0' in latest_data and latest_data['controller0'] is not None:
        c0 = latest_data['controller0']
        
        if c0 and 'position' in c0:
            pos = c0['position']
            print(f"│ Position: X={pos['x']:7.3f}  Y={pos['y']:7.3f}  Z={pos['z']:7.3f}".ljust(79) + "│")
        
        if c0 and 'joystick' in c0:
            joy = c0['joystick']
            joy_x = joy.get('x', 0)
            joy_y = joy.get('y', 0)
            print(f"│ 🕹️  Joystick: X={joy_x:+6.3f}  Y={joy_y:+6.3f}".ljust(79) + "│")
        
        if c0 and 'buttons' in c0:
            btns = c0['buttons']
            trigger = btns.get('trigger', 0)
            grip = btns.get('grip', 0)
            x_btn = btns.get('a_x', False)
            y_btn = btns.get('b_y', False)
            stick = btns.get('thumbstick', False)
            
            trig_icon = "🔴" if trigger > 0.5 else "⚪"
            grip_icon = "🔴" if grip > 0.5 else "⚪"
            x_icon = "🔴" if x_btn else "⚪"
            y_icon = "🔴" if y_btn else "⚪"
            stick_icon = "🔴" if stick else "⚪"
            
            print(f"│ {trig_icon} Trigger: {trigger:.2f}  |  {grip_icon} Grip: {grip:.2f}  |  {stick_icon} Stick".ljust(79) + "│")
            print(f"│ {x_icon} X Button  |  {y_icon} Y Button".ljust(79) + "│")
    else:
        print("│ Not detected".ljust(79) + "│")
    print("└────────────────────────────────────────────────────────────────────────────┘")
    print()
    
    # RIGHT Controller - WITH NULL CHECKS
    print("┌─── RIGHT CONTROLLER (DRAWING) ─────────────────────────────────────────────┐")
    if 'controller1' in latest_data and latest_data['controller1'] is not None:
        c1 = latest_data['controller1']
        
        if c1 and 'position' in c1:
            pos = c1['position']
            print(f"│ Position: X={pos['x']:7.3f}  Y={pos['y']:7.3f}  Z={pos['z']:7.3f}".ljust(79) + "│")
        
        if c1 and 'joystick' in c1:
            joy = c1['joystick']
            joy_x = joy.get('x', 0)
            joy_y = joy.get('y', 0)
            print(f"│ 🕹️  Joystick: X={joy_x:+6.3f}  Y={joy_y:+6.3f}".ljust(79) + "│")
        
        if c1 and 'buttons' in c1:
            btns = c1['buttons']
            trigger = btns.get('trigger', 0)
            grip = btns.get('grip', 0)
            a_btn = btns.get('a_x', False)
            b_btn = btns.get('b_y', False)
            stick = btns.get('thumbstick', False)
            
            trig_icon = "🔴" if trigger > 0.5 else "⚪"
            grip_icon = "🔴" if grip > 0.5 else "⚪"
            a_icon = "🔴" if a_btn else "⚪"
            b_icon = "🔴" if b_btn else "⚪"
            stick_icon = "🔴" if stick else "⚪"
            
            print(f"│ {trig_icon} TRIGGER: {trigger:.2f}  |  {grip_icon} GRIP (Approve): {grip:.2f}  |  {stick_icon} STICK (Undo)".ljust(79) + "│")
            print(f"│ {a_icon} A Button  |  {b_icon} B Button".ljust(79) + "│")
    else:
        print("│ Not detected".ljust(79) + "│")
    print("└────────────────────────────────────────────────────────────────────────────┘")
    print()

def refresh_display():
    clear_screen()
    display_header()
    display_status()
    display_trajectory_info()
    display_controller_data()
    print("=" * 80)
    print("  Controls: TRIGGER=Draw | GRIP=Approve | THUMBSTICK=Undo")
    print("  Press Ctrl+C to stop")
    print("=" * 80)

# ==============================================================================
# WEBSOCKET HANDLER
# ==============================================================================

async def handle_client(websocket, path):
    """Handle WebSocket client with NULL SAFETY"""
    global total_commands, trajectory_updates, latest_trajectory, latest_data, is_approved
    
    client_ip = websocket.remote_address[0] if hasattr(websocket, 'remote_address') else 'Unknown'
    connected_clients.add(websocket)
    
    print(f"\n✓ Quest 3 connected: {client_ip}")
    refresh_display()
    
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                total_commands += 1
                latest_data = data
                
                # Check approval status
                if 'approved' in data:
                    is_approved = data['approved']
                
                # Check trajectory data
                if 'trajectory' in data and data['trajectory'] is not None:
                    latest_trajectory = data['trajectory']
                    trajectory_updates += 1
                    
                    save_data = {
                        'timestamp': datetime.now().isoformat(),
                        'trajectory': latest_trajectory,
                        'total_updates': trajectory_updates,
                        'approved': is_approved
                    }
                    
                    with open(DATA_FILE, 'w') as f:
                        json.dump(save_data, f, indent=2)
                
                # Send acknowledgment
                await websocket.send(json.dumps({
                    'type': 'ack',
                    'commands_received': total_commands,
                    'trajectory_updates': trajectory_updates,
                    'timestamp': int(datetime.now().timestamp() * 1000)
                }))
                
                # Update display every 2 commands
                if total_commands % 2 == 0:
                    refresh_display()
                
            except json.JSONDecodeError:
                pass
            except Exception as e:
                print(f"⚠ Error: {e}")
                
    except websockets.exceptions.ConnectionClosed:
        pass
    except Exception as e:
        print(f"⚠ Connection error: {e}")
    finally:
        connected_clients.discard(websocket)
        print(f"\n✗ Quest 3 disconnected: {client_ip}")
        refresh_display()

# ==============================================================================
# MAIN SERVER
# ==============================================================================

async def main():
    """Start server"""
    global start_time
    start_time = datetime.now()
    
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
    
    clear_screen()
    print("=" * 80)
    print("  STARTING TRAJECTORY SERVER")
    print("=" * 80)
    print(f"\n  Server: wss://{HOST}:{PORT}")
    print(f"  Quest 3: https://192.168.100.10:8000/controls_trajectory_drawing.html")
    print("\n  Waiting for Quest 3...")
    print("=" * 80)
    print()
    
    async with websockets.serve(handle_client, HOST, PORT, ssl=ssl_context):
        await asyncio.Future()

# ==============================================================================
# ENTRY POINT - Python 3.6 Compatible
# ==============================================================================

if __name__ == '__main__':
    try:
        loop = asyncio.get_event_loop()
        loop.run_until_complete(main())
    except KeyboardInterrupt:
        print("\n\n" + "=" * 80)
        print("  SERVER STOPPED")
        print("=" * 80)
        print(f"  Total commands: {total_commands}")
        print(f"  Trajectory updates: {trajectory_updates}")
        print(f"  Status: {'APPROVED' if is_approved else 'Drawing'}")
        uptime = (datetime.now() - start_time).total_seconds()
        print(f"  Session time: {uptime:.1f}s")
        print("=" * 80)
        sys.exit(0)
