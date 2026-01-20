#!/usr/bin/env python3
"""
Quest 3 to Arduino Actuator Control via Jetson Nano
WebSocket server that receives joystick/button data and controls servos + motors via serial

LEFT Controller:
  - Joystick Y-axis → Motor1 & Motor2 speed (50-90% forward)
  
RIGHT Controller:
  - Joystick X-axis → Servo2 (Pin 9): Steering (50-130°)
  - A/B Buttons → Servo1 (Pin 8): Control (40-140°)
"""

import asyncio
import websockets
import ssl
import json
import sys
import os
import serial
import time
from datetime import datetime

# ==============================================================================
# CONFIGURATION
# ==============================================================================

HOST = '0.0.0.0'
PORT = 8443
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'

# Arduino Serial Configuration
ARDUINO_PORT = '/dev/ttyACM0'  # Change to /dev/ttyUSB0 if needed
ARDUINO_BAUD = 115200

# Servo1 (A/B Buttons) Configuration
SERVO1_MIN = 40
SERVO1_MAX = 140
SERVO1_SPEED_DOWN = 50  # degrees/second (10° per 0.2s)
SERVO1_SPEED_UP = 100   # degrees/second (20° per 0.2s)

# Servo2 (RIGHT Joystick X) Configuration
JOYSTICK_MIN = -1.0
JOYSTICK_MAX = 1.0
SERVO2_MIN = 50
SERVO2_CENTER = 90
SERVO2_MAX = 130

# Motor Configuration (LEFT Joystick Y)
MOTOR_MIN_PERCENT = 50  # Motors don't move below 50%
MOTOR_MAX_PERCENT = 90  # 100% would pull too much current
MOTOR_DEADZONE = 0.10   # 10% deadzone to prevent accidental movement

# ==============================================================================
# GLOBAL STATE
# ==============================================================================

connected_clients = set()
latest_data = {}
total_commands = 0
servo1_updates = 0
servo2_updates = 0
motor_updates = 0
start_time = datetime.now()
arduino_serial = None

# Servo states
servo1_angle = 90
servo2_angle = 90
button_a_pressed = False
button_b_pressed = False
button_press_start_time = 0

# Motor states
current_motor_speed = 0
last_motor_speed = 0

# ==============================================================================
# ARDUINO SERIAL FUNCTIONS
# ==============================================================================

def init_arduino():
    """Initialize serial connection to Arduino"""
    global arduino_serial
    
    try:
        arduino_serial = serial.Serial(ARDUINO_PORT, ARDUINO_BAUD, timeout=1)
        time.sleep(2)  # Wait for Arduino reset
        
        # Read startup messages
        print("\nArduino startup messages:")
        for _ in range(15):
            if arduino_serial.in_waiting:
                line = arduino_serial.readline().decode().strip()
                if line:
                    print(f"  {line}")
        
        print(f"✓ Arduino connected on {ARDUINO_PORT}")
        
        # Center both servos and stop motors on startup
        send_servo1_command(90)
        send_servo2_command(90)
        send_motors_command(0)
        return True
        
    except serial.SerialException as e:
        print(f"✗ Arduino connection failed: {e}")
        print(f"  Make sure Arduino is connected to {ARDUINO_PORT}")
        arduino_serial = None
        return False

def send_servo1_command(angle):
    """Send servo1 angle command to Arduino"""
    global servo1_angle, servo1_updates
    
    if not arduino_serial:
        return False
    
    try:
        # Clamp to valid range
        angle = max(SERVO1_MIN, min(SERVO1_MAX, int(angle)))
        
        # Only send if angle changed significantly
        if abs(angle - servo1_angle) < 2:
            return True
        
        # Flush input buffer before sending
        arduino_serial.reset_input_buffer()
        
        # Send command
        command = f"SERVO1:{angle}\n"
        arduino_serial.write(command.encode())
        arduino_serial.flush()
        servo1_angle = angle
        servo1_updates += 1
        
        # Read response with timeout protection
        time.sleep(0.005)
        attempts = 0
        while arduino_serial.in_waiting and attempts < 3:
            try:
                response = arduino_serial.readline().decode('utf-8', errors='ignore').strip()
                if response and 'OK' in response:
                    if servo1_updates % 10 == 0:
                        print(f"  Servo1: {angle}°")
                    break
            except (UnicodeDecodeError, serial.SerialException):
                break
            attempts += 1
        
        return True
        
    except (serial.SerialException, OSError) as e:
        print(f"✗ Servo1 serial error: {e}")
        return False
    except Exception as e:
        print(f"✗ Servo1 error: {e}")
        return False

