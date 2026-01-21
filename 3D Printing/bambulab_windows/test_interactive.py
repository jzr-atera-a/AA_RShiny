#!/usr/bin/env python3
"""
Interactive MQTT Connection Tester
No batch file needed - just run: python test_interactive.py
"""

import sys
import socket
import ssl
import time

def print_header():
    print("=" * 60)
    print("BAMBULAB PRINTER CONNECTION TESTER")
    print("=" * 60)
    print()

def get_input(prompt, default=None):
    """Get input with optional default"""
    if default:
        user_input = input(f"{prompt} [{default}]: ").strip()
        return user_input if user_input else default
    else:
        user_input = input(f"{prompt}: ").strip()
        return user_input

def test_port(ip, port=8883):
    """Test if port is accessible"""
    print(f"\n[1/3] Testing port {port} on {ip}...")
    print("-" * 60)
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((ip, port))
        sock.close()
        
        if result == 0:
            print(f"✓ Port {port} is OPEN")
            return True
        else:
            print(f"✗ Port {port} is CLOSED or blocked")
            print(f"\n  Common causes:")
            print(f"  • Windows Firewall blocking port {port}")
            print(f"  • Antivirus blocking connection")
            print(f"  • Printer's MQTT service not running")
            return False
    except Exception as e:
        print(f"✗ Cannot reach port {port}: {e}")
        return False

def test_mqtt_connection(ip, access_code, serial):
    """Test full MQTT connection"""
    print(f"\n[2/3] Testing MQTT connection...")
    print("-" * 60)
    
    try:
        import paho.mqtt.client as mqtt
    except ImportError:
        print("✗ paho-mqtt not installed!")
        print("\nRun: python -m pip install paho-mqtt")
        return False
    
    connected = [False]
    error_info = [None]
    
    def on_connect(client, userdata, flags, rc):
        if rc == 0:
            print("✓ MQTT connection SUCCESSFUL!")
            connected[0] = True
        else:
            errors = {
                1: "Incorrect protocol version",
                2: "Invalid client ID",
                3: "Server unavailable",
                4: "Bad username or password - CHECK ACCESS CODE!",
                5: "Not authorized - CHECK ACCESS CODE!"
            }
            msg = errors.get(rc, f"Unknown error {rc}")
            print(f"✗ Connection failed: {msg}")
            error_info[0] = (rc, msg)
    
    try:
        client = mqtt.Client(client_id=f"test_{int(time.time())}")
        client.username_pw_set("bblp", access_code)
        client.tls_set(cert_reqs=ssl.CERT_NONE)
        client.tls_insecure_set(True)
        client.on_connect = on_connect
        
        print(f"  Connecting to {ip}:8883...")
        print(f"  Username: bblp")
        print(f"  Access Code: {access_code}")
        
        client.connect(ip, 8883, 60)
        client.loop_start()
        
        # Wait up to 10 seconds
        for i in range(10):
            if connected[0] or error_info[0]:
                break
            time.sleep(1)
        
        client.loop_stop()
        client.disconnect()
        
        if connected[0]:
            return True
        else:
            if error_info[0] and error_info[0][0] in [4, 5]:
                print("\n** ACCESS CODE IS INCORRECT **")
                print("  Go to printer: Settings → WLAN → Access Code")
                print("  Must be EXACTLY 8 digits")
            return False
            
    except Exception as e:
        print(f"✗ Connection error: {e}")
        return False

def test_credentials(ip, access_code, serial):
    """Validate input format"""
    print(f"\n[3/3] Validating credentials...")
    print("-" * 60)
    
    issues = []
    
    # Check IP format
    try:
        parts = ip.split('.')
        if len(parts) != 4:
            issues.append("IP address must have 4 parts (e.g., 192.168.1.100)")
        else:
            for part in parts:
                if not 0 <= int(part) <= 255:
                    issues.append(f"IP part '{part}' must be 0-255")
    except:
        issues.append("IP address format is invalid")
    
    # Check access code
    if len(access_code) != 8:
        issues.append(f"Access code must be 8 digits (you entered {len(access_code)})")
    if not access_code.isdigit():
        issues.append("Access code must be only digits (0-9)")
    
    # Check serial (basic check)
    if not serial or len(serial) < 5:
        issues.append("Serial number seems too short")
    
    if issues:
        print("✗ Credential issues found:")
        for issue in issues:
            print(f"  • {issue}")
        return False
    else:
        print("✓ Credential format looks good")
        return True

def main():
    print_header()
    
    print("This tool will test your connection to the Bambulab printer.")
    print("You'll need 3 things from your printer's touchscreen:")
    print("  1. IP Address (Settings → Network)")
    print("  2. Access Code (Settings → WLAN) - 8 digits")
    print("  3. Serial Number (Settings → Device)")
    print()
    
    # Get user input
    ip = get_input("Enter Printer IP Address", "192.168.100.13")
    access_code = get_input("Enter Access Code (8 digits)")
    serial = get_input("Enter Serial Number")
    
    print()
    print("=" * 60)
    print("TESTING CONNECTION")
    print("=" * 60)
    
    # Run tests
    creds_ok = test_credentials(ip, access_code, serial)
    if not creds_ok:
        print("\n" + "=" * 60)
        print("FIX THE ISSUES ABOVE AND TRY AGAIN")
        print("=" * 60)
        input("\nPress Enter to exit...")
        return 1
    
    port_ok = test_port(ip, 8883)
    mqtt_ok = test_mqtt_connection(ip, access_code, serial) if port_ok else False
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST RESULTS")
    print("=" * 60)
    
    if mqtt_ok:
        print("✓✓✓ CONNECTION SUCCESSFUL! ✓✓✓")
        print("\nYour credentials are correct and the connection works!")
        print("\nThe R Shiny app should work now.")
        print("If it still doesn't work, the issue is with the R/Python integration.")
        print("\nTry this in the R console:")
        print(f'  system("python bambulab_mqtt.py connect {ip} {access_code} {serial}")')
        
    elif port_ok and not mqtt_ok:
        print("✗ MQTT CONNECTION FAILED")
        print("\nPort 8883 is open, but MQTT authentication failed.")
        print("\nMOST LIKELY: Wrong access code")
        print("\nDouble-check on printer:")
        print("  Settings → WLAN → Access Code")
        print("\nMake sure it's EXACTLY 8 digits with no spaces.")
        
    elif not port_ok:
        print("✗ PORT 8883 BLOCKED OR CLOSED")
        print("\nCannot reach the printer's MQTT port.")
        print("\nTroubleshooting:")
        print("  1. Check Windows Firewall")
        print("  2. Temporarily disable antivirus")
        print("  3. Restart the printer")
        print("  4. Make sure printer is fully booted")
        
    else:
        print("✗ CONNECTION FAILED")
        print("\nCheck the errors above for details.")
    
    print("=" * 60)
    
    input("\nPress Enter to exit...")
    return 0 if mqtt_ok else 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\nTest cancelled by user.")
        sys.exit(1)
    except Exception as e:
        print(f"\n\nUnexpected error: {e}")
        input("Press Enter to exit...")
        sys.exit(1)
