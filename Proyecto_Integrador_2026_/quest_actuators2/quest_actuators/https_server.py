#!/usr/bin/env python3
"""
HTTPS server to serve actuators.html to Quest 3
"""

import http.server
import ssl
import os
import sys

HOST = '0.0.0.0'
PORT = 8000
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'

def main():
    # Check certificates
    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print("=" * 60)
        print("  ERROR: SSL certificates not found!")
        print("=" * 60)
        print("\n  Generate with:")
        print("  openssl req -x509 -newkey rsa:2048 -keyout key.pem \\")
        print("          -out cert.pem -days 365 -nodes \\")
        print("          -subj '/CN=192.168.100.10'")
        print("=" * 60)
        sys.exit(1)
    
    # Create HTTPS server
    server_address = (HOST, PORT)
    httpd = http.server.HTTPServer(server_address, http.server.SimpleHTTPRequestHandler)
    
    # Wrap with SSL
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(CERT_FILE, KEY_FILE)
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
    
    print("=" * 70)
    print("  HTTPS SERVER RUNNING")
    print("=" * 70)
    print(f"\n  Server: https://192.168.100.10:{PORT}")
    print("\n  On Quest 3, navigate to:")
    print("    https://192.168.100.10:8000/actuators.html")
    print("\n  ⚠️  Accept certificate warning when prompted")
    print("\n  Press Ctrl+C to stop")
    print("=" * 70)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\nHTTPS server stopped")

if __name__ == '__main__':
    main()
