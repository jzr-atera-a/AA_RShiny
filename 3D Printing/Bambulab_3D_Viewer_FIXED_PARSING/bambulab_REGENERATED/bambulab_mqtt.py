"""
Bambulab A1 MQTT Connection Helper
Connects to Bambulab printers via MQTT over LAN
"""

import paho.mqtt.client as mqtt
import json
import sys
import time
import ssl
from ftplib import FTP
import os

class BambulabPrinter:
    def __init__(self, ip, access_code, serial):
        self.ip = ip
        self.access_code = access_code
        self.serial = serial
        self.mqtt_client = None
        self.is_connected = False
        self.status_data = {}
        
        # MQTT configuration
        self.mqtt_port = 8883
        self.username = "bblp"
        
    def on_connect(self, client, userdata, flags, rc):
        """Callback when connected to MQTT broker"""
        if rc == 0:
            # Print to stdout for R to capture
            print(json.dumps({"status": "connected", "message": "Successfully connected to printer"}), flush=True)
            self.is_connected = True
            
            # Subscribe to status updates
            topic = f"device/{self.serial}/report"
            client.subscribe(topic)
            
            # Request status update
            self.request_push_all()
        else:
            error_msg = f"Connection failed with code {rc}"
            if rc == 4:
                error_msg = "Authentication failed - check access code (must be 8 digits)"
            elif rc == 5:
                error_msg = "Not authorized - check access code"
            
            # Print error to stdout as JSON for R to parse
            print(json.dumps({"status": "error", "message": error_msg}), flush=True)
            sys.stderr.write(f"MQTT Error: {error_msg}\n")
            
    def on_message(self, client, userdata, msg):
        """Callback when message received"""
        try:
            payload = json.loads(msg.payload.decode())
            
            # Store status data
            if 'print' in payload:
                self.status_data.update(payload)
                
            # Print message for debugging
            print(json.dumps({"topic": msg.topic, "data": payload}))
            
        except json.JSONDecodeError:
            pass
            
    def on_disconnect(self, client, userdata, rc):
        """Callback when disconnected"""
        self.is_connected = False
        print(json.dumps({"status": "disconnected", "message": "Disconnected from printer"}))
        
    def connect(self):
        """Connect to printer via MQTT"""
        try:
            self.mqtt_client = mqtt.Client(client_id=f"python_client_{int(time.time())}")
            
            # Set credentials
            self.mqtt_client.username_pw_set(self.username, self.access_code)
            
            # Set callbacks
            self.mqtt_client.on_connect = self.on_connect
            self.mqtt_client.on_message = self.on_message
            self.mqtt_client.on_disconnect = self.on_disconnect
            
            # Enable TLS
            self.mqtt_client.tls_set(cert_reqs=ssl.CERT_NONE)
            self.mqtt_client.tls_insecure_set(True)
            
            # Connect
            self.mqtt_client.connect(self.ip, self.mqtt_port, 60)
            
            # Start loop in background
            self.mqtt_client.loop_start()
            
            # Wait for connection
            timeout = 10
            start_time = time.time()
            while not self.is_connected and time.time() - start_time < timeout:
                time.sleep(0.1)
                
            if not self.is_connected:
                print(json.dumps({"status": "error", "message": "Connection timeout - printer not responding"}), flush=True)
                return False
                
            return True
            
        except Exception as e:
            error_msg = str(e)
            # More specific error messages
            if "11001" in error_msg or "getaddrinfo" in error_msg:
                error_msg = f"Cannot reach printer at {self.ip}. Check IP address and network connection."
            elif "timed out" in error_msg.lower():
                error_msg = f"Connection timeout. Printer may be off or unreachable at {self.ip}"
            elif "refused" in error_msg.lower():
                error_msg = f"Connection refused. Check firewall or printer settings."
            
            print(json.dumps({"status": "error", "message": error_msg}), flush=True)
            sys.stderr.write(f"Connection error: {error_msg}\n")
            return False
            
    def disconnect(self):
        """Disconnect from printer"""
        if self.mqtt_client:
            self.mqtt_client.loop_stop()
            self.mqtt_client.disconnect()
            
    def publish_command(self, command):
        """Publish command to printer"""
        if not self.is_connected:
            raise Exception("Not connected to printer")
            
        topic = f"device/{self.serial}/request"
        self.mqtt_client.publish(topic, json.dumps(command))
        
    def request_push_all(self):
        """Request full status update"""
        command = {
            "pushing": {
                "sequence_id": "0",
                "command": "pushall"
            }
        }
        self.publish_command(command)
        
    def get_status(self):
        """Get current printer status"""
        return self.status_data
        
    def get_temperature(self):
        """Get current temperatures"""
        if 'print' in self.status_data:
            print_data = self.status_data['print']
            return {
                'nozzle_temp': print_data.get('nozzle_temper', 0),
                'nozzle_target': print_data.get('nozzle_target_temper', 0),
                'bed_temp': print_data.get('bed_temper', 0),
                'bed_target': print_data.get('bed_target_temper', 0),
                'chamber_temp': print_data.get('chamber_temper', 0)
            }
        return None
        
    def get_print_info(self):
        """Get print job information"""
        if 'print' in self.status_data:
            print_data = self.status_data['print']
            return {
                'status': print_data.get('gcode_state', 'IDLE'),
                'progress': print_data.get('mc_percent', 0),
                'remaining_time': print_data.get('mc_remaining_time', 0),
                'current_layer': print_data.get('layer_num', 0),
                'total_layers': print_data.get('total_layer_num', 0),
                'file_name': print_data.get('gcode_file', '')
            }
        return None
        
    def start_print(self, filename, plate_number=1, use_ams=True):
        """Start a print job"""
        command = {
            "print": {
                "sequence_id": "0",
                "command": "project_file",
                "param": f"Metadata/plate_{plate_number}.gcode",
                "subtask_name": filename,
                "url": f"ftp://{filename}",
                "bed_type": "auto",
                "use_ams": use_ams
            }
        }
        self.publish_command(command)
        
    def pause_print(self):
        """Pause current print"""
        command = {
            "print": {
                "sequence_id": "0",
                "command": "pause"
            }
        }
        self.publish_command(command)
        
    def resume_print(self):
        """Resume paused print"""
        command = {
            "print": {
                "sequence_id": "0",
                "command": "resume"
            }
        }
        self.publish_command(command)
        
    def stop_print(self):
        """Stop current print"""
        command = {
            "print": {
                "sequence_id": "0",
                "command": "stop"
            }
        }
        self.publish_command(command)
        
    def set_temperature(self, nozzle=None, bed=None):
        """Set target temperatures"""
        if nozzle is not None:
            command = {
                "print": {
                    "sequence_id": "0",
                    "command": "gcode_line",
                    "param": f"M104 S{nozzle}"
                }
            }
            self.publish_command(command)
            
        if bed is not None:
            command = {
                "print": {
                    "sequence_id": "0",
                    "command": "gcode_line",
                    "param": f"M140 S{bed}"
                }
            }
            self.publish_command(command)
            
    def send_gcode(self, gcode):
        """Send custom G-code command"""
        command = {
            "print": {
                "sequence_id": "0",
                "command": "gcode_line",
                "param": gcode
            }
        }
        self.publish_command(command)
        
    def upload_file_ftp(self, local_path, filename=None):
        """Upload file to printer via FTP"""
        if filename is None:
            filename = os.path.basename(local_path)
            
        try:
            # Connect to FTP
            ftp = FTP()
            ftp.connect(self.ip, 990, timeout=30)
            ftp.login('bblp', self.access_code)
            
            # Switch to binary mode
            ftp.sendcmd('TYPE I')
            
            # Upload file
            with open(local_path, 'rb') as f:
                ftp.storbinary(f'STOR {filename}', f)
                
            ftp.quit()
            
            return {
                'status': 'success',
                'filename': filename,
                'message': 'File uploaded successfully'
            }
            
        except Exception as e:
            return {
                'status': 'error',
                'message': str(e)
            }
            
    def get_light_state(self):
        """Get chamber light state"""
        if 'print' in self.status_data:
            return self.status_data['print'].get('lights_report', [{'mode': 'off'}])[0].get('mode')
        return None
        
    def set_light(self, mode='on'):
        """Control chamber light (on/off)"""
        command = {
            "system": {
                "sequence_id": "0",
                "command": "ledctrl",
                "led_node": "chamber_light",
                "led_mode": mode,
                "led_on_time": 500,
                "led_off_time": 500,
                "loop_times": 0,
                "interval_time": 0
            }
        }
        self.publish_command(command)

