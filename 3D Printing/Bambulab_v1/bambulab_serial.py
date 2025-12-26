"""
Bambulab A1 Serial Communication Helper
Python script for handling USB serial communication with the printer
Can be called from R using system() commands
"""

import serial
import serial.tools.list_ports
import sys
import time
import json

class BambulabPrinter:
    def __init__(self, port=None, baud_rate=115200):
        self.port = port
        self.baud_rate = baud_rate
        self.connection = None
        self.is_connected = False
        
    def list_ports(self):
        """List all available COM ports"""
        ports = serial.tools.list_ports.comports()
        available_ports = []
        
        for port in ports:
            available_ports.append({
                'port': port.device,
                'description': port.description,
                'hwid': port.hwid
            })
        
        return available_ports
    
    def connect(self, port=None, baud_rate=None):
        """Connect to the printer"""
        if port:
            self.port = port
        if baud_rate:
            self.baud_rate = baud_rate
            
        if not self.port:
            raise ValueError("No port specified")
        
        try:
            self.connection = serial.Serial(
                port=self.port,
                baudrate=self.baud_rate,
                bytesize=serial.EIGHTBITS,
                parity=serial.PARITY_NONE,
                stopbits=serial.STOPBITS_ONE,
                timeout=2,
                xonxoff=False,
                rtscts=False,
                dsrdtr=False
            )
            
            time.sleep(2)  # Wait for connection to stabilize
            
            # Clear any initial data
            self.connection.reset_input_buffer()
            self.connection.reset_output_buffer()
            
            self.is_connected = True
            return True
            
        except serial.SerialException as e:
            self.is_connected = False
            raise Exception(f"Failed to connect: {str(e)}")
    
    def disconnect(self):
        """Disconnect from the printer"""
        if self.connection and self.connection.is_open:
            self.connection.close()
        self.is_connected = False
    
    def send_command(self, command, wait_for_response=True, timeout=5):
        """Send a G-code command to the printer"""
        if not self.is_connected or not self.connection:
            raise Exception("Not connected to printer")
        
        # Ensure command ends with newline
        if not command.endswith('\n'):
            command += '\n'
        
        try:
            # Send command
            self.connection.write(command.encode('utf-8'))
            
            if wait_for_response:
                response_lines = []
                start_time = time.time()
                
                while True:
                    if time.time() - start_time > timeout:
                        break
                    
                    if self.connection.in_waiting > 0:
                        line = self.connection.readline().decode('utf-8').strip()
                        if line:
                            response_lines.append(line)
                            
                            # Check for completion indicators
                            if 'ok' in line.lower() or 'error' in line.lower():
                                break
                
                return '\n'.join(response_lines)
            
            return "Command sent"
            
        except Exception as e:
            raise Exception(f"Error sending command: {str(e)}")
    
    def get_temperature(self):
        """Get current temperatures"""
        response = self.send_command("M105")
        
        # Parse temperature response
        # Format: ok T:25.0 /0.0 B:25.0 /0.0
        temps = {
            'hotend_current': 0,
            'hotend_target': 0,
            'bed_current': 0,
            'bed_target': 0
        }
        
        try:
            if 'T:' in response:
                t_part = response.split('T:')[1].split()[0]
                temps['hotend_current'] = float(t_part.split('/')[0])
                temps['hotend_target'] = float(t_part.split('/')[1])
            
            if 'B:' in response:
                b_part = response.split('B:')[1].split()[0]
                temps['bed_current'] = float(b_part.split('/')[0])
                temps['bed_target'] = float(b_part.split('/')[1])
        except:
            pass
        
        return temps
    
    def get_position(self):
        """Get current position"""
        response = self.send_command("M114")
        
        # Parse position response
        # Format: X:0.00 Y:0.00 Z:0.00 E:0.00
        position = {
            'x': 0,
            'y': 0,
            'z': 0,
            'e': 0
        }
        
        try:
            parts = response.split()
            for part in parts:
                if part.startswith('X:'):
                    position['x'] = float(part.split(':')[1])
                elif part.startswith('Y:'):
                    position['y'] = float(part.split(':')[1])
                elif part.startswith('Z:'):
                    position['z'] = float(part.split(':')[1])
                elif part.startswith('E:'):
                    position['e'] = float(part.split(':')[1])
        except:
            pass
        
        return position
    
    def home_all(self):
        """Home all axes"""
        return self.send_command("G28")
    
    def home_axis(self, axis):
        """Home specific axis"""
        axis = axis.upper()
        if axis not in ['X', 'Y', 'Z']:
            raise ValueError("Invalid axis. Must be X, Y, or Z")
        return self.send_command(f"G28 {axis}")
    
    def set_temperature(self, hotend=None, bed=None):
        """Set target temperatures"""
        results = []
        
        if hotend is not None:
            results.append(self.send_command(f"M104 S{hotend}"))
        
        if bed is not None:
            results.append(self.send_command(f"M140 S{bed}"))
        
        return '\n'.join(results)
    
    def move(self, x=None, y=None, z=None, feedrate=3000):
        """Move to position"""
        command = "G1"
        
        if x is not None:
            command += f" X{x}"
        if y is not None:
            command += f" Y{y}"
        if z is not None:
            command += f" Z{z}"
        
        command += f" F{feedrate}"
        
        return self.send_command(command)
    
    def extrude(self, amount, feedrate=300):
        """Extrude filament"""
        return self.send_command(f"G1 E{amount} F{feedrate}")
    
    def set_fan_speed(self, speed):
        """Set fan speed (0-255)"""
        if speed < 0 or speed > 255:
            raise ValueError("Fan speed must be between 0 and 255")
        return self.send_command(f"M106 S{speed}")
    
    def send_file(self, filepath):
        """Send a G-code file to the printer"""
        if not self.is_connected:
            raise Exception("Not connected to printer")
        
        try:
            with open(filepath, 'r') as f:
                lines = f.readlines()
            
            total_lines = len(lines)
            for i, line in enumerate(lines):
                # Strip comments and whitespace
                line = line.split(';')[0].strip()
                
                if line:
                    self.send_command(line, wait_for_response=True)
                
                # Progress update every 10 lines
                if i % 10 == 0:
                    progress = (i / total_lines) * 100
                    print(f"Progress: {progress:.1f}%", file=sys.stderr)
            
            return "File sent successfully"
            
        except Exception as e:
            raise Exception(f"Error sending file: {str(e)}")

