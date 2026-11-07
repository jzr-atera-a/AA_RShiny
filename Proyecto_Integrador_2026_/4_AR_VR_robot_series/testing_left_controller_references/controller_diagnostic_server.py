#!/usr/bin/env python3
"""
Controller Diagnostic WebSocket Server
Receives left controller position and orientation from the Quest 3
and displays live readings in the terminal.

Port: 8446 (WSS)  — does not conflict with robot server on 8444

Usage:
    python controller_diagnostic_server.py                   # auto IP
    python controller_diagnostic_server.py 192.168.100.10    # specific IP

Requirements:
    - pip install websockets
    - cert.pem and key.pem (same certificates as main robot server)
"""

import asyncio
import websockets
import ssl
import json
import os
import sys
from datetime import datetime

PORT      = 8446
CERT_FILE = 'cert.pem'
KEY_FILE  = 'key.pem'

# ANSI colours
R   = '\033[91m'
G   = '\033[92m'
B   = '\033[96m'
Y   = '\033[93m'
W   = '\033[97m'
DIM = '\033[2m'
RST = '\033[0m'
BLD = '\033[1m'
CLR = '\033[2J\033[H'


def get_local_ip():
    import socket
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return 'UNKNOWN'


def bar(value, lo, hi, width=18):
    ratio  = max(0.0, min(1.0, (value - lo) / (hi - lo)))
    filled = round(ratio * width)
    return '█' * filled + DIM + '░' * (width - filled) + RST


def centre_bar(value, width=18):
    half  = width // 2
    count = min(half, round(abs(value) / 180 * half))
    if value >= 0:
        return DIM + '─' * half + RST + G + '█' * count + RST + ' ' * (half - count)
    else:
        return ' ' * (half - count) + R + '█' * count + RST + DIM + '─' * half + RST


def render(data):
    pos   = data.get('pos',   {})
    euler = data.get('euler', {})
    quat  = data.get('quat',  {})

    px, py, pz = pos.get('x', 0.0), pos.get('y', 0.0), pos.get('z', 0.0)
    pitch = euler.get('pitch', 0.0)
    yaw   = euler.get('yaw',   0.0)
    roll  = euler.get('roll',  0.0)
    qx = quat.get('x', 0.0); qy = quat.get('y', 0.0)
    qz = quat.get('z', 0.0); qw = quat.get('w', 1.0)

    now = datetime.now().strftime('%H:%M:%S.%f')[:-3]

    print(CLR, end='')
    print(f"{BLD}{'='*62}{RST}")
    print(f"{BLD}  LEFT CONTROLLER DIAGNOSTIC{RST}          {DIM}{now}{RST}")
    print(f"{BLD}{'='*62}{RST}")

    print(f"\n{BLD}{W}  POSITION  {DIM}(metres){RST}")
    print(f"  {'-'*58}")
    print(f"  {R}X{RST}  left/right   {R}{px:+8.4f} m{RST}   {bar(px, -2.0, 2.0)}")
    print(f"  {G}Y{RST}  up/down      {G}{py:+8.4f} m{RST}   {bar(py,  0.0, 2.0)}")
    print(f"  {B}Z{RST}  fwd/back     {B}{pz:+8.4f} m{RST}   {bar(pz, -2.0, 2.0)}")

    print(f"\n{BLD}{W}  ORIENTATION  {DIM}(degrees){RST}")
    print(f"  {'-'*58}")
    print(f"  {R}Pitch{RST}  X-axis   {R}{pitch:+8.1f} deg{RST}   {centre_bar(pitch)}")
    print(f"  {G}Yaw  {RST}  Y-axis   {G}{yaw:+8.1f} deg{RST}   {centre_bar(yaw)}")
    print(f"  {B}Roll {RST}  Z-axis   {B}{roll:+8.1f} deg{RST}   {centre_bar(roll)}")

    print(f"\n{BLD}{W}  QUATERNION  {DIM}(raw){RST}")
    print(f"  {'-'*58}")
    print(f"  {DIM}qX{RST} {Y}{qx:+.6f}{RST}   "
          f"{DIM}qY{RST} {Y}{qy:+.6f}{RST}   "
          f"{DIM}qZ{RST} {Y}{qz:+.6f}{RST}   "
          f"{DIM}qW{RST} {Y}{qw:+.6f}{RST}")

    print(f"\n{BLD}{'='*62}{RST}")
    print(f"  {DIM}Ctrl+C to stop{RST}")


async def handle_client(websocket):
    addr = websocket.remote_address
    print(f"\n{G}+ Quest connected from {addr[0]}:{addr[1]}{RST}\n")
    try:
        async for message in websocket:
            try:
                render(json.loads(message))
            except json.JSONDecodeError:
                print(f"Non-JSON: {message[:80]}")
    except websockets.exceptions.ConnectionClosed:
        print(f"\nQuest disconnected.\n")


async def main():
    if len(sys.argv) >= 2:
        local_ip = sys.argv[1]
    else:
        local_ip = get_local_ip()

    if not os.path.exists(CERT_FILE) or not os.path.exists(KEY_FILE):
        print(f"\nERROR: {CERT_FILE} / {KEY_FILE} not found.")
        print("Generate with:")
        print("  openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes")
        sys.exit(1)

    ssl_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_ctx.load_cert_chain(certfile=CERT_FILE, keyfile=KEY_FILE)

    print(f"\n{'='*62}")
    print(f"  LEFT CONTROLLER DIAGNOSTIC - WebSocket Server")
    print(f"{'='*62}")
    print(f"  Port : {PORT} (WSS)")
    print(f"  IP   : {local_ip}")
    print(f"\n  HTML page auto-connects to: wss://{local_ip}:{PORT}")
    print(f"  Cert : {CERT_FILE}   Key: {KEY_FILE}")
    print(f"\nWaiting for Quest connection...")
    print(f"{'='*62}\n")

    async with websockets.serve(handle_client, '0.0.0.0', PORT, ssl=ssl_ctx):
        await asyncio.Future()


if __name__ == '__main__':
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print(f"\nServer stopped.\n")
