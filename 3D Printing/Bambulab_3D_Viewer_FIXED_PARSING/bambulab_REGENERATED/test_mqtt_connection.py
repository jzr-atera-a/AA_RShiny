#!/usr/bin/env python3
"""
Direct MQTT connection test for Bambulab printer
Tests the actual MQTT connection to diagnose issues
"""

import sys
import socket
import ssl

def test_mqtt_port(ip):
    """Test if MQTT port 8883 is accessible"""
    print(f"Testing MQTT port 8883 on {ip}...")
    print("-" * 50)
    
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(10)
        
        print("Attempting to connect to port 8883...")
        result = sock.connect_ex((ip, 8883))
        
        if result == 0:
            print("✓ Port 8883 is OPEN and accepting connections")
            sock.close()
            return True
        else:
            print(f"✗ Port 8883 connection failed (error code: {result})")
            print("\nPossible causes:")
            print("  • Printer's MQTT server not running")
            print("  • Firewall blocking port 8883")
            print("  • Printer firmware issue")
            sock.close()
            return False
    except socket.timeout:
        print("✗ Connection TIMEOUT on port 8883")
        print("\nPossible causes:")
        print("  • Firewall blocking the port")
        print("  • Printer not responding on MQTT port")
        return False
    except Exception as e:
        print(f"✗ Error: {e}")
        return False

def test_mqtt_connection(ip, access_code, serial):
    """Test actual MQTT connection with credentials"""
    print(f"\nTesting MQTT connection with credentials...")
    print("-" * 50)
    
    try:
        import paho.mqtt.client as mqtt
        
        connected = [False]
        error_msg = [None]
        
        def on_connect(client, userdata, flags, rc):
            if rc == 0:
                print("✓ MQTT connection SUCCESSFUL!")
                connected[0] = True
            else:
                error_codes = {
                    1: "Connection refused - incorrect protocol version",
                    2: "Connection refused - invalid client identifier",
                    3: "Connection refused - server unavailable",
                    4: "Connection refused - bad username or password (CHECK ACCESS CODE!)",
                    5: "Connection refused - not authorized"
                }
                msg = error_codes.get(rc, f"Unknown error code: {rc}")
                print(f"✗ MQTT connection FAILED: {msg}")
                error_msg[0] = msg
        
        def on_disconnect(client, userdata, rc):
            if rc != 0:
                print(f"Unexpected disconnection (code: {rc})")
        
        print(f"Connecting to: {ip}:8883")
        print(f"Username: bblp")
        print(f"Access Code: {access_code}")
        print(f"Serial: {serial}")
        
        client = mqtt.Client(client_id=f"test_client_{serial}")
        client.username_pw_set("bblp", access_code)
        
        # Enable TLS
        client.tls_set(cert_reqs=ssl.CERT_NONE)
        client.tls_insecure_set(True)
        
        client.on_connect = on_connect
        client.on_disconnect = on_disconnect
        
        print("\nAttempting MQTT connection...")
        client.connect(ip, 8883, 60)
        client.loop_start()
        
        # Wait for connection
        import time
        for i in range(10):
            if connected[0]:
                break
            time.sleep(1)
            print(f"  Waiting... {i+1}/10")
        
        client.loop_stop()
        client.disconnect()
        
        if connected[0]:
            print("\n✓✓✓ CONNECTION SUCCESSFUL! ✓✓✓")
            print("\nYour credentials are correct!")
            print("The issue is with the R Shiny app, not the connection.")
            return True
        else:
            print("\n✗✗✗ CONNECTION FAILED ✗✗✗")
            if error_msg[0]:
                print(f"\nError: {error_msg[0]}")
                if "bad username or password" in error_msg[0].lower():
                    print("\n** ACCESS CODE IS WRONG **")
                    print("Double-check on printer: Settings → WLAN → Access Code")
            return False
            
    except ImportError:
        print("✗ paho-mqtt not installed!")
        print("Run: python -m pip install paho-mqtt")
        return False
    except Exception as e:
        print(f"✗ Connection error: {e}")
        return False

def main():
    print("=" * 50)
    print("BAMBULAB MQTT CONNECTION TEST")
    print("=" * 50)
    
    if len(sys.argv) < 4:
        print("\nUsage: python test_mqtt_connection.py <IP> <ACCESS_CODE> <SERIAL>")
        print("Example: python test_mqtt_connection.py 192.168.1.100 12345678 01S00A123456789")
        sys.exit(1)
    
    ip = sys.argv[1]
    access_code = sys.argv[2]
    serial = sys.argv[3]
    
    print(f"\nPrinter IP: {ip}")
    print(f"Access Code: {access_code}")
    print(f"Serial: {serial}")
    print()
    
    # Test 1: Port accessibility
    port_ok = test_mqtt_port(ip)
    
    if not port_ok:
        print("\n" + "=" * 50)
        print("PORT TEST FAILED")
        print("=" * 50)
        print("\nTroubleshooting:")
        print("1. Check Windows Firewall settings")
        print("2. Temporarily disable antivirus")
        print("3. Restart printer")
        print("4. Check printer firmware is up to date")
        return 1
    
    # Test 2: MQTT connection
    mqtt_ok = test_mqtt_connection(ip, access_code, serial)
    
    print("\n" + "=" * 50)
    if mqtt_ok:
        print("✓ ALL TESTS PASSED!")
        print("=" * 50)
        print("\nThe connection works! The issue is in the R app.")
        print("\nTry running the R Shiny app again.")
        print("If it still fails, check the Logs tab for details.")
        return 0
    else:
        print("✗ MQTT CONNECTION FAILED")
        print("=" * 50)
        print("\nMost likely issue: WRONG ACCESS CODE")
        print("\nVerify on printer:")
        print("  Settings → WLAN → Access Code")
        print("\nMust be EXACTLY 8 digits, no spaces.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
