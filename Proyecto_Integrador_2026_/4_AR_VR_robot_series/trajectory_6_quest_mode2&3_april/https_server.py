#!/usr/bin/env python3
"""
HTTPS Server for Meta Quest 3 Trajectory AR Application
Serves trajectory_6modes_tracker.html with proper SSL certificates

Usage:
    python3 https_server.py
    python3 https_server.py --ip 192.168.1.50
    python3 https_server.py --port 9000
"""

import http.server
import ssl
import os
import sys
import argparse
import socket

DEFAULT_PORT = 8443
CERT_FILE = 'cert.pem'
KEY_FILE = 'key.pem'
MAIN_HTML = 'trajectory_6modes_tracker.html'  # ← CORRECT FILE


def get_local_ip():
    """Auto-detect local IP address"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return '127.0.0.1'


class TrajectoryARHandler(http.server.SimpleHTTPRequestHandler):
    """Custom handler with correct MIME types and CORS headers"""

    MIME_MAP = {
        '.html': 'text/html',
        '.htm': 'text/html',
        '.js': 'application/javascript',
        '.mjs': 'application/javascript',
        '.css': 'text/css',
        '.json': 'application/json',
        '.geojson': 'application/json',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.gif': 'image/gif',
        '.svg': 'image/svg+xml',
        '.ico': 'image/x-icon',
        '.wasm': 'application/wasm',
        '.stl': 'model/stl',
        '.pem': 'text/plain',
        '.md': 'text/plain',
        '.txt': 'text/plain',
        '.py': 'text/plain',
    }

    def guess_type(self, path):
        """Override MIME type detection for Python 3.9-3.13 compatibility"""
        ext = os.path.splitext(str(path))[1].lower()
        return self.MIME_MAP.get(ext, 'application/octet-stream')

    def end_headers(self):
        """Add required headers for WebXR and CORS"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

    def log_message(self, fmt, *args):
        """Only log important requests"""
        msg = fmt % args
        if any(x in msg for x in ['.html', '.geojson', 'GET /']):
            print(f'  [{self.address_string()}] {msg}')


def parse_args():
    """Parse command line arguments"""
    p = argparse.ArgumentParser(description='HTTPS server for Trajectory AR')
    p.add_argument('--ip', default=None, help='Server IP address (auto-detect if not specified)')
    p.add_argument('--port', '-p', type=int, default=DEFAULT_PORT, help=f'Server port (default: {DEFAULT_PORT})')
    return p.parse_args()


def main():
    args = parse_args()

    # Determine IP address
    if args.ip:
        host_ip = args.ip
    else:
        host_ip = get_local_ip()
        print(f"\n🔍 Auto-detected IP: {host_ip}")

    port = args.port

    # Change to script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    # Validate required files
    missing = []
    if not os.path.exists(CERT_FILE):
        missing.append(f"  - {CERT_FILE} (SSL certificate)")
    if not os.path.exists(KEY_FILE):
        missing.append(f"  - {KEY_FILE} (SSL private key)")
    if not os.path.exists(MAIN_HTML):
        missing.append(f"  - {MAIN_HTML} (AR application)")

    if missing:
        print("\n" + "="*70)
        print("Meta Quest 3 AR Application - HTTPS Server")
        print("="*70)
        print("ERROR: Missing required files:")
        for m in missing:
            print(m)
        if CERT_FILE in str(missing) or KEY_FILE in str(missing):
            print("\nTo generate SSL certificates, run:")
            print("  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes")
        print("="*70 + "\n")
        sys.exit(1)

    # Create HTTPS server
    httpd = http.server.HTTPServer(('0.0.0.0', port), TrajectoryARHandler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(CERT_FILE, KEY_FILE)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)

    # Display server info
    url = f'https://{host_ip}:{port}'
    print()
    print("="*70)
    print("Meta Quest 3 Trajectory AR - HTTPS Server")
    print("="*70)
    print(f"  IP Address: {host_ip}")
    print(f"  Port:       {port}")
    print(f"  File:       {MAIN_HTML}")
    print()
    print(f"  Quest 3 Browser URL:")
    print(f"    {url}/{MAIN_HTML}")
    print()
    print("  Steps:")
    print("    1. Quest 3 on same WiFi network")
    print("    2. Open browser and enter URL above")
    print("    3. Click 'Advanced' → 'Proceed' (accept certificate warning)")
    print("    4. Grant camera/controller permissions")
    print("    5. Click 'Start AR'")
    print()
    print("  Press Ctrl+C to stop")
    print("="*70)
    print()

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\n\n✓ Server stopped.\n')


if __name__ == '__main__':
    main()