def send_servo2_command(angle):
    """Send servo2 angle command to Arduino"""
    global servo2_angle, servo2_updates
    
    if not arduino_serial:
        return False
    
    try:
        # Clamp to valid range
        angle = max(SERVO2_MIN, min(SERVO2_MAX, int(angle)))
        
        # Only send if angle changed significantly
        if abs(angle - servo2_angle) < 2:
            return True
        
        # Flush input buffer before sending
        arduino_serial.reset_input_buffer()
        
        # Send command
        command = f"SERVO2:{angle}\n"
        arduino_serial.write(command.encode())
        arduino_serial.flush()
        servo2_angle = angle
        servo2_updates += 1
        
        # Read response with timeout protection
        time.sleep(0.005)
        attempts = 0
        while arduino_serial.in_waiting and attempts < 3:
            try:
                response = arduino_serial.readline().decode('utf-8', errors='ignore').strip()
                if response and 'OK' in response:
                    if servo2_updates % 10 == 0:
                        print(f"  Servo2: {angle}°")
                    break
            except (UnicodeDecodeError, serial.SerialException):
                break
            attempts += 1
        
        return True
        
    except (serial.SerialException, OSError) as e:
        print(f"✗ Servo2 serial error: {e}")
        return False
    except Exception as e:
        print(f"✗ Servo2 error: {e}")
        return False

def send_motors_command(speed):
    """
    Send motor speed command to Arduino
    Speed: 0 (stop) or 50-90 (percent forward)
    """
    global current_motor_speed, motor_updates, last_motor_speed
    
    if not arduino_serial:
        return False
    
    try:
        # Clamp to valid range
        if speed <= 0:
            speed = 0
        else:
            speed = max(MOTOR_MIN_PERCENT, min(MOTOR_MAX_PERCENT, int(speed)))
        
        # Only send if speed changed significantly (reduce serial traffic)
        if abs(speed - last_motor_speed) < 3:
            return True
        
        # Send command
        if speed == 0:
            command = "STOP_ALL_MOTORS\n"
        else:
            command = f"MOTORS:{speed}\n"
        
        # Flush any pending data before sending
        arduino_serial.reset_input_buffer()
        arduino_serial.write(command.encode())
        arduino_serial.flush()  # Ensure data is sent
        
        current_motor_speed = speed
        last_motor_speed = speed
        motor_updates += 1
        
        # Read response with timeout protection
        time.sleep(0.005)  # Reduced delay
        attempts = 0
        while arduino_serial.in_waiting and attempts < 3:
            try:
                response = arduino_serial.readline().decode('utf-8', errors='ignore').strip()
                if response and ('OK' in response or 'stopped' in response or 'Motors' in response):
                    if motor_updates % 10 == 0:  # Print every 10th update to reduce spam
                        print(f"  Motors: {speed}%")
                    break
            except (UnicodeDecodeError, serial.SerialException):
                break
            attempts += 1
        
        return True
        
    except serial.SerialException as e:
        print(f"✗ Serial error in motor command: {e}")
        print(f"  Attempting to recover...")
        return False
    except OSError as e:
        print(f"✗ I/O error in motor command: {e}")
        print(f"  Attempting to recover...")
        return False
    except Exception as e:
        print(f"✗ Unexpected motor error: {e}")
        return False

def joystick_to_servo2_angle(joystick_x):
    """
    Map joystick X (-1.0 to +1.0) to servo2 angle (50° to 130°)
    """
    normalized = (joystick_x + 1.0) / 2.0  # Convert -1..1 to 0..1
    angle = SERVO2_MIN + normalized * (SERVO2_MAX - SERVO2_MIN)
    return int(angle)

