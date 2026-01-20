#!/usr/bin/env python3
"""
Generate self-signed SSL certificate for HTTPS server
"""

try:
    from OpenSSL import crypto
    
    print("Generating SSL certificate...")
    
    # Generate key
    key = crypto.PKey()
    key.generate_key(crypto.TYPE_RSA, 2048)
    
    # Generate certificate
    cert = crypto.X509()
    cert.get_subject().CN = "192.168.100.2"
    cert.set_serial_number(1000)
    cert.gmtime_adj_notBefore(0)
    cert.gmtime_adj_notAfter(365*24*60*60)  # Valid for 1 year
    cert.set_issuer(cert.get_subject())
    cert.set_pubkey(key)
    cert.sign(key, 'sha256')
    
    # Save files
    with open('cert.pem', 'wb') as f:
        f.write(crypto.dump_certificate(crypto.FILETYPE_PEM, cert))
    
    with open('key.pem', 'wb') as f:
        f.write(crypto.dump_privatekey(crypto.FILETYPE_PEM, key))
    
    print("✓ SUCCESS!")
    print("  cert.pem - Certificate file")
    print("  key.pem  - Private key file")
    print("\nNow run: python https_server.py")

except ImportError:
    print("ERROR: pyOpenSSL not installed")
    print("\nInstall it with:")
    print("  pip install pyopenssl")
    print("\nThen run this script again.")
