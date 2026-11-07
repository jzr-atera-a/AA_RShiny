#!/usr/bin/env python3
"""
HTTPS Server for AR Map Viewer on Meta Quest 3
Windows Machine IP: 192.168.100.14
"""

import http.server
import ssl
import os
import sys

HOST = '0.0.0.0'
PORT = 8000
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'
SERVER_IP = '192.168.100.14'

def main():
    # Check certificates
    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print("=" * 70)
        print("  ERROR: SSL certificates not found!")
        print("=" * 70)
        print("\n  Generate certificates with:")
        print(f"  openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj \"/CN={SERVER_IP}\"")
        print("\n  Or run: generate_certs.bat")
        print("=" * 70)
        sys.exit(1)
    
    # Create HTTPS server
    server_address = (HOST, PORT)
    httpd = http.server.HTTPServer(server_address, http.server.SimpleHTTPRequestHandler)
    
    # Wrap with SSL
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(CERT_FILE, KEY_FILE)
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
    
    print("=" * 70)
    print("  AR MAP VIEWER - HTTPS SERVER RUNNING")
    print("=" * 70)
    print(f"\n  Server: https://{SERVER_IP}:{PORT}")
    print("\n  On Quest 3 Browser:")
    print(f"    https://{SERVER_IP}:{PORT}/ar_map_viewer.html")
    print("\n  Instructions:")
    print("    1. Accept SSL certificate warning")
    print("    2. Grant AR permissions")
    print("    3. Click 'Start AR'")
    print("    4. Point at floor to place map")
    print("\n  Press Ctrl+C to stop")
    print("=" * 70)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\nServer stopped")

if __name__ == '__main__':
    main()