def joystick_y_to_motor_speed(joystick_y):
    """
    Map LEFT joystick Y to motor speed (50-90%)
    
    Joystick Y:
      - Resting (0.0) → STOP (0%)
      - Forward (+1.0) → MAX (90%)
      - Deadzone: ±10% to prevent accidental movement
    
    Returns: 0 (stop) or 50-90 (percent forward)
    """
    # Apply deadzone
    if abs(joystick_y) < MOTOR_DEADZONE:
        return 0  # Stop motors
    
    # Only accept positive Y (forward motion)
    if joystick_y <= 0:
        return 0  # No backward motion
    
    # Map positive Y (0.1 to 1.0) to speed (50% to 90%)
    # Remove deadzone from calculation
    adjusted_y = (joystick_y - MOTOR_DEADZONE) / (1.0 - MOTOR_DEADZONE)
    adjusted_y = max(0.0, min(1.0, adjusted_y))
    
    # Map to motor speed range (50-90%)
    speed = MOTOR_MIN_PERCENT + adjusted_y * (MOTOR_MAX_PERCENT - MOTOR_MIN_PERCENT)
    
    return int(speed)

def update_servo1_from_buttons(button_a, button_b):
    """
    Update servo1 based on A/B button state
    A button: Move toward 40° at 50°/s
    B button: Move toward 140° at 100°/s
    """
    global servo1_angle, button_a_pressed, button_b_pressed, button_press_start_time
    
    current_time = time.time()
    
    # Button A pressed - move down toward 40°
    if button_a and not button_a_pressed:
        # Button just pressed
        button_a_pressed = True
        button_press_start_time = current_time
    elif button_a and button_a_pressed:
        # Button being held - calculate movement
        elapsed = current_time - button_press_start_time
        degrees_to_move = SERVO1_SPEED_DOWN * elapsed
        new_angle = max(SERVO1_MIN, servo1_angle - degrees_to_move)
        
        if new_angle != servo1_angle:
            send_servo1_command(new_angle)
            button_press_start_time = current_time
    elif not button_a and button_a_pressed:
        # Button released
        button_a_pressed = False
    
    # Button B pressed - move up toward 140°
    if button_b and not button_b_pressed:
        # Button just pressed
        button_b_pressed = True
        button_press_start_time = current_time
    elif button_b and button_b_pressed:
        # Button being held - calculate movement
        elapsed = current_time - button_press_start_time
        degrees_to_move = SERVO1_SPEED_UP * elapsed
        new_angle = min(SERVO1_MAX, servo1_angle + degrees_to_move)
        
        if new_angle != servo1_angle:
            send_servo1_command(new_angle)
            button_press_start_time = current_time
    elif not button_b and button_b_pressed:
        # Button released
        button_b_pressed = False

# ==============================================================================
# TERMINAL DISPLAY
# ==============================================================================

def clear_screen():
    os.system('clear')

def display_header():
    print("=" * 80)
    print("  QUEST 3 → ARDUINO DUAL SERVO + MD22 MOTOR CONTROL")
    print("=" * 80)
    print(f"  WebSocket: wss://192.168.100.10:{PORT}")
    print(f"  Arduino: {ARDUINO_PORT} @ {ARDUINO_BAUD} baud")
    print(f"  LEFT Joystick Y → Motors (50-90%)")
    print(f"  RIGHT Joystick X → Servo2/Steering ({SERVO2_MIN}-{SERVO2_MAX}°)")
    print(f"  RIGHT A/B Buttons → Servo1 ({SERVO1_MIN}-{SERVO1_MAX}°)")
    print("=" * 80)
    print()

def display_status():
    uptime = (datetime.now() - start_time).total_seconds()
    rate = total_commands / uptime if uptime > 0 else 0
    
    print(f"┌{'─' * 78}┐")
    status = '🟢 CONNECTED' if connected_clients else '🔴 WAITING'
    print(f"│ STATUS: {status}".ljust(79) + "│")
    print(f"│ Commands: {total_commands} | Rate: {rate:.1f}/s".ljust(79) + "│")
    arduino_status = '✅ Connected' if arduino_serial else '❌ Disconnected'
    print(f"│ Arduino: {arduino_status}".ljust(79) + "│")
    print(f"│ Motors: {current_motor_speed:3d}% | Updates: {motor_updates}".ljust(79) + "│")
    print(f"│ Servo1: {servo1_angle:3d}° | Updates: {servo1_updates}".ljust(79) + "│")
    print(f"│ Servo2: {servo2_angle:3d}° | Updates: {servo2_updates}".ljust(79) + "│")
    print(f"└{'─' * 78}┘")
    print()