def main():
    """Command-line interface"""
    if len(sys.argv) < 2:
        print("Usage: python bambulab_serial.py <command> [args...]")
        print("\nCommands:")
        print("  list_ports")
        print("  connect <port> <baud_rate>")
        print("  send <port> <baud_rate> <command>")
        print("  get_temp <port> <baud_rate>")
        print("  get_pos <port> <baud_rate>")
        print("  home <port> <baud_rate> [axis]")
        print("  send_file <port> <baud_rate> <filepath>")
        sys.exit(1)
    
    command = sys.argv[1]
    printer = BambulabPrinter()
    
    try:
        if command == "list_ports":
            ports = printer.list_ports()
            print(json.dumps(ports, indent=2))
        
        elif command == "connect":
            port = sys.argv[2]
            baud_rate = int(sys.argv[3])
            printer.connect(port, baud_rate)
            print("Connected successfully")
        
        elif command == "send":
            port = sys.argv[2]
            baud_rate = int(sys.argv[3])
            gcode = sys.argv[4]
            
            printer.connect(port, baud_rate)
            response = printer.send_command(gcode)
            print(response)
            printer.disconnect()
        
        elif command == "get_temp":
            port = sys.argv[2]
            baud_rate = int(sys.argv[3])
            
            printer.connect(port, baud_rate)
            temps = printer.get_temperature()
            print(json.dumps(temps, indent=2))
            printer.disconnect()
        
        elif command == "get_pos":
            port = sys.argv[2]
            baud_rate = int(sys.argv[3])
            
            printer.connect(port, baud_rate)
            position = printer.get_position()
            print(json.dumps(position, indent=2))
            printer.disconnect()
        
        elif command == "home":
            port = sys.argv[2]
            baud_rate = int(sys.argv[3])
            axis = sys.argv[4] if len(sys.argv) > 4 else None
            
            printer.connect(port, baud_rate)
            if axis:
                result = printer.home_axis(axis)
            else:
                result = printer.home_all()
            print(result)
            printer.disconnect()
        
        elif command == "send_file":
            port = sys.argv[2]
            baud_rate = int(sys.argv[3])
            filepath = sys.argv[4]
            
            printer.connect(port, baud_rate)
            result = printer.send_file(filepath)
            print(result)
            printer.disconnect()
        
        else:
            print(f"Unknown command: {command}")
            sys.exit(1)
    
    except Exception as e:
        print(f"Error: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