def main():
    """Command-line interface"""
    if len(sys.argv) < 2:
        print("Usage: python bambulab_mqtt.py <command> [args...]")
        print("\nCommands:")
        print("  connect <ip> <access_code> <serial>")
        print("  status <ip> <access_code> <serial>")
        print("  temps <ip> <access_code> <serial>")
        print("  print_info <ip> <access_code> <serial>")
        print("  start_print <ip> <access_code> <serial> <filename>")
        print("  pause <ip> <access_code> <serial>")
        print("  resume <ip> <access_code> <serial>")
        print("  stop <ip> <access_code> <serial>")
        print("  gcode <ip> <access_code> <serial> <command>")
        print("  upload <ip> <access_code> <serial> <filepath>")
        print("  light <ip> <access_code> <serial> <on|off>")
        sys.exit(1)
        
    command = sys.argv[1]
    
    try:
        if command == "connect":
            ip = sys.argv[2]
            access_code = sys.argv[3]
            serial = sys.argv[4]
            
            printer = BambulabPrinter(ip, access_code, serial)
            if printer.connect():
                time.sleep(2)  # Wait for initial data
                printer.disconnect()
                
        elif command == "status":
            ip = sys.argv[2]
            access_code = sys.argv[3]
            serial = sys.argv[4]
            
            printer = BambulabPrinter(ip, access_code, serial)
            printer.connect()
            time.sleep(3)  # Wait for status data
            status = printer.get_status()
            print(json.dumps(status, indent=2))
            printer.disconnect()
            
        elif command == "temps":
            ip = sys.argv[2]
            access_code = sys.argv[3]
            serial = sys.argv[4]
            
            printer = BambulabPrinter(ip, access_code, serial)
            printer.connect()
            time.sleep(3)
            temps = printer.get_temperature()
            print(json.dumps(temps, indent=2))
            printer.disconnect()
            
        elif command == "print_info":
            ip = sys.argv[2]
            access_code = sys.argv[3]
            serial = sys.argv[4]
            
            printer = BambulabPrinter(ip, access_code, serial)
            printer.connect()
            time.sleep(3)
            info = printer.get_print_info()
            print(json.dumps(info, indent=2))
            printer.disconnect()
            
        elif command == "start_print":
            ip = sys.argv[2]
            access_code = sys.argv[3]
            serial = sys.argv[4]
            filename = sys.argv[5]
            
            printer = BambulabPrinter(ip, access_code, serial)
            printer.connect()
            time.sleep(2)
            printer.start_print(filename)
            print(json.dumps({"status": "success", "message": "Print started"}))
            time.sleep(2)
            printer.disconnect()
            
        elif command == "pause":
            ip = sys.argv[2]
            access_code = sys.argv[3]
            serial = sys.argv[4]
            
            printer = BambulabPrinter(ip, access_code, serial)
            printer.connect()
            time.sleep(2)
            printer.pause_print()
            print(json.dumps({"status": "success", "message": "Print paused"}))
            time.sleep(2)
            printer.disconnect()
            
        elif command == "resume":
            ip = sys.argv[2]
            access_code = sys.argv[3]
            serial = sys.argv[4]
            
            printer = BambulabPrinter(ip, access_code, serial)
            printer.connect()
            time.sleep(2)
            printer.resume_print()
            print(json.dumps({"status": "success", "message": "Print resumed"}))
            time.sleep(2)
            printer.disconnect()
            
        elif command == "stop":
            ip = sys.argv[2]
            access_code = sys.argv[3]
            serial = sys.argv[4]
            
            printer = BambulabPrinter(ip, access_code, serial)
            printer.connect()
            time.sleep(2)
            printer.stop_print()
            print(json.dumps({"status": "success", "message": "Print stopped"}))
            time.sleep(2)
            printer.disconnect()
            
        elif command == "gcode":
            ip = sys.argv[2]
            access_code = sys.argv[3]
            serial = sys.argv[4]
            gcode = sys.argv[5]
            
            printer = BambulabPrinter(ip, access_code, serial)
            printer.connect()
            time.sleep(2)
            printer.send_gcode(gcode)
            print(json.dumps({"status": "success", "message": "G-code sent"}))
            time.sleep(2)
            printer.disconnect()
            
        elif command == "upload":
            ip = sys.argv[2]
            access_code = sys.argv[3]
            serial = sys.argv[4]
            filepath = sys.argv[5]
            
            printer = BambulabPrinter(ip, access_code, serial)
            result = printer.upload_file_ftp(filepath)
            print(json.dumps(result, indent=2))
            
        elif command == "light":
            ip = sys.argv[2]
            access_code = sys.argv[3]
            serial = sys.argv[4]
            mode = sys.argv[5]
            
            printer = BambulabPrinter(ip, access_code, serial)
            printer.connect()
            time.sleep(2)
            printer.set_light(mode)
            print(json.dumps({"status": "success", "message": f"Light turned {mode}"}))
            time.sleep(2)
            printer.disconnect()
            
        else:
            print(f"Unknown command: {command}")
            sys.exit(1)
            
    except Exception as e:
        print(json.dumps({"status": "error", "message": str(e)}), file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