def display_controller_data():
    if not latest_data:
        print("⏳ Waiting for Quest 3 controller data...")
        return
    
    # LEFT Controller - Motors
    print("┌─── LEFT CONTROLLER (MOTORS) ──────────────────────────────────────────────┐")
    if 'controller0' in latest_data:
        c0 = latest_data['controller0']
        
        # Motor control - Joystick Y
        if 'joystick' in c0:
            joy = c0['joystick']
            joy_y = joy.get('y', 0)
            
            print(f"│ MOTORS (MD22) - Joystick Y Control".ljust(79) + "│")
            print(f"│ 🕹️  Joystick Y: {joy_y:+7.3f}  →  Motors: {current_motor_speed:3d}%".ljust(79) + "│")
            
            # Visual bar
            bar_length = 40
            if joy_y > 0:
                bar_pos = int(joy_y * bar_length)
            else:
                bar_pos = 0
            bar = ['─'] * bar_length
            if bar_pos > 0:
                bar[bar_pos-1] = '●'
            print(f"│      REST {''.join(bar)} FORWARD".ljust(79) + "│")
            print(f"│        0%               50%                90%".ljust(79) + "│")
            print(f"│      DEADZONE: ±{int(MOTOR_DEADZONE*100)}%  |  Range: {MOTOR_MIN_PERCENT}-{MOTOR_MAX_PERCENT}%".ljust(79) + "│")
    else:
        print("│ No data".ljust(79) + "│")
    print("└──────────────────────────────────────────────────────────────────────────┘")
    print()
    
    # RIGHT Controller - Servos
    print("┌─── RIGHT CONTROLLER (SERVOS) ─────────────────────────────────────────────┐")
    if 'controller1' in latest_data:
        c1 = latest_data['controller1']
        
        # Servo2 - Joystick control (steering)
        if 'joystick' in c1:
            joy = c1['joystick']
            joy_x = joy.get('x', 0)
            
            print(f"│ SERVO2 (Pin 9) - Joystick X Control (STEERING)".ljust(79) + "│")
            print(f"│ 🕹️  Joystick X: {joy_x:+7.3f}  →  Servo2: {servo2_angle:3d}°".ljust(79) + "│")
            
            # Visual bar
            bar_length = 40
            bar_pos = int((joy_x + 1.0) / 2.0 * bar_length)
            bar = ['─'] * bar_length
            bar[bar_pos] = '●'
            print(f"│      LEFT {''.join(bar)} RIGHT".ljust(79) + "│")
            print(f"│       50°                90°               130°".ljust(79) + "│")
            print(f"│".ljust(79) + "│")
        
        # Servo1 - Button control
        print(f"│ SERVO1 (Pin 8) - A/B Button Control: {servo1_angle:3d}°".ljust(79) + "│")
        if 'buttons' in c1:
            btns = c1['buttons']
            a_pressed = btns.get('a_x', False)
            b_pressed = btns.get('b_y', False)
            
            a = "🔴" if a_pressed else "⚪"
            b = "🔴" if b_pressed else "⚪"
            
            print(f"│ {a} A (Down/40°)  |  {b} B (Up/140°)".ljust(79) + "│")
            
            # Visual bar for servo1
            bar_length = 40
            if servo1_angle >= SERVO1_MIN and servo1_angle <= SERVO1_MAX:
                bar_pos = int((servo1_angle - SERVO1_MIN) / (SERVO1_MAX - SERVO1_MIN) * bar_length)
            else:
                bar_pos = 20
            bar = ['─'] * bar_length
            bar[bar_pos] = '●'
            print(f"│      {''.join(bar)}".ljust(79) + "│")
            print(f"│       40°                90°               140°".ljust(79) + "│")
    else:
        print("│ No data".ljust(79) + "│")
    print("└──────────────────────────────────────────────────────────────────────────┘")
    print()

def refresh_display():
    clear_screen()
    display_header()
    display_status()
    display_controller_data()
    print("Press Ctrl+C to stop")

# ==============================================================================
# WEBSOCKET HANDLER
# ==============================================================================

