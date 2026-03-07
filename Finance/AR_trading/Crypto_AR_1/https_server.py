#!/usr/bin/env python3
"""
HTTPS server for Finance AR Dashboard — Python 3.9-3.13 compatible

Usage:
  python https_server.py                   # default IP: 10.5.21.31
  python https_server.py 192.168.1.50      # custom IP (positional)
  python https_server.py --ip 192.168.1.50
  python https_server.py --port 9000
  python https_server.py --auto-ip         # auto-detect local IP
"""

import http.server
import ssl
import os
import sys
import argparse
import socket
import json
from datetime import datetime

DEFAULT_IP   = '10.5.21.31'
DEFAULT_PORT = 8443
CERT_FILE    = 'cert.pem'
KEY_FILE     = 'key.pem'
MAIN_HTML    = 'finance_dashboard_ar.html'   # ← updated from trajectory_6modes.html
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


class FinanceARHandler(http.server.SimpleHTTPRequestHandler):
    """
    MIME-safe handler with debug-logging endpoint.
    No IP injection needed (no WebSocket in this version).
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

    server_ip = None

    def guess_type(self, path):
        ext = os.path.splitext(str(path))[1].lower()
        return self.MIME_MAP.get(ext, 'application/octet-stream')

    def do_GET(self):
        """Serve files; redirect root to main HTML."""
        if self.path in ('/', f'/{MAIN_HTML}'):
            actual = MAIN_HTML
            if os.path.exists(actual):
                try:
                    with open(actual, 'r', encoding='utf-8') as f:
                        content = f.read()
                    encoded = content.encode('utf-8')
                    self.send_response(200)
                    self.send_header('Content-type', 'text/html; charset=utf-8')
                    self.send_header('Content-Length', len(encoded))
                    self.end_headers()
                    self.wfile.write(encoded)
                    return
                except Exception as e:
                    print(f'Error serving main HTML: {e}')
        super().do_GET()

    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

    def do_POST(self):
        """Handle debug log posts from the AR client."""
        if self.path == '/debug_log':
            try:
                length   = int(self.headers.get('Content-Length', 0))
                raw      = self.rfile.read(length)
                data     = json.loads(raw.decode('utf-8'))
                ts       = datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')[:-3]
                entry    = f"[{ts}] {data.get('level','INFO')}: {data.get('message','')}\n"

                with open(DEBUG_LOG, 'a') as f:
                    f.write(entry)

                lvl = data.get('level', 'INFO')
                if lvl in ('ERROR', 'WARN') or any(k in entry for k in ['SCENE', 'SESSION', 'MODE', 'Floor']):
                    print(f'  [AR] {entry.strip()}')

                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'status': 'ok'}).encode())
            except Exception as e:
                print(f'Debug log error: {e}')
                self.send_response(500)
                self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, fmt, *args):
        msg = fmt % args
        if any(x in msg for x in ['.html', 'GET /', 'POST /']):
            print(f'  [{self.address_string()}] {msg}')


def parse_args():
    p = argparse.ArgumentParser(description='HTTPS server for Finance AR Dashboard')
    p.add_argument('ip',      nargs='?', default=None,             help='Server IP (positional)')
    p.add_argument('--ip',    dest='ip_flag', default=None,        help='Server IP (flag)')
    p.add_argument('--port',  '-p', type=int, default=DEFAULT_PORT, help='Port (default 8443)')
    p.add_argument('--auto-ip', action='store_true',               help='Auto-detect local IP')
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
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print('=' * 62)
        print('  ERROR: cert.pem / key.pem not found!')
        print('  Generate self-signed cert with:')
        print(f'    openssl req -x509 -newkey rsa:2048 -keyout key.pem \\')
        print(f'            -out cert.pem -days 365 -nodes \\')
        print(f'            -subj "/CN={host_ip}"')
        print('=' * 62)
        sys.exit(1)

    if not os.path.exists(MAIN_HTML):
        print(f'  WARNING: {MAIN_HTML} not found in current directory.')
        print(f'  Make sure finance_dashboard_ar.html is in the same folder.')

    # Initialise debug log
    with open(DEBUG_LOG, 'w') as f:
        f.write(f"=== Finance AR Debug Log: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} ===\n")

    FinanceARHandler.server_ip = host_ip

    httpd = http.server.HTTPServer(('0.0.0.0', port), FinanceARHandler)
    ctx   = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(CERT_FILE, KEY_FILE)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)

    url = f'https://{host_ip}:{port}'
    print()
    print('=' * 62)
    print('  FINANCE AR DASHBOARD  —  HTTPS SERVER')
    print('=' * 62)
    print(f'  IP   : {host_ip}')
    print(f'  Port : {port}')
    print()
    print(f'  MetaQuest Browser URL:')
    print(f'    {url}/{MAIN_HTML}')
    print()
    print(f'  3 AR Modes available:')
    print(f'    Mode 1 — Price Analysis   (OHLC · SMA · Bollinger)')
    print(f'    Mode 2 — Technical        (RSI · MACD · SMA lines)')
    print(f'    Mode 3 — Volatility       (Surface · Regimes · VaR)')
    print()
    print(f'  Debug log: {DEBUG_LOG}   (tail -f {DEBUG_LOG})')
    print()
    print('  Steps on MetaQuest Browser:')
    print('    1. Same WiFi as this PC')
    print('    2. Open URL above')
    print('    3. Advanced → Proceed  (accept cert warning)')
    print('    4. Tap "Start AR" button')
    print('    5. Aim LEFT controller ray at floating panel')
    print('    6. Pull LEFT TRIGGER to select a mode')
    print()
    print('  No WebSocket needed — runs on synthetic BTC/USD data')
    print('  Ctrl+C to stop')
    print('=' * 62)

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print('\n  Stopped.')


if __name__ == '__main__':
    main()
