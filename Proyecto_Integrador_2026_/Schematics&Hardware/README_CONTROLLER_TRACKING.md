# Quest 3 Left Controller Tracking System

## Overview
This system tracks the **Quest 3 left controller** position and orientation in real-time during WebXR AR sessions. No markers, no camera detection needed - pure WebXR controller tracking!

## 📋 What You Get

### Real-time Data Display (In AR Session):
- **Position**: X, Y, Z coordinates in meters and centimeters
- **Rotation**: X, Y, Z Euler angles in degrees
- **Distance**: Total distance from origin
- **Heading**: Direction the controller is pointing
- **Top-down visualization**: Live 2D map showing controller movement

### Data Logging:
- CSV file with timestamped position/orientation data
- Console output with real-time tracking updates
- Data stored for post-processing

## 🚀 Quick Start Guide

### Step 1: Setup on Jetson Nano

```bash
# Navigate to your project directory
cd /path/to/your/project

# Generate SSL certificates (required for HTTPS)
openssl req -x509 -newkey rsa:2048 -keyout key.pem \
        -out cert.pem -days 365 -nodes \
        -subj '/CN=YOUR_JETSON_IP'

# Replace YOUR_JETSON_IP with actual IP (e.g., 192.168.100.10)
```

### Step 2: Start the Servers

**Terminal 1 - HTTPS Server (required):**
```bash
python3 https_server_controller.py
```

**Terminal 2 - Data Logger (optional, for CSV logging):**
```bash
python3 controller_logger.py
```

### Step 3: Access from Quest 3

1. **Put on Quest 3 headset**
2. **Open Browser** (Meta Quest Browser)
3. **Navigate to**: `https://YOUR_JETSON_IP:8000/controller_tracking.html`
   - Example: `https://192.168.100.10:8000/controller_tracking.html`
4. **Accept certificate warning** (click "Advanced" → "Proceed")
5. **Click "Enter AR" button**
6. **Move your LEFT controller** and watch the data update!

## 📊 What You'll See

### In the AR Session (Overlay Panel):

```
┌─────────────────────────────────────┐
│   🎮 LEFT CONTROLLER TRACKER        │
├─────────────────────────────────────┤
│ Status: ✓ TRACKING LEFT CONTROLLER  │
├─────────────────────────────────────┤
│ Position X:  +0.234m (23.4cm)       │
│ Position Y:  +1.120m (112.0cm)      │
│ Position Z:  -0.567m (-56.7cm)      │
├─────────────────────────────────────┤
│ Rotation X:  +12.5°                 │
│ Rotation Y:  -45.3°                 │
│ Rotation Z:  +8.1°                  │
├─────────────────────────────────────┤
│ Distance:    1.234m (123.4cm)       │
│ Heading:     -45.3°                 │
└─────────────────────────────────────┘
```

### In the 3D Scene:
- **Purple sphere**: Current controller position
- **Green cone**: Direction controller is pointing
- **Cyan trail**: Path the controller has traveled (last 100 points)

### Bottom-right Visualization:
- Top-down view (X-Z plane)
- Shows controller position relative to origin
- Green arrow indicates controller direction

### On Jetson Console (if logger running):

```
[14:32:15.234] Pos: X=+0.234 Y=+1.120 Z=-0.567 | Rot: X=+12.5° Y=-45.3° Z=+8.1° | Dist: 1.234m | Head: -45.3°
[14:32:15.334] Pos: X=+0.235 Y=+1.121 Z=-0.568 | Rot: X=+12.6° Y=-45.4° Z=+8.2° | Dist: 1.235m | Head: -45.4°
```

## 📁 Files Included

### Main Files:
- `controller_tracking.html` - WebXR AR application
- `https_server_controller.py` - HTTPS server
- `controller_logger.py` - WebSocket data logger

### Generated Files:
- `controller_tracking_YYYYMMDD_HHMMSS.csv` - Logged tracking data
- `cert.pem` / `key.pem` - SSL certificates

## 📝 CSV Log Format

```csv
timestamp,time_ms,pos_x_m,pos_y_m,pos_z_m,rot_x_deg,rot_y_deg,rot_z_deg,distance_m,heading_deg
2026-01-29T14:32:15.234,1738164735234,0.234,1.120,-0.567,12.5,-45.3,8.1,1.234,-45.3
2026-01-29T14:32:15.334,1738164735334,0.235,1.121,-0.568,12.6,-45.4,8.2,1.235,-45.4
```

## 🎯 Coordinate System

**WebXR Local Floor Reference:**
- **X axis**: Left (-) / Right (+)
- **Y axis**: Down (-) / Up (+)
- **Z axis**: Forward (-) / Backward (+)

**Origin (0, 0, 0)**: Where you started the AR session

**Heading**:
- 0° = Pointing forward (-Z direction)
- +90° = Pointing right (+X direction)
- -90° = Pointing left (-X direction)
- ±180° = Pointing backward (+Z direction)

## 🔧 Tracking Range & Limitations

### Controller Tracking Range:
- **Maximum effective distance**: ~2.5 meters from headset
- **Best accuracy**: Within 2 meters
- **Update rate**: 72-120 Hz (depends on headset refresh rate)

### Important Notes:
1. **Left controller must be visible to headset cameras** for best tracking
2. **Fast movements** may cause brief tracking drift
3. **Occlusion** (controller behind body) uses IMU estimation
4. Controller **must stay within ~2.5m** of headset

## 🔍 Troubleshooting

### "LEFT CONTROLLER NOT FOUND" message:
- Ensure controller is powered on
- Check controller batteries
- Wave the left controller in front of the headset
- Restart AR session

### No tracking data in console:
- Check WebSocket server is running (controller_logger.py)
- Verify WebSocket port 8765 is not blocked
- Check Jetson Nano IP address in HTML file (line 37)

### Certificate error won't go away:
- Regenerate certificate with correct IP address
- Try different browser (Wolvic or Firefox Reality)
- Add exception in browser security settings

### Tracking is choppy/laggy:
- Ensure good lighting conditions
- Keep controller visible to headset cameras
- Reduce number of trail points in code (line 243: change 100 to 50)

## 💡 Tips for Best Results

1. **Good Lighting**: Track in well-lit environments
2. **Smooth Movements**: Move controller slowly for better accuracy
3. **Stay in Range**: Keep within 2 meters of headset
4. **Front-Facing**: Keep controller in front of headset cameras when possible
5. **Calibrate**: Stand still at origin when starting AR session

## 🔄 Next Steps / Extensions

Want to track the moving object instead? Here are your options:

### Option A: Attach Controller to Object
- Physically attach the left controller to your moving object
- Use this tracking system as-is
- **Pros**: Works immediately, reliable
- **Cons**: Controller batteries, 2.5m range limit

### Option B: Switch to Unity + ArUco Markers
- Build Unity app with Passthrough Camera API
- Use ArUco markers on the object
- **Pros**: 5m range, better for floor tracking
- **Cons**: Need to develop Unity app

### Option C: Use External Sensors
- Add IMU sensor to object
- Send data via WebSocket
- Fuse with WebXR coordinates
- **Pros**: No range limit
- **Cons**: More hardware complexity

## 📞 Support

If you encounter issues:
1. Check all cables and connections
2. Verify IP addresses match
3. Restart servers in order (HTTPS first, then logger)
4. Restart Quest 3 browser
5. Check firewall settings on Jetson Nano

## 📄 License

MIT License - Free to use and modify

---

**Made for Quest 3 + Jetson Nano**  
**Last Updated**: January 2026
