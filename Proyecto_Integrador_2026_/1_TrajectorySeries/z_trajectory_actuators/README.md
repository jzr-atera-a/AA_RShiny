# Quest 3 Robot Trajectory with Arduino Control

Complete system for drawing trajectories in AR and executing them on a 4-wheel Ackerman-steered robot via Arduino.

## System Overview

**Hardware:**
- Meta Quest 3 (AR trajectory drawing)
- Jetson Nano (command generation + serial communication)
- Arduino Mega 2560 (actuator control)
- 4-wheel robot with Ackerman steering

**Robot Configuration:**
- Front wheels: Servo-controlled Ackerman steering (SERVO2, pin 9, range 50-130°)
- Rear wheels: 2x DC motors via MD22 H-bridge
- Turning radius: 50cm minimum
- Wheelbase: 34cm
- **Motor range: 50-80% power (SAFETY LIMITED)**

## Files

```
z_trajectory_actuators.zip
├── trajectory_commands.html            - Quest 3 AR interface
├── trajectory_websocket_server.py      - Command generator with Arduino serial
├── arduino_actuator_controller.ino     - Arduino firmware
├── https_server.py                     - HTTPS file server
├── cert.pem                            - SSL certificate
├── key.pem                             - SSL private key
└── README.md                           - This file
```

## Setup

### 1. Arduino Setup

**Upload firmware:**
```
1. Open arduino_actuator_controller.ino in Arduino IDE
2. Select Board: Arduino Mega 2560
3. Select Port: /dev/ttyACM0 (or check with: ls /dev/ttyACM*)
4. Click Upload
```

**Hardware connections:**
- SERVO2 → Pin 9 (Ackerman steering)
- MD22 SDA → Pin 20
- MD22 SCL → Pin 21
- USB → Jetson Nano

**Verify:**
```bash
# Check Arduino is connected
ls -la /dev/ttyACM*

# Test communication (optional)
screen /dev/ttyACM0 115200
# Type: PING
# Should see: PONG
# Press Ctrl+A then K to exit
```

### 2. Jetson Nano Setup

```bash
# Extract files
unzip z_trajectory_actuators.zip
cd z_trajectory_actuators

# Install dependencies
pip3 install websockets pyserial --break-system-packages

# Verify Arduino connection
python3 -c "import serial; s=serial.Serial('/dev/ttyACM0',115200); print('Arduino OK')"
```

### 3. Start Servers

**Terminal 1 - Trajectory Server (with Arduino):**
```bash
python3 trajectory_websocket_server.py
```

You should see:
```
================================================================================
  ARDUINO INITIALIZATION
================================================================================
  Arduino Actuator Controller v1.0
  Servo1 initialized (Pin 8)
  Servo2 initialized (Pin 9)
  MD22 motor controller detected
  Ready for commands

✓ Arduino connected on /dev/ttyACM0
  Baud rate: 115200
================================================================================
```

**Terminal 2 - HTTPS Server:**
```bash
python3 https_server.py
```

### 4. Quest 3 Setup

1. Open Quest 3 browser
2. Navigate to: `https://192.168.100.10:8000/trajectory_commands.html`
3. Accept SSL certificate warning
4. Click "START AR" button

## Usage

### Drawing and Executing Trajectory

1. **Draw trajectory**
   - Point RIGHT controller at floor
   - Green reticle shows where you're pointing
   - Hold RIGHT TRIGGER to draw (green line)
   - Trajectory respects 50cm turning radius

2. **Approve trajectory**
   - Press GRIP button
   - Trajectory turns ORANGE
   - Ready to execute

3. **Execute on robot**
   - Press A BUTTON
   - Commands stream to Arduino at 5Hz (every 200ms)
   - Watch robot follow trajectory!
   - Terminal shows real-time execution

### Safety Features

✅ **Motor power limited to 50-80%** (was 90%)
✅ **Automatic slowdown** when approaching end
✅ **Emergency stop** on server shutdown
✅ **Servo limits** enforced (50-130°)

### Controls Summary

- **RIGHT TRIGGER**: Draw trajectory
- **GRIP**: Approve (turns orange)
- **A BUTTON**: Execute on robot
- **THUMBSTICK**: Delete last section (while drawing)

## Command Execution

### Flow

1. User presses A button
2. Trajectory sent to Jetson
3. Commands generated (instant)
4. Commands saved to CSV
5. **Commands streamed to Arduino at 5Hz**
6. Arduino controls servos + motors
7. Robot follows trajectory

