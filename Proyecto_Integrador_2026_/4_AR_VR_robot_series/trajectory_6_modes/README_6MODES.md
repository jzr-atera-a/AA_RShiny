# Quest 3 AR Robot Control - 6 Modes

## Quick Start

### Testing Mode 0 Only (No Websocket Needed)
1. Put these files in same folder:
   - `trajectory_6modes.html`
   - `sample_campus_map.geojson`
   - `cert.pem` and `key.pem` (HTTPS certificates)

2. Run HTTPS server:
   ```bash
   python https_server.py
   ```

3. On Quest 3 browser, visit:
   ```
   https://YOUR_IP:8443/trajectory_6modes.html
   ```

4. You'll see Mode 0 active by default (London map + robot)

### Testing All Modes (With Websocket)
1. In addition to above files, also need:
   - `trajectory_websocket_server.py`

2. Start websocket server (in separate terminal):
   ```bash
   python trajectory_websocket_server.py
   ```

3. Update websocket IP in `trajectory_6modes.html` (line 47-48):
   ```javascript
   const WS_IP = '192.168.100.10';  // Change to your PC IP
   const WS_PORT = '8443';
   ```

4. Follow steps 2-3 from above

## Modes Overview

**Mode 0 - R Vehicle Map View** (Default)
- London M25 heatmap always visible
- Procedural robot visible only in this mode
- No websocket required
- Robot centered over London, arm facing south

**Mode 1 - Manual Control**
- Joystick control (requires websocket)

**Mode 2 - User Trajectory**
- Draw path with trigger (requires websocket)

**Mode 3 - M25 Auto**
- Auto-drive from Sevenoaks (requires websocket)

**Mode 4 - Controller Tracking**
- Left controller tracking with Kalman filter
- **Requires websocket** - sends position/orientation data
- Server displays: X, Z, Heading, Distance in real-time

**Mode 5 - Spatial Anchor**
- Place anchor with spatial tracking (requires websocket)

## Websocket Server Features

When running `trajectory_websocket_server.py`:

### Mode 4 Output Example:
```
[MODE 4 TRACKING] X:   12.5cm  Z:  -45.3cm  Heading:  135.2°  Dist:   47.2cm
[MODE 4 TRACKING] X:   13.1cm  Z:  -46.0cm  Heading:  136.5°  Dist:   48.1cm
```

### Mode Selection Output:
```
================================================================================
  MODE 4 ACTIVATED: Track Robot (Controller)
================================================================================
```

### Trajectory Execution Output:
```
====================================================================================================
  EXECUTING TRAJECTORY ON ROBOT (5 Hz)
====================================================================================================
    Time  DistOrg  DistEnd   SERVO2  MOTOR1  MOTOR2
----------------------------------------------------------------------------------------------------
   0.000    0.000    2.450       90      50      50
   0.200    0.024    2.426       95      52      52
```

## Arduino Connection (Optional)

If Arduino is connected on `/dev/ttyACM0`:
- Trajectory commands will be sent to motors/servo
- If not connected, server still works but displays warning

## Troubleshooting

**"WebSocket connection failed"**
- Check WS_IP in HTML matches your PC IP
- Make sure websocket server is running
- Mode 0 doesn't need websocket - ignore this for Mode 0

**"GeoJSON load failed"**
- Ensure `sample_campus_map.geojson` is in same folder as HTML

**Robot not visible**
- Make sure you're in Mode 0
- Robot only shows in Mode 0, hidden in other modes
- London map is always visible in all modes

**Panel too small/large**
- Panel is 1.5m × 1.0m, positioned north of map
- Should fit all 6 modes in single view

## File Requirements

### Minimum (Mode 0 only):
- trajectory_6modes.html
- sample_campus_map.geojson  
- https_server.py
- cert.pem, key.pem

### Full System (All modes):
- All above files PLUS
- trajectory_websocket_server.py
