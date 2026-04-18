#!/usr/bin/env python3
"""
HTTPS Server for Meta Quest 3 AR Application
Serves the trajectory_6modes.html file and related assets
Port: 8443 (HTTPS)

Usage:
    python https_server.py

Requirements:
    - cert.pem and key.pem in same directory (SSL certificates)
    - trajectory_6modes.html in same directory
    - Python 3.6+

The Quest 3 will connect to: https://<YOUR_PC_IP>:8443/trajectory_6modes.html
"""

import http.server
import ssl
import os
import sys

# Configuration
PORT = 8443
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'

class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler with CORS headers for Quest 3 compatibility"""
    
    def end_headers(self):
        # Add CORS headers
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        # Cache control
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle preflight OPTIONS requests"""
        self.send_response(200)
        self.end_headers()
    
    def log_message(self, format, *args):
        """Custom log format with timestamp"""
        sys.stdout.write("[%s] %s - %s\n" % (
            self.log_date_time_string(),
            self.address_string(),
            format % args
        ))

def check_files():
    """Verify required files exist"""
    required_files = {
        CERT_FILE: 'SSL certificate',
        KEY_FILE: 'SSL private key',
        'trajectory_6modes.html': 'AR application'
    }
    
    missing = []
    for filename, description in required_files.items():
        if not os.path.exists(filename):
            missing.append(f"  - {filename} ({description})")
    
    if missing:
        print("ERROR: Missing required files:")
        print("\n".join(missing))
        print("\nTo generate SSL certificates, run:")
        print("  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes")
        return False
    
    return True

def get_local_ip():
    """Get local IP address for display"""
    import socket
    try:
        # Create a socket to determine local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        local_ip = s.getsockname()[0]
        s.close()
        return local_ip
    except:
        return "UNKNOWN"

def main():
    """Start HTTPS server"""
    
    print("=" * 70)
    print("Meta Quest 3 AR Application - HTTPS Server")
    print("=" * 70)
    
    # Check required files
    if not check_files():
        sys.exit(1)
    
    # Get local IP
    local_ip = get_local_ip()
    
    # Create server
    server_address = ('', PORT)
    httpd = http.server.HTTPServer(server_address, CORSRequestHandler)
    
    # Wrap with SSL
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=CERT_FILE, keyfile=KEY_FILE)
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)
    
    print(f"\n✓ Server started successfully!")
    print(f"\nServer Details:")
    print(f"  - Port: {PORT}")
    print(f"  - Protocol: HTTPS")
    print(f"  - Local IP: {local_ip}")
    print(f"\nOn your Meta Quest 3:")
    print(f"  1. Connect to the same WiFi network")
    print(f"  2. Open Quest Browser")
    print(f"  3. Navigate to: https://{local_ip}:{PORT}/trajectory_6modes.html")
    print(f"  4. Accept the self-signed certificate warning")
    print(f"\nFiles being served from: {os.getcwd()}")
    print(f"\nPress Ctrl+C to stop the server\n")
    print("=" * 70)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\nShutting down server...")
        httpd.shutdown()
        print("Server stopped.")

if __name__ == '__main__':
    main()
