"""
Simple Flask server for Arduino serial communication
Run this FIRST before starting R Shiny app
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import serial
import time
import threading

app = Flask(__name__)
CORS(app)

# Global variables
arduino = None
connected = False
current_angle = 90
last_message = ""

def connect_arduino(port='COM1', baudrate=9600):
    global arduino, connected, last_message
    try:
        arduino = serial.Serial(port, baudrate, timeout=1)
        time.sleep(2)  # Wait for Arduino reset
        
        # Read initial message
        if arduino.in_waiting > 0:
            msg = arduino.readline().decode('utf-8').strip()
            last_message = msg
            print(f"Arduino says: {msg}")
        
        connected = True
        print(f"✅ Connected to {port}")
        return True
    except Exception as e:
        print(f"❌ Connection error: {e}")
        connected = False
        return False

def send_angle(angle):
    global arduino, connected, current_angle, last_message
    
    if not connected:
        return {'status': 'error', 'message': 'Not connected'}
    
    try:
        # Send command
        arduino.write(f"{angle}\n".encode())
        time.sleep(0.1)
        
        # Read response
        if arduino.in_waiting > 0:
            response = arduino.readline().decode('utf-8').strip()
            last_message = response
            
            # Extract angle from response
            if "ANGLE:" in response:
                reported_angle = int(response.split("ANGLE:")[1])
                current_angle = reported_angle
        
        return {
            'status': 'success',
            'angle': angle,
            'message': last_message
        }
    except Exception as e:
        return {
            'status': 'error',
            'message': str(e)
        }

# ===== API ENDPOINTS =====

@app.route('/')
def home():
    return jsonify({
        'status': 'running',
        'connected': connected,
        'current_angle': current_angle
    })

@app.route('/connect', methods=['POST'])
def connect():
    data = request.json
    port = data.get('port', 'COM1')
    
    result = connect_arduino(port)
    
    return jsonify({
        'status': 'success' if result else 'error',
        'connected': connected,
        'message': 'Connected' if result else 'Connection failed'
    })

@app.route('/disconnect', methods=['POST'])
def disconnect():
    global arduino, connected
    
    try:
        if arduino:
            arduino.close()
        connected = False
        return jsonify({'status': 'success', 'message': 'Disconnected'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/angle', methods=['POST'])
def set_angle():
    data = request.json
    angle = data.get('angle', 90)
    
    result = send_angle(angle)
    return jsonify(result)

@app.route('/status', methods=['GET'])
def status():
    return jsonify({
        'connected': connected,
        'current_angle': current_angle,
        'last_message': last_message
    })

if __name__ == '__main__':
    print("=" * 50)
    print("🤖 Arduino Servo Control Server")
    print("=" * 50)
    print("Starting server on http://localhost:5000")
    print("Make sure Arduino is connected to COM1")
    print("=" * 50)
    
    app.run(host='127.0.0.1', port=5000, debug=False)