### Terminal Output During Execution

```
================================================================================
  EXECUTING TRAJECTORY ON ROBOT (5 Hz)
================================================================================
    Time  DistOrg  DistEnd   SERVO2   MOTOR1   MOTOR2
------------------------------------------------------------------------------------
   0.000    0.000   21.428       90       80       80
   0.200    0.026   21.402       92       80       80
   0.400    0.052   21.376       95       80       80
   ...
  142.200   21.300    0.128       90       50       50
  142.400   21.428    0.000       90        0        0
================================================================================
  TRAJECTORY EXECUTION COMPLETE!
================================================================================
```

## Arduino Serial Commands

The Python server sends these commands every 200ms:

```
SERVO2:90\n          - Set steering angle
MOTORS:80\n          - Set both motors to 80% power
STOP_ALL_MOTORS\n    - Stop all motors (at trajectory end)
```

**Arduino responds:**
```
Servo2: OK (90°)
Motors: OK (80%)
Motors stopped
```

## Motor Speed Profile

| Distance to End | Motor Power | Speed (approx) |
|----------------|-------------|----------------|
| > 1.0m         | 80%         | 17 cm/s       |
| 0.5 - 1.0m     | 65%         | 13 cm/s       |
| < 0.5m         | 50%         | 8 cm/s        |
| 0m (end)       | 0%          | STOP          |

## Files Generated

### CSV File
Every trajectory execution creates: `robot_commands_YYYYMMDD_HHMMSS.csv`

```csv
timestamp,distance_from_origin,distance_to_end,SERVO2,MOTOR1,MOTOR2
0.000,0.000,21.428,90,80,80
0.200,0.026,21.402,92,80,80
...
```

**Use for:**
- Trajectory analysis
- Performance tuning
- Replay without Quest 3
- Debugging

## Troubleshooting

### Arduino Not Detected

```bash
# Check USB connection
ls /dev/ttyACM*

# If shows ttyUSB0 instead, edit trajectory_websocket_server.py:
ARDUINO_PORT = '/dev/ttyUSB0'

# Check permissions
sudo chmod 666 /dev/ttyACM0

# Add user to dialout group (permanent fix)
sudo usermod -a -G dialout $USER
# Then logout and login
```

### Robot Not Moving

1. Check MD22 power (12V connected?)
2. Check MD22 I2C address (default 0x58)
3. Test Arduino manually:
```bash
screen /dev/ttyACM0 115200
SERVO2:90
MOTORS:60
STOP_ALL_MOTORS
```

### Commands Not Executing

- Verify Arduino terminal shows "CONNECTED ✓"
- Check motor power limits in code
- Verify MD22 DIP switches (address 0x58)
- Check I2C connections (pins 20, 21)

### Trajectory Too Fast/Slow

Edit in `trajectory_websocket_server.py`:
```python
avg_speed = 0.13  # m/s - Increase/decrease this
```

## Safety Notes

⚠️ **IMPORTANT:**
- Always test in open area
- Keep emergency stop accessible (Ctrl+C stops server and robot)
- Motor power limited to 80% maximum
- Servo range limited to prevent mechanical damage
- Robot stops automatically at trajectory end

## Technical Details

### Timing
- Quest 3 → Jetson: Real-time via WebSocket
- Jetson → Arduino: 5Hz (200ms intervals)
- Arduino response: < 10ms

### Coordinate System
- Origin: Where user stands when starting AR
- Floor: 1.6m below Quest 3 headset
- Trajectory: Drawn on floor (XZ plane)

### Command Generation
1. Calculate curvature at each point (3-point method)
2. Convert curvature to steering angle (Ackerman formula)
3. Calculate motor speed based on distance remaining
4. Generate commands at 5Hz intervals
5. Add final STOP command

## Next Steps

✅ Drawing working
✅ Commands generating
✅ Arduino receiving
✅ Robot executing

**Possible enhancements:**
- Add encoder feedback for closed-loop control
- Add obstacle detection with sensors
- Implement path following PID control
- Add trajectory replay from CSV
- Create web interface for monitoring

## Support

**Check logs:**
- Jetson: Terminal output shows all commands
- Arduino: Serial monitor (115200 baud)
- Quest 3: Browser console (if accessible)

**Common issues:**
- Port permissions → `sudo chmod 666 /dev/ttyACM0`
- Wrong port → Check with `ls /dev/tty*`
- Motors not moving → Check MD22 power supply
- Servo jittering → Check servo power supply

## License

Educational and research use.
