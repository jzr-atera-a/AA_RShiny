#!/usr/bin/env python3
"""
Quick test script to verify Python and MQTT setup
Run this before using the R Shiny app
"""

import sys

def test_python():
    print("✓ Python is working!")
    print(f"  Python version: {sys.version}")
    print(f"  Python executable: {sys.executable}")
    return True

def test_paho_mqtt():
    try:
        import paho.mqtt.client as mqtt
        print("✓ paho-mqtt library is installed!")
        print(f"  Version: {mqtt.__version__ if hasattr(mqtt, '__version__') else 'Unknown'}")
        return True
    except ImportError as e:
        print("✗ paho-mqtt library NOT installed!")
        print(f"  Error: {e}")
        print("\n  Fix: Run one of these commands:")
        print("    python -m pip install paho-mqtt")
        print("    OR")
        print("    Double-click install_mqtt.bat (Windows)")
        print("    OR")
        print("    ./install_mqtt.sh (Mac/Linux)")
        return False

def test_json():
    try:
        import json
        print("✓ json library is available!")
        return True
    except ImportError:
        print("✗ json library NOT available!")
        return False

def test_bambulab_script():
    import os
    if os.path.exists("bambulab_mqtt.py"):
        print("✓ bambulab_mqtt.py found!")
        return True
    else:
        print("✗ bambulab_mqtt.py NOT found!")
        print("  Make sure the script is in the same directory")
        return False

def main():
    print("=" * 50)
    print("Bambulab Printer Setup Test")
    print("=" * 50)
    print()
    
    results = []
    
    # Test 1: Python
    results.append(test_python())
    print()
    
    # Test 2: paho-mqtt
    results.append(test_paho_mqtt())
    print()
    
    # Test 3: json
    results.append(test_json())
    print()
    
    # Test 4: Script file
    results.append(test_bambulab_script())
    print()
    
    # Summary
    print("=" * 50)
    if all(results):
        print("✓ ALL TESTS PASSED!")
        print("  You're ready to use the Bambulab controller")
    else:
        print("✗ SOME TESTS FAILED")
        print("  Please fix the issues above before proceeding")
        print()
        print("  Quick fix for paho-mqtt:")
        print(f"    {sys.executable} -m pip install paho-mqtt")
        print()
        print("  Or run:")
        print("    install_mqtt.bat (Windows)")
        print("    ./install_mqtt.sh (Mac/Linux)")
    print("=" * 50)
    
    return 0 if all(results) else 1

if __name__ == "__main__":
    sys.exit(main())
