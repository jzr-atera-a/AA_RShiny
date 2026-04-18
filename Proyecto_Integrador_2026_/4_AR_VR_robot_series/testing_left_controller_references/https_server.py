#!/usr/bin/env python3
"""
HTTPS Server for Meta Quest 3 AR Application
Serves HTML files from the current directory over HTTPS.
Port: 8443

Usage:
    python https_server.py                    # auto-detects local IP
    python https_server.py 192.168.100.10     # use specific IP for URL display

Requirements:
    - cert.pem and key.pem in same directory (SSL certificates)
    - Python 3.6+

Quest 3 URL (controller diagnostic):
    https://<IP>:8443/controller_diagnostic.html

Quest 3 URL (main robot app):
    https://<IP>:8443/trajectory_6modes_tracker.html
"""

import http.server
import ssl
import os
import sys

# Configuration
PORT      = 8443
CERT_FILE = 'cert.pem'
KEY_FILE  = 'key.pem'


class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    """HTTP request handler with CORS headers for Quest 3 compatibility."""

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def log_message(self, format, *args):
        sys.stdout.write("[%s] %s - %s\n" % (
            self.log_date_time_string(),
            self.address_string(),
            format % args
        ))


def get_local_ip():
    """Auto-detect local LAN IP address."""
    import socket
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "UNKNOWN"


def check_files():
    """Verify SSL certificates exist."""
    missing = []
    for f, desc in [(CERT_FILE, 'SSL certificate'), (KEY_FILE, 'SSL private key')]:
        if not os.path.exists(f):
            missing.append(f"  - {f} ({desc})")
    if missing:
        print("ERROR: Missing required files:")
        print("\n".join(missing))
        print("\nGenerate with:")
        print("  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes")
        return False
    return True


def main():
    # ── IP argument ────────────────────────────────────────────────────────────
    if len(sys.argv) >= 2:
        local_ip = sys.argv[1]
        print(f"Using IP from argument: {local_ip}")
    else:
        local_ip = get_local_ip()

    print("=" * 70)
    print("Meta Quest 3 - HTTPS File Server")
    print("=" * 70)

    if not check_files():
        sys.exit(1)

    # ── Start server ───────────────────────────────────────────────────────────
    httpd = http.server.HTTPServer(('', PORT), CORSRequestHandler)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=CERT_FILE, keyfile=KEY_FILE)
    httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

    print(f"\n✓ HTTPS server started")
    print(f"\n  Port     : {PORT}")
    print(f"  IP       : {local_ip}")
    print(f"  Serving  : {os.getcwd()}")

    print(f"\n  ── Quest 3 URLs ──────────────────────────────────────")
    print(f"  Main app   : https://{local_ip}:{PORT}/trajectory_6modes_tracker.html")
    print(f"  Diagnostic : https://{local_ip}:{PORT}/controller_diagnostic.html")
    print(f"  ─────────────────────────────────────────────────────")
    print(f"\n  Accept the self-signed certificate warning on first visit.")
    print(f"\nPress Ctrl+C to stop\n")
    print("=" * 70)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n\nShutting down...")
        httpd.shutdown()
        print("Server stopped.")


if __name__ == '__main__':
    main()