async def handle_client(websocket, path):
    """Handle WebSocket client connection"""
    global total_commands, latest_data, arduino_serial
    
    client_ip = websocket.remote_address[0] if hasattr(websocket, 'remote_address') else 'Unknown'
    connected_clients.add(websocket)
    
    print(f"\n✓ Quest 3 connected: {client_ip}")
    refresh_display()
    
    try:
        async for message in websocket:
            try:
                data = json.loads(message)
                latest_data = data
                total_commands += 1
                
                # Check if Arduino connection is still alive
                if arduino_serial and not arduino_serial.is_open:
                    print("\n⚠️  Arduino connection lost, attempting reconnect...")
                    init_arduino()
                
                # Process LEFT controller (controller0) - Motors
                if 'controller0' in data:
                    c0 = data['controller0']
                    
                    # Motor control - Joystick Y
                    if 'joystick' in c0:
                        joystick_y = c0['joystick'].get('y', 0)
                        motor_speed = joystick_y_to_motor_speed(joystick_y)
                        send_motors_command(motor_speed)
                
                # Process RIGHT controller (controller1) - Servos
                if 'controller1' in data:
                    c1 = data['controller1']
                    
                    # Servo2 - Joystick X control (steering)
                    if 'joystick' in c1:
                        joystick_x = c1['joystick'].get('x', 0)
                        servo2_target = joystick_to_servo2_angle(joystick_x)
                        send_servo2_command(servo2_target)
                    
                    # Servo1 - A/B button control
                    if 'buttons' in c1:
                        button_a = c1['buttons'].get('a_x', False)
                        button_b = c1['buttons'].get('b_y', False)
                        update_servo1_from_buttons(button_a, button_b)
                    
                    # Send feedback to Quest 3
                    try:
                        await websocket.send(json.dumps({
                            'servo1_angle': servo1_angle,
                            'servo2_angle': servo2_angle,
                            'motor_speed': current_motor_speed
                        }))
                    except Exception as send_error:
                        print(f"⚠ Error sending feedback: {send_error}")
                
                # Update display every 5 commands (reduced frequency)
                if total_commands % 5 == 0:
                    refresh_display()
                
            except json.JSONDecodeError:
                pass
            except serial.SerialException as e:
                print(f"⚠ Serial error in handler: {e}")
                # Don't crash, just log and continue
            except Exception as e:
                print(f"⚠ Error processing message: {e}")
    
    except websockets.exceptions.ConnectionClosed:
        print(f"\n✗ Quest 3 disconnected cleanly: {client_ip}")
    except Exception as e:
        print(f"\n✗ Quest 3 connection error: {client_ip} - {e}")
    finally:
        connected_clients.discard(websocket)
        print(f"\n✗ Quest 3 disconnected: {client_ip}")
        refresh_display()

# ==============================================================================
# MAIN SERVER
# ==============================================================================

async def main():
    global start_time
    start_time = datetime.now()
    
    # Check SSL certificates
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
    
    # Initialize Arduino
    print("Initializing Arduino connection...")
    arduino_ok = init_arduino()
    if not arduino_ok:
        print("\n⚠️  WARNING: Continuing without Arduino")
        print("   Servo and motor control will not work until Arduino is connected\n")
    
    clear_screen()
    print("=" * 80)
    print("  STARTING WEBSOCKET SERVER")
    print("=" * 80)
    print(f"\n  Server: wss://{HOST}:{PORT}")
    print(f"  Quest 3 URL: https://192.168.100.10:8000/actuators.html")
    print("\n  Waiting for Quest 3 connection...")
    print("=" * 80)
    print()
    
    async with websockets.serve(handle_client, HOST, PORT, ssl=ssl_context):
        await asyncio.Future()

# ==============================================================================
# ENTRY POINT - Compatible with Python 3.6
# ==============================================================================

if __name__ == "__main__":
    try:
        loop = asyncio.get_event_loop()
        loop.run_until_complete(main())
    except KeyboardInterrupt:
        print("\n\n" + "=" * 80)
        print("  SERVER STOPPED")
        print("=" * 80)
        print(f"  Total commands: {total_commands}")
        print(f"  Servo1 updates: {servo1_updates}")
        print(f"  Servo2 updates: {servo2_updates}")
        print(f"  Motor updates: {motor_updates}")
        print(f"  Session time: {(datetime.now() - start_time).total_seconds():.1f}s")
        print("=" * 80)
        if arduino_serial:
            # Stop motors before closing
            try:
                arduino_serial.write(b"STOP_ALL_MOTORS\n")
                time.sleep(0.1)
            except:
                pass
            arduino_serial.close()
            print("  Arduino connection closed (motors stopped)")
        sys.exit(0)
