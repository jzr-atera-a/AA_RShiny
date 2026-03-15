#!/usr/bin/env python3
"""
HTTPS server for Robot AR WebXR viewer — Python 3.9-3.13 compatible
NOW WITH DEBUG LOGGING TO FILE!

Usage:
  python https_server.py                   # default IP: 10.5.21.31
  python https_server.py 192.168.1.50      # custom IP (positional)
  python https_server.py --ip 192.168.1.50
  python https_server.py --port 9000
"""

import http.server
import ssl
import os
import sys
import argparse
import socket
import json
from datetime import datetime
from urllib.parse import parse_qs

DEFAULT_IP   = '10.5.21.31'
DEFAULT_PORT = 8443
CERT_FILE    = 'cert.pem'
KEY_FILE     = 'key.pem'
MAIN_HTML    = 'trajectory_6modes.html'
DEBUG_LOG    = 'ar_debug.log'


def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return '127.0.0.1'


class RobotARHandler(http.server.SimpleHTTPRequestHandler):
    """
    MIME-safe handler with debug logging endpoint and dynamic IP injection
    """

    MIME_MAP = {
        '.html':    'text/html',
        '.htm':     'text/html',
        '.js':      'application/javascript',
        '.mjs':     'application/javascript',
        '.css':     'text/css',
        '.json':    'application/json',
        '.geojson': 'application/json',
        '.png':     'image/png',
        '.jpg':     'image/jpeg',
        '.jpeg':    'image/jpeg',
        '.gif':     'image/gif',
        '.svg':     'image/svg+xml',
        '.ico':     'image/x-icon',
        '.wasm':    'application/wasm',
        '.stl':     'model/stl',
        '.pem':     'text/plain',
        '.md':      'text/plain',
        '.txt':     'text/plain',
        '.py':      'text/plain',
    }

    server_ip = None  # Will be set by main()

    def guess_type(self, path):
        ext = os.path.splitext(str(path))[1].lower()
        return self.MIME_MAP.get(ext, 'application/octet-stream')

    def do_GET(self):
        """Override GET to inject IP into HTML files"""
        # Check if requesting the main HTML file
        if self.path == f'/{MAIN_HTML}' or self.path == '/':
            actual_path = MAIN_HTML if self.path == '/' else MAIN_HTML
            
            if os.path.exists(actual_path):
                try:
                    with open(actual_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Inject the server IP into the websocket connection
                    # Replace the hardcoded IP with the actual server IP
                    content = content.replace(
                        "const WS_IP = '192.168.100.10';",
                        f"const WS_IP = '{self.server_ip}';"
                    )
                    content = content.replace(
                        "const WS_IP = '10.183.14.243';",
                        f"const WS_IP = '{self.server_ip}';"
                    )
                    
                    # Send response
                    self.send_response(200)
                    self.send_header('Content-type', 'text/html')
                    self.send_header('Content-Length', len(content.encode()))
                    self.end_headers()
                    self.wfile.write(content.encode())
                    return
                except Exception as e:
                    print(f"Error injecting IP: {e}")
                    # Fall through to default handler
        
        # Default handling for other files
        super().do_GET()

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

    def do_POST(self):
        """Handle POST requests for debug logging"""
        if self.path == '/debug_log':
            try:
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                data = json.loads(post_data.decode('utf-8'))
                
                # Write to debug log file
                timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
                log_entry = f"[{timestamp}] {data.get('level', 'INFO')}: {data.get('message', '')}\n"
                
                with open(DEBUG_LOG, 'a') as f:
                    f.write(log_entry)
                
                # Also print to console
                print(log_entry.strip())
                
                # Send response
                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'status': 'ok'}).encode())
                
            except Exception as e:
                print(f"Error logging: {e}")
                self.send_response(500)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, fmt, *args):
        msg = fmt % args
        if any(x in msg for x in ['.html', '.geojson', 'GET /', 'POST /']):
            print(f'  [{self.address_string()}] {msg}')


def parse_args():
    p = argparse.ArgumentParser(description='HTTPS server for Robot AR')
    p.add_argument('ip', nargs='?', default=None)
    p.add_argument('--ip', dest='ip_flag', default=None)
    p.add_argument('--port', '-p', type=int, default=DEFAULT_PORT)
    p.add_argument('--auto-ip', action='store_true')
    return p.parse_args()


def main():
    args = parse_args()

    if args.auto_ip:
        host_ip = get_local_ip()
    elif args.ip:
        host_ip = args.ip
    elif args.ip_flag:
        host_ip = args.ip_flag
    else:
        host_ip = DEFAULT_IP

    port = args.port

    script_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(script_dir)

    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print('=' * 60)
        print('  ERROR: cert.pem / key.pem not found!')
        print('  Regenerate with:')
        print(f'    openssl req -x509 -newkey rsa:2048 -keyout key.pem \\')
        print(f'            -out cert.pem -days 365 -nodes \\')
        print(f'            -subj "/CN={host_ip}"')
        print('=' * 60)
        sys.exit(1)

    # Clear/create debug log file
    with open(DEBUG_LOG, 'w') as f:
        f.write(f"=== AR Debug Log Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===\n")

    # Set the server IP in the handler class so it can inject it into HTML
    RobotARHandler.server_ip = host_ip

    httpd = http.server.HTTPServer(('0.0.0.0', port), RobotARHandler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(CERT_FILE, KEY_FILE)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)

    url = f'https://{host_ip}:{port}'
    print()
    print('=' * 60)
    print('  ROBOT AR  —  HTTPS SERVER WITH DEBUG LOGGING')
    print('=' * 60)
    print(f'  IP   : {host_ip}')
    print(f'  Port : {port}')
    print()
    print(f'  MetaQuest URL:')
    print(f'    {url}/{MAIN_HTML}')
    print()
    print(f'  WebSocket will use: {host_ip}:8444')
    print(f'  Debug log file: {DEBUG_LOG}')
    print(f'  Watch logs: tail -f {DEBUG_LOG}')
    print()
    print('  Steps on MetaQuest Browser:')
    print('    1. Same WiFi as this PC')
    print('    2. Open URL above')
    print('    3. Advanced -> Proceed  (accept cert warning)')
    print('    4. AR will start automatically')
    print()
    print('  IP is auto-injected into HTML - no hardcoding!')
    print('  Ctrl+C to stop')
    print('=' * 60)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\n  Stopped.')


if __name__ == '__main__':
    main()
