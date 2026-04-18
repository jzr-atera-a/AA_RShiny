# Meta Quest 3 Robot Control - Mode 1 Platform Test
## Quick Start Guide

---

## Required Files

Place all these files in the **same directory** on your Windows PC or Jetson Nano:

1. **trajectory_6modes.html** - AR application (main file)
2. **https_server.py** - Serves HTML file to Quest 3
3. **trajectory_websocket_server.py** - Forwards commands to Arduino
4. **cert.pem** - SSL certificate (generate below)
5. **key.pem** - SSL private key (generate below)
6. **arduino_actuator_controller.ino** - Arduino firmware (upload to Arduino)

---

## Step 1: Generate SSL Certificates

Open terminal/command prompt in the same directory and run:

```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

Press Enter through all prompts (or fill in as desired). This creates:
- **cert.pem** (certificate file)
- **key.pem** (private key file)

---

## Step 2: Upload Arduino Firmware

1. Open **Arduino IDE**
2. File → Open → Select `arduino_actuator_controller.ino`
3. Tools → Board → Select **Arduino Mega 2560**
4. Tools → Port → Select your Arduino's COM port (e.g., COM3 or /dev/ttyACM0)
5. Click **Upload** button
6. Wait for "Done uploading" message

**Arduino should respond with:**
```
Arduino Dual Servo + MD22 Motor Controller Ready
MD22 Status: Connected (or Not detected)
Current state - Servo1: 90° | Servo2: 90° | Motor1: 0% | Motor2: 0%
```

---

## Step 3: Install Python Dependencies

```bash
pip install websockets pyserial
```

Or on some systems:
```bash
pip3 install websockets pyserial
```

---

## Step 4: Start Servers

Open **TWO terminal windows** in the same directory:

### Terminal 1: HTTPS Server
```bash
python https_server.py
```

You should see:
```
Meta Quest 3 AR Application - HTTPS Server
✓ Server started successfully!

Server Details:
  - Port: 8443
  - Protocol: HTTPS
  - Local IP: 192.168.1.XXX

On your Meta Quest 3:
  Navigate to: https://192.168.1.XXX:8443/trajectory_6modes.html
```

**Note the IP address!**

### Terminal 2: WebSocket Server
```bash
python trajectory_websocket_server.py
```

You should see:
```
Meta Quest 3 Robot Control - WebSocket Server

Connecting to Arduino...
✓ Found Arduino on COM3 (or /dev/ttyACM0)
✓ Arduino connected successfully

✓ WebSocket server starting...
  wss://192.168.1.XXX:8444

Waiting for Quest 3 connection...
```

---

## Step 5: Connect Quest 3

1. **Put on Meta Quest 3**
2. **Connect to same WiFi** as your PC
3. **Open Quest Browser**
4. **Navigate to:** `https://YOUR_PC_IP:8443/trajectory_6modes.html`
   - Replace `YOUR_PC_IP` with IP from Step 4
   - Example: `https://192.168.1.100:8443/trajectory_6modes.html`
5. **Accept certificate warning** (self-signed certificate is safe)
6. **Allow VR mode** when prompted

---

## Step 6: Test Robot Control

### Platform Test Setup:
- Robot on raised platform (wheels off ground)
- Motors can spin freely
- Arduino powered via USB
- MD22 powered separately (12V)

### Controls:

**Right Controller:**
- **Thumbstick vertical:** Forward/stop (0-80% motor speed)
- **Thumbstick horizontal:** Steering (50°-130°)
- **A button:** Open gripper (40°)
- **B button:** Close gripper (140°)

**Expected Behavior:**
1. Push thumbstick forward → Both rear motors spin
2. Move thumbstick left/right → Steering servo rotates
3. Press A → Gripper opens
4. Press B → Gripper closes

### Terminal Output (WebSocket server):
```
[14:32:10.123] Quest → Arduino: MOTORS:65
[14:32:10.124] Arduino → Quest: OK: Both motors set to 65%
[14:32:10.323] Quest → Arduino: SERVO2:110
[14:32:10.324] Arduino → Quest: OK: Servo2 set to 110 degrees
```

---

## Troubleshooting

### Quest 3 won't connect to HTTPS server
- Verify Quest and PC on same WiFi network
- Check firewall allows ports 8443 and 8444
- Try PC IP address in browser (not localhost)

### WebSocket server can't find Arduino
- **Linux/Jetson:** Run `ls /dev/ttyACM*` to find port
- **Windows:** Check Device Manager → Ports (COM & LPT)
- **Permissions (Linux):** `sudo usermod -a -G dialout $USER` then logout/login

### Motors don't spin
- Check MD22 power supply (12V connected)
- Verify MD22 I2C connections (SDA/SCL to Arduino pins 20/21)
- Arduino Serial Monitor → Send `MOTORS:70` → Should see "OK: Both motors set to 70%"
- Check Arduino receives commands in Terminal 2

### Commands sent but no response
- Arduino may not have MD22 connected
- Check Arduino Serial Monitor for error messages
- Verify baud rate is 115200

---

## Command Reference

### Motor Commands:
```
MOTORS:0     Stop
MOTORS:50    Minimum speed (50%)
MOTORS:65    Medium speed
MOTORS:80    Maximum speed (80%)
```

### Servo Commands:
```
SERVO1:40    Gripper open
SERVO1:90    Gripper center
SERVO1:140   Gripper close

SERVO2:50    Steer full left
SERVO2:90    Steer center
SERVO2:130   Steer full right
```

---

## Success Criteria for Test 1

✅ **HTTPS server running** (Terminal 1)
✅ **WebSocket server connected to Arduino** (Terminal 2)
✅ **Quest 3 loads AR application** (white grid visible)
✅ **Right joystick controls motors** (wheels spin when pushed forward)
✅ **Right joystick controls steering** (servo rotates left/right)
✅ **A/B buttons control gripper** (servo opens/closes)
✅ **Terminal shows commands** (MOTORS:X, SERVO1:X, SERVO2:X)
✅ **Arduino responds** (OK messages in terminal)

---

## Next Steps After Test 1

Once platform test successful:

**Test 2:** Differential drive (independent motor control)
**Test 3:** Ground test with tracking (robot moves on floor)

---

## File Locations

All files should be in **ONE directory**:

```
C:\RobotControl\          (Windows example)
├── trajectory_6modes.html
├── https_server.py
├── trajectory_websocket_server.py
├── cert.pem
├── key.pem
└── arduino_actuator_controller.ino
```

Or:

```
/home/user/robot/         (Linux/Jetson example)
├── trajectory_6modes.html
├── https_server.py
├── trajectory_websocket_server.py
├── cert.pem
├── key.pem
└── arduino_actuator_controller.ino
```

---

## Support

If issues persist:
1. Check Arduino Serial Monitor for detailed error messages
2. Verify all cables connected (USB, I2C, Power)
3. Test Arduino independently with Serial Monitor commands
4. Confirm WebSocket server sees Quest 3 connection

---

**Good luck with Test 1!** 🤖🎮
