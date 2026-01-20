#!/usr/bin/env python3
"""
HTTPS server for Quest 3 WebXR
Serves files over HTTPS so navigator.xr is available
"""

import http.server
import ssl
import os

# Check if certificate files exist
if not os.path.exists('cert.pem') or not os.path.exists('key.pem'):
    print("ERROR: Certificate files not found!")
    print("\nRun this first:")
    print("  python generate_cert.py")
    exit(1)

# Server configuration
HOST = '0.0.0.0'  # Listen on all interfaces
PORT = 8000

# Create HTTPS server
server_address = (HOST, PORT)
httpd = http.server.HTTPServer(server_address, http.server.SimpleHTTPRequestHandler)

# Create SSL context (modern method)
ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ssl_context.load_cert_chain(certfile='cert.pem', keyfile='key.pem')

# Wrap socket with SSL
httpd.socket = ssl_context.wrap_socket(httpd.socket, server_side=True)

print("=" * 60)
print("HTTPS Server Running!")
print("=" * 60)
print(f"URL: https://192.168.100.2:{PORT}/")
print("\nServing files from:", os.getcwd())
print("\nOn Quest 3, go to:")
print(f"  https://192.168.100.2:{PORT}/cones.html")
print("\nPress Ctrl+C to stop")
print("=" * 60)

try:
    httpd.serve_forever()
except KeyboardInterrupt:
    print("\n\nServer stopped.")
