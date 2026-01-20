# Meta Quest 3 4-Wheel Robot Actuator Control System

Control a 4-wheel robot with 2 servos and 2 DC motors using Meta Quest 3 VR controllers via Jetson Nano and Arduino Mega 2560.

## 🎯 System Overview

```
Meta Quest 3 Controllers
    ├─ LEFT Joystick Y → Motor1 & Motor2 (MD22): 50-90% forward speed
    └─ RIGHT Controller
        ├─ Joystick X → Servo2 (Pin 9): 50-130° (Steering)
        └─ A/B Buttons → Servo1 (Pin 8): 40-140°
            ↓ WebSocket over WiFi (WSS)
Jetson Nano (Python Server + Display)
            ↓ USB Serial (115200 baud)
Arduino Mega 2560 (Dual Servo + MD22 Motor Controller)
    ├─ I2C (Pins 20/21) → MD22 H-Bridge
    │   ├─ Motor1 (50-90% forward)
    │   └─ Motor2 (50-90% forward)
    ├─ PWM Pin 8 → Servo1 (40-140°)
    └─ PWM Pin 9 → Servo2 (50-130°) - Steering
```

## 🎮 Control Mapping

**LEFT Controller:**
- **Joystick Y-axis** → Controls Motor1 & Motor2 speed (MD22 via I2C)
  - Rest (Y=0): STOP (motors off)
  - Forward (Y=+1.0): 90% speed
  - **Deadzone**: ±10% to prevent accidental movement
  - **Speed Range**: 50-90% (motors don't move below 50%, 100% draws too much current)
  - **Linear mapping**: Halfway forward → 70% speed
  - **Note**: No backward motion (Y < 0 is ignored)

**RIGHT Controller:**
- **Joystick X-axis** → Controls Servo2 (Pin 9) - Steering
  - Left: 50°
  - Center: 90°
  - Right: 130°

- **Button A** → Move Servo1 toward 40°
  - Speed: 50°/second
  - Hold button to continuously move down
  
- **Button B** → Move Servo1 toward 140°
  - Speed: 100°/second
  - Hold button to continuously move up

## 📦 Files Included

| File | Purpose |
|------|---------|
| `actuators.html` | Quest 3 WebXR interface with motor + dual servo display |
| `actuator_websocket_server.py` | Jetson Nano WebSocket server with motor + servo control |
| `https_server.py` | HTTPS server to serve HTML to Quest 3 |
| `arduino_actuator_controller.ino` | Arduino sketch for MD22 motors + dual servo control |
| `cert.pem` / `key.pem` | SSL certificates (pre-generated) |
| `README.md` | This file |

## 🔧 Hardware Setup

### Required Hardware:
- **Meta Quest 3** with controllers
- **Jetson Nano** (any model)
- **Arduino Mega 2560** (required for I2C on pins 20/21)
- **MD22 H-Bridge** (Devantech MD22, I2C address 0x58)
  - DIP switches: ALL ON (1,2,3,4)
- **2x DC Motors** (connected to MD22 M1A/M1B, M2A/M2B)
- **2x Servo Motors**:
  - Servo1: Range 40-140° (any standard servo)
  - Servo2: Range 50-130° (any standard servo)
- **External 12V Power Supply** (for MD22 motor power)
- **USB Cable** (Arduino to Jetson Nano)
- **WiFi Router** (Quest 3 and Jetson on same network)

### MD22 H-Bridge Connections:

**MD22 to Arduino Mega:**
```
MD22 SDA → Arduino Pin 20 (SDA)
MD22 SCL → Arduino Pin 21 (SCL)
MD22 GND → Arduino GND
MD22 5V  → Arduino 5V (logic power)
```

**MD22 Motor Power:**
```
12V Power Supply (+) → MD22 12V input
12V Power Supply (-) → MD22 GND
```

**MD22 to Motors:**
```
Motor1 → MD22 M1A, M1B terminals
Motor2 → MD22 M2A, M2B terminals
```

### Servo Connections:

**Servo1 (Pin 8):**
```
Brown/Black  → Arduino GND
Red          → Arduino 5V
Orange/Yellow → Arduino Pin 8
```

**Servo2 (Pin 9):**
```
Brown/Black  → Arduino GND
Red          → Arduino 5V
Orange/Yellow → Arduino Pin 9
```

**⚠️ Important Notes:**
- MD22 DIP switches must be set to ALL ON for I2C address 0x58
- High-torque servos may need external 5V power supply
- MD22 requires external 12V power for motors (not from Arduino)
- Ensure common GND between Arduino, MD22, and power supply

---

## 🚀 Setup Instructions

### Part 1: Arduino Setup

#### Step 1: Upload Sketch to Arduino Mega 2560

1. **Connect Arduino Mega to your computer** (not Jetson yet)
2. **Open Arduino IDE**
3. **Load** `arduino_actuator_controller.ino`
4. **Select Board**: Tools → Board → Arduino Mega 2560
5. **Select Port**: Tools → Port → (your Arduino port, e.g., /dev/ttyACM0)
6. **Upload**: Click Upload button or Ctrl+U

#### Step 2: Test Arduino

1. **Open Serial Monitor**: Tools → Serial Monitor or Ctrl+Shift+M
2. **Set baud rate**: 115200
3. **Set line ending**: "Newline" or "Both NL & CR"
4. **You should see**:
   ```
   Initializing MD22...
     MD22 found at 0x58
     Software version: 7
     Mode set to: 0
     Acceleration set to 10
     Both motors stopped
   MD22 initialized successfully!
   
   Arduino Dual Servo + MD22 Motor Controller Ready
   Commands: SERVO1:angle, SERVO2:angle, MOTORS:speed, M1_STOP, M2_STOP
   Servo1 (Pin 8): Range 40-140 degrees (RIGHT A/B buttons)
   Servo2 (Pin 9): Range 50-130 degrees (RIGHT joystick X - steering)
   Motors (MD22 via I2C): Speed 50-90% forward (LEFT joystick Y)
   MD22 Status: Connected
   Current state - Servo1: 90° | Servo2: 90° | Motor1: 0% | Motor2: 0%
   ```

5. **Test commands**:
   ```
   PING                → Should respond "PONG"
   STATUS              → Should show servo angles and motor speeds
   SERVO1_CENTER       → Servo1 moves to 90°
   SERVO2_CENTER       → Servo2 moves to 90°
   SERVO1:40           → Servo1 moves to 40°
   SERVO1:140          → Servo1 moves to 140°
   SERVO2:50           → Servo2 moves to 50°
   SERVO2:130          → Servo2 moves to 130°
   MOTORS:50           → Both motors start at 50% speed
   MOTORS:70           → Both motors run at 70% speed
   MOTORS:90           → Both motors run at 90% speed
   MOTORS:0            → Both motors stop
   STOP_ALL_MOTORS     → Both motors stop
   ```

6. **Verify all components**:
   - Servos should move smoothly
   - Motors should respond to speed commands
   - MD22 status should show "Connected"

---

### Part 2: Jetson Nano Setup

#### Step 1: Transfer Files to Jetson

**Option A - SCP** (if SSH enabled):
```bash
scp * username@192.168.100.10:~/quest_actuators/
```

**Option B - USB Drive**:
1. Copy all files to USB drive
2. Plug into Jetson
3. Copy to home directory

#### Step 2: Connect Arduino to Jetson

1. **Disconnect Arduino from computer**
2. **Connect Arduino Mega to Jetson Nano via USB**
3. **On Jetson, verify connection**:
   ```bash
   ls /dev/ttyACM* /dev/ttyUSB*
   ```
   - Should show `/dev/ttyACM0` or `/dev/ttyUSB0`

4. **If port is different**, edit `actuator_websocket_server.py`:
   ```bash
   nano actuator_websocket_server.py
   # Line 30: Change ARDUINO_PORT to match your port
   ```

#### Step 3: Install Dependencies

On Jetson Nano:
```bash
# Install Python packages
pip3 install websockets pyserial

# Verify installation
python3 -c "import websockets; print('websockets OK')"
python3 -c "import serial; print('pyserial OK')"
```

#### Step 4: Start Servers

Open **TWO terminal windows** on Jetson:

**Terminal 1 - WebSocket Server:**
```bash
cd ~/quest_actuators
python3 actuator_websocket_server.py
```

Expected output:
```
Initializing Arduino connection...

Arduino startup messages:
  Initializing MD22...
    MD22 found at 0x58
    Software version: 7
  ...
  Arduino Dual Servo + MD22 Motor Controller Ready
  ...

✓ Arduino connected on /dev/ttyACM0

STARTING WEBSOCKET SERVER
Server: wss://0.0.0.0:8443
Quest 3 URL: https://192.168.100.10:8000/actuators.html

Waiting for Quest 3 connection...
```

**Terminal 2 - HTTPS Server:**
```bash
cd ~/quest_actuators
python3 https_server.py
```

Expected output:
```
HTTPS SERVER RUNNING
Server: https://192.168.100.10:8000

On Quest 3, navigate to:
  https://192.168.100.10:8000/actuators.html

⚠️  Accept certificate warning when prompted

Press Ctrl+C to stop
```

---

### Part 3: Quest 3 Setup

#### Step 1: Accept SSL Certificate for Port 8443

1. **Put on Meta Quest 3**
2. **Open Meta Browser**
3. **Navigate to**: `https://192.168.100.10:8443`
4. **You'll see**: "Your connection is not private" warning
5. **Click**: "Advanced"
6. **Click**: "Proceed to 192.168.100.10 (unsafe)"
7. **You'll see error message** - this is OK! Certificate is now accepted.

#### Step 2: Load Actuator Control Page

1. **In Meta Browser, navigate to**: `https://192.168.100.10:8000/actuators.html`
2. **Accept certificate warning** (same as above)
3. **You should see**:
   - Top banner: "Quest 3 → 4-Wheel Robot Actuator Control"
   - "Connected: YES" (green)
   - Three panels showing motors, servo1, and servo2 status
   - "START AR" button

#### Step 3: Enter AR Mode

1. **Click "START AR" button**
2. **Grant permissions** if asked
3. **You'll enter AR mode** - see your room through Quest cameras

#### Step 4: Control the Robot!

**Drive Forward (LEFT Joystick Y):**
1. **Push LEFT controller joystick FORWARD**
2. **Watch**: Both motors start spinning! Speed increases as you push further.
3. **Release joystick**: Motors stop immediately.
4. **Speed mapping**:
   - Slight push (past deadzone) → 50% speed
   - Halfway forward → 70% speed
   - Full forward → 90% speed

**Steer (RIGHT Joystick X):**
1. **Move RIGHT controller joystick LEFT/RIGHT**
2. **Watch**: Servo2 turns! (steering mechanism)

**Control Servo1 (RIGHT A/B Buttons):**
1. **Press and hold A button** on RIGHT controller
2. **Watch**: Servo1 moves toward 40°
3. **Press and hold B button** on RIGHT controller
4. **Watch**: Servo1 moves toward 140°

---

## 📊 What You'll See

### On Quest 3 Display:
```
Quest 3 → 4-Wheel Robot Actuator Control
Connected: YES | Commands: 1234

┌─ MOTORS (MD22) - LEFT JOYSTICK Y ─┐
│              70%                    │
│    🕹️ Joystick Y: +0.567           │
│  Rest: STOP | Forward: 50-90%      │
└────────────────────────────────────┘

┌─ SERVO1 (Pin 8) - RIGHT A/B BUTTONS ─┐
│              112°                      │
│        🔴 A        ⚪ B                │
│  A: Down to 40° | B: Up to 140°       │
└───────────────────────────────────────┘

┌─ SERVO2 (Pin 9) - RIGHT JOYSTICK X (STEERING) ─┐
│                90°                               │
│      🕹️ Joystick X: +0.123                      │
│  Left: 50° | Center: 90° | Right: 130°          │
└─────────────────────────────────────────────────┘
```

### On Jetson Terminal (WebSocket Server):
```
QUEST 3 → ARDUINO DUAL SERVO + MD22 MOTOR CONTROL
WebSocket: wss://192.168.100.10:8443
Arduino: /dev/ttyACM0 @ 115200 baud
LEFT Joystick Y → Motors (50-90%)
RIGHT Joystick X → Servo2/Steering (50-130°)
RIGHT A/B Buttons → Servo1 (40-140°)

┌──────────────────────────────────────────────────┐
│ STATUS: 🟢 CONNECTED                              │
│ Commands: 1234 | Rate: 20.1/s                    │
│ Arduino: ✅ Connected                             │
│ Motors:  70% | Updates: 89                       │
│ Servo1: 112° | Updates: 45                       │
│ Servo2:  90° | Updates: 89                       │
└──────────────────────────────────────────────────┘

┌─── LEFT CONTROLLER (MOTORS) ──────────────────────┐
│ MOTORS (MD22) - Joystick Y Control                │
│ 🕹️  Joystick Y: +0.567  →  Motors:  70%          │
│      REST ─────────────●────────────── FORWARD    │
│        0%               50%                90%    │
│      DEADZONE: ±10%  |  Range: 50-90%             │
└───────────────────────────────────────────────────┘

┌─── RIGHT CONTROLLER (SERVOS) ─────────────────────┐
│ SERVO2 (Pin 9) - Joystick X Control (STEERING)    │
│ 🕹️  Joystick X: +0.123  →  Servo2:  90°          │
│      LEFT ────────────●────────────── RIGHT       │
│       50°                90°              130°    │
│                                                    │
│ SERVO1 (Pin 8) - A/B Button Control: 112°         │
│ ⚪ A (Down/40°)  |  🔴 B (Up/140°)                 │
│      ──────────────────●─────────────────         │
│       40°                90°              140°    │
└───────────────────────────────────────────────────┘
```

---

## 🐛 Troubleshooting

### Quest shows "Connected: NO"

**Check 1: Did you accept certificate for port 8443?**
- Visit `https://192.168.100.10:8443` first
- Accept the certificate warning

**Check 2: Is WebSocket server running?**
- Check Terminal 1 on Jetson
- Should say "Waiting for Quest 3 connection..."

### Motors don't move

**Check 1: MD22 connected?**
- Check Arduino Serial Monitor for "MD22 Status: Connected"
- If not connected, check I2C wiring (SDA/SCL on pins 20/21)
- Verify DIP switches on MD22 are ALL ON

**Check 2: MD22 powered?**
- Check 12V external power supply to MD22
- Verify power LED on MD22 is lit

**Check 3: Test motors via Serial Monitor**
```
MOTORS:60
```
- Motors should start spinning at 60% speed
- If they don't, check motor connections to MD22

**Check 4: Joystick deadzone**
- Push joystick past 10% threshold
- Display should show motor speed changing

### Servos don't move

**Check 1: Test servos via Serial Monitor**
- Upload sketch again if needed
- Test with `SERVO1:90` and `SERVO2:90` commands

**Check 2: Servo powered?**
- Check 5V connection
- High-torque servos may need external power

### MD22 not detected

**Check 1: I2C connections**
- Verify SDA → Pin 20, SCL → Pin 21 on Arduino Mega
- Check for loose connections

**Check 2: DIP switches**
- All 4 DIP switches on MD22 must be ON
- This sets I2C address to 0x58

**Check 3: MD22 power**
- Check 5V logic power to MD22
- Check 12V motor power to MD22

### Motors run but don't stop when joystick released

**This indicates a software issue:**
- Restart Python WebSocket server
- Check that joystick Y returns to 0 when released
- Verify deadzone threshold (±10%)

---

## 🎓 Technical Details

### Motor Control Algorithm

**LEFT Joystick Y to Motor Speed Mapping:**
```python
# Deadzone: ±10%
if abs(joystick_y) < 0.10:
    return 0  # Stop motors

# Only positive Y (forward motion)
if joystick_y <= 0:
    return 0  # No backward

# Remove deadzone, map to 50-90%
adjusted_y = (joystick_y - 0.10) / 0.90  # 0.1..1.0 → 0..1
speed = 50 + adjusted_y * 40  # 0..1 → 50..90%
```

| Joystick Y | Motor Speed |
|------------|-------------|
| 0.00 (rest) | 0% (STOP) |
| 0.10 (deadzone edge) | 0% (STOP) |
| 0.11+ | 50% (minimum) |
| 0.55 (halfway) | 70% |
| 1.00 (full forward) | 90% (maximum) |

### MD22 Motor Speed Calculation

**Percentage to MD22 Value:**
```cpp
// Mode 0: 0=full reverse, 128=stop, 255=full forward
// Convert 0-100% to 128-255 range
md22_value = 128 + (percent * 127 / 100)
```

| Percent | MD22 Value |
|---------|------------|
| 0% | 128 (stop) |
| 50% | 192 |
| 70% | 217 |
| 90% | 242 |
| 100% | 255 |

### Joystick to Servo2 Mapping

```python
# RIGHT Joystick X: -1..1 → 50..130°
normalized = (joystick_x + 1.0) / 2.0  # -1..1 → 0..1
angle = 50 + normalized * 80           # 0..1 → 50..130
```

| Joystick X | Servo2 Angle |
|------------|--------------|
| -1.0 (left) | 50° |
| -0.5 | 70° |
| 0.0 (center) | 90° |
| +0.5 | 110° |
| +1.0 (right) | 130° |

### Communication Protocol

**Quest → Jetson (JSON over WebSocket):**
```json
{
  "timestamp": 1234567890,
  "controller0": {
    "joystick": {"x": 0.123, "y": 0.567}
  },
  "controller1": {
    "joystick": {"x": 0.487, "y": -0.123},
    "buttons": {
      "trigger": 0.0,
      "grip": 0.0,
      "a_x": true,
      "b_y": false
    }
  }
}
```

**Jetson → Arduino (Serial commands):**
```
SERVO1:112\n
SERVO2:90\n
MOTORS:70\n
STOP_ALL_MOTORS\n
```

**Arduino → Jetson (Serial response):**
```
OK: Servo1 set to 112 degrees\n
OK: Servo2 set to 90 degrees\n
Both Motors: 70% (MD22 value: 217, M1: 217, M2: 217)\n
All motors stopped\n
```

---

## 🔧 Advanced Configuration

### Changing Motor Speed Range

Edit `actuator_websocket_server.py`:
```python
# Line 42-43
MOTOR_MIN_PERCENT = 50  # Change minimum speed
MOTOR_MAX_PERCENT = 90  # Change maximum speed
```

And `arduino_actuator_controller.ino`:
```cpp
// Line 60-61
const int MOTOR_MIN_PERCENT = 50;
const int MOTOR_MAX_PERCENT = 90;
```

### Changing Deadzone

Edit `actuator_websocket_server.py`:
```python
# Line 44
MOTOR_DEADZONE = 0.10  # Change deadzone (0.10 = 10%)
```

### Changing MD22 Acceleration

Edit `arduino_actuator_controller.ino`:
```cpp
// Line 226 in initMD22()
writeMD22Register(MD22_ACCELERATION_REG, 10);  // Change value (1-10)
```
- Lower value = faster acceleration
- Higher value = smoother acceleration

### Enabling Reverse Motion

Edit `actuator_websocket_server.py`, function `joystick_y_to_motor_speed()`:
```python
# Remove line 173-174
# if joystick_y <= 0:
#     return 0

# Add reverse mapping for negative Y
# (Requires Arduino code changes to support negative speeds)
```

---

## 📞 Support

If issues persist:

1. ✅ Check all physical connections (I2C, servos, motors, power)
2. ✅ Verify MD22 DIP switches are ALL ON
3. ✅ Verify IP address is 192.168.100.10
4. ✅ Ensure both Jetson servers running
5. ✅ Test Arduino separately via Serial Monitor
6. ✅ Review Jetson terminal output for errors
7. ✅ Check MD22 12V power supply

---

## 🚨 Safety Notes

- **Always test motors with robot elevated** (wheels off ground)
- **Start with low speeds** (50-60%) before increasing
- **Emergency stop**: Release LEFT joystick immediately
- **Power off MD22** before making wiring changes
- **Check for overheating** during extended use
- **Monitor current draw** from 12V power supply

---

**🎉 Enjoy controlling your 4-wheel robot with VR!** 🤖🎮
