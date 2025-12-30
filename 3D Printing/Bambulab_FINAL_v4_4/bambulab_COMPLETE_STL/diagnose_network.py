#!/usr/bin/env python3
"""
Network diagnostic script for Bambulab printer connection
Tests connectivity before attempting MQTT connection
"""

import sys
import socket

def test_dns_resolution(host):
    """Test if hostname/IP can be resolved"""
    print(f"\n[TEST 1] DNS Resolution for: {host}")
    print("-" * 50)
    try:
        ip = socket.gethostbyname(host)
        print(f"✓ Successfully resolved to: {ip}")
        return True, ip
    except socket.gaierror as e:
        print(f"✗ DNS resolution failed!")
        print(f"  Error: {e}")
        print(f"  This means: Cannot find the IP address '{host}'")
        return False, None

def test_ping(host, port=8883):
    """Test if we can reach the host and port"""
    print(f"\n[TEST 2] Network connectivity to {host}:{port}")
    print("-" * 50)
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        result = sock.connect_ex((host, port))
        sock.close()
        
        if result == 0:
            print(f"✓ Port {port} is OPEN and reachable")
            return True
        else:
            print(f"✗ Port {port} is CLOSED or unreachable")
            print(f"  Error code: {result}")
            return False
    except socket.gaierror as e:
        print(f"✗ Cannot resolve hostname: {e}")
        return False
    except socket.timeout:
        print(f"✗ Connection timeout - printer may be off or unreachable")
        return False
    except Exception as e:
        print(f"✗ Connection failed: {e}")
        return False

def test_network_interface():
    """Check local network configuration"""
    print(f"\n[TEST 3] Local network configuration")
    print("-" * 50)
    try:
        hostname = socket.gethostname()
        local_ip = socket.gethostbyname(hostname)
        print(f"✓ Computer hostname: {hostname}")
        print(f"✓ Computer IP: {local_ip}")
        
        # Check if on same subnet (simple check)
        return True, local_ip
    except Exception as e:
        print(f"✗ Cannot get local IP: {e}")
        return False, None

def validate_ip_format(ip_str):
    """Validate IP address format"""
    print(f"\n[TEST 4] IP address format validation")
    print("-" * 50)
    try:
        parts = ip_str.split('.')
        if len(parts) != 4:
            print(f"✗ Invalid IP format: {ip_str}")
            print(f"  Should have 4 parts separated by dots")
            return False
        
        for part in parts:
            num = int(part)
            if num < 0 or num > 255:
                print(f"✗ Invalid IP format: {ip_str}")
                print(f"  Each part must be 0-255, got: {part}")
                return False
        
        print(f"✓ IP format is valid: {ip_str}")
        return True
    except ValueError:
        print(f"✗ Invalid IP format: {ip_str}")
        print(f"  Contains non-numeric characters")
        return False

def check_firewall_ports():
    """Check if required ports might be blocked"""
    print(f"\n[TEST 5] Firewall check")
    print("-" * 50)
    print("Required ports for Bambulab printer:")
    print("  • Port 8883 (MQTT) - Control and status")
    print("  • Port 990 (FTP) - File uploads")
    print("\nPlease ensure these ports are not blocked by:")
    print("  • Windows Firewall")
    print("  • Antivirus software")
    print("  • Router firewall")
    print("  • VPN software")
    return True

def main():
    print("=" * 50)
    print("BAMBULAB PRINTER NETWORK DIAGNOSTICS")
    print("=" * 50)
    
    if len(sys.argv) < 2:
        print("\nUsage: python diagnose_network.py <PRINTER_IP>")
        print("Example: python diagnose_network.py 192.168.1.100")
        sys.exit(1)
    
    printer_ip = sys.argv[1]
    
    print(f"\nTesting connection to printer: {printer_ip}")
    
    results = []
    
    # Test 1: Validate IP format
    results.append(validate_ip_format(printer_ip))
    
    # Test 2: DNS resolution
    can_resolve, resolved_ip = test_dns_resolution(printer_ip)
    results.append(can_resolve)
    
    # Test 3: Local network
    has_network, local_ip = test_network_interface()
    results.append(has_network)
    
    # Test 4: Check connectivity to MQTT port
    if can_resolve:
        results.append(test_ping(printer_ip, 8883))
        
        # Also test FTP port
        print(f"\n[BONUS] Testing FTP port 990")
        print("-" * 50)
        test_ping(printer_ip, 990)
    
    # Test 5: Firewall info
    check_firewall_ports()
    
    # Summary
    print("\n" + "=" * 50)
    print("DIAGNOSTIC SUMMARY")
    print("=" * 50)
    
    if all(results):
        print("✓ All network tests passed!")
        print("\nYour network configuration looks good.")
        print("If connection still fails, check:")
        print("  1. Access code is correct (8 digits)")
        print("  2. Serial number is correct")
        print("  3. Printer is not in sleep mode")
    else:
        print("✗ Some network tests failed\n")
        print("TROUBLESHOOTING STEPS:\n")
        
        if not validate_ip_format(printer_ip):
            print("1. CHECK IP ADDRESS FORMAT")
            print("   • Go to printer: Settings → Network")
            print("   • Copy IP address exactly as shown")
            print("   • Should look like: 192.168.1.100")
            print()
        
        if not can_resolve:
            print("2. VERIFY PRINTER IP ADDRESS")
            print("   • Printer must be ON")
            print("   • Check Settings → Network → IP Address")
            print("   • IP address may have changed")
            print()
        
        if can_resolve and not results[-1]:
            print("3. CHECK NETWORK CONNECTION")
            print("   • Printer must be connected to WiFi")
            print("   • Computer and printer on SAME network")
            print("   • Try pinging: ping", printer_ip)
            print()
        
        if local_ip and resolved_ip:
            local_subnet = '.'.join(local_ip.split('.')[:3])
            printer_subnet = '.'.join(resolved_ip.split('.')[:3])
            if local_subnet != printer_subnet:
                print("4. DIFFERENT SUBNETS DETECTED!")
                print(f"   • Your computer: {local_ip} (subnet: {local_subnet}.x)")
                print(f"   • Printer: {resolved_ip} (subnet: {printer_subnet}.x)")
                print("   • Both must be on same network!")
                print()
    
    print("=" * 50)
    
    return 0 if all(results) else 1

if __name__ == "__main__":
    sys.exit(main())
