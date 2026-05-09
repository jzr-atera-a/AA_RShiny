# Meta Quest 3 AR Robot Control — Project Report
**Status: ✅ COMPLETE**  
**Final Successful Run:** Mode 5 · Spline · 45 cm turning radius · 110% map scale · 28/28 waypoints · 800 commands · 0 errors

---

## 1. System Architecture

```
Meta Quest 3 (WebXR HTML)
        │  WSS :8444
        ▼
Python WebSocket Server  ──────────────►  Arduino Mega (USB /dev/ttyACM0)
trajectory_websocket_server_m2.py              arduino_actuator_controller_expanded_ranges.ino
        │                                          │
        │                               MD22 (I2C 0x58) ──► M1 LEFT motor
        │                               MD22           ──► M2 RIGHT motor
        │                               Servo Pin 8   ──► Gripper (S1)
        │                               Servo Pin 9   ──► Steering (S2)
        ▼
HTTPS File Server (https_server.py :8443)
```

### Network
| Service | Protocol | Port | Notes |
|---------|----------|------|-------|
| HTTPS file server | TLS | 8443 | Serves HTML, GeoJSON |
| WebSocket server | WSS | 8444 | Bidirectional command/telemetry |
| Quest 3 | WiFi | — | 192.168.100.12 |
| Server | LAN | — | 192.168.100.10 |

---

## 2. Hardware Configuration

### Vehicle
| Parameter | Value |
|-----------|-------|
| Wheelbase | 34 cm |
| Track width | 29 cm |
| Left controller mount | Top centre of vehicle |
| Minimum physical turning diameter | ~1.5 m |

### Arduino Actuator Ranges
| Actuator | Range | Centre | Notes |
|----------|-------|--------|-------|
| M1 (LEFT motor) | 0 or 40–100% | 0 = stop | Mode 5: 50–100% |
| M2 (RIGHT motor) | 0 or 40–100% | 0 = stop | Mode 5: 50–100% |
| S1 Servo — Gripper (Pin 8) | 40°–140° | 90° | All modes |
| S2 Servo — Steering (Pin 9) | 40°–140° | 90° = straight | **Mode 5 only: full range** |
| S2 Servo — Steering | 50°–130° | 90° | Modes 1, 2, 3 (restricted) |

> **Critical:** Motors reject any speed in 1–39% range with `ERR:RANGE`. Always send 0 (stop) or ≥40 (50 recommended minimum for adequate torque). Mode 5 uses 50–100% for sharp turns.

### Steering Convention
```
S2 = 90 − steeringAngleDeg × (50/30)   [Mode 5, ±30° → 40–140°]
S2 = 90 − steeringAngleDeg × (40/30)   [Modes 1/2, ±30° → 50–130°]

S2 = 40  → Full RIGHT turn (M1 inner, M2 outer)
S2 = 90  → Straight
S2 = 140 → Full LEFT turn  (M2 inner, M1 outer)
```

**M1 is the LEFT motor (confirmed by behaviour):**
- Right turn: M1 = inner (slower), M2 = outer (faster), S2 < 90
- Left turn:  M2 = inner (slower), M1 = outer (faster), S2 > 90

---

## 3. Software Stack

### Client — trajectory_6modes_tracker0.html
| Component | Version/Detail |
|-----------|---------------|
| Three.js | 0.170.0 (CDN) |
| WebXR | `hit-test`, `local-floor` required; `dom-overlay`, `anchors` optional |
| AR Button | `ARButton` from three/addons |
| GLTF Loader | For robot/truck 3D models |
| Kalman filters | X: (q=0.01, r=0.1), Z: (q=0.01, r=0.1), H: (q=0.01, r=0.5) |
| Control rate | 2 Hz (500 ms intervals) for all autonomous modes |
| Safety timeout | Mode 2: 2 minutes maximum run time |

### Server — trajectory_websocket_server_m2.py
- Python 3.13, `websockets` library, SSL/TLS
- Parses `MODE2_TRACK`, `MODE2_PATH`, `MODE2_STOP`, `MODE5_TRACK`, `MODE5_PATH`, `MODE5_STOP`
- Forwards `ALL:M1:x:M2:y:S1:z:S2:w` commands to Arduino via serial
- Statistics every 50 commands

### HTTPS Server — https_server.py
- Python `http.server` with SSL wrap
- Port 8443, serves all static files including GeoJSON
- Required CORS headers: `Cross-Origin-Opener-Policy: same-origin`

---

## 4. Operating Modes

| Mode | Name | Purpose | Key Input |
|------|------|---------|-----------|
| 0 | Map View | London M25 overview | — |
| 1 | Manual Control | Direct joystick drive | Right joystick + steering |
| 2 | User Trajectory | Draw → Smooth → Follow | Left controller draws, A = start |
| 3 | M25 Highway | M25 simulation | — |
| 4 | Controller Track | Kalman-filtered position tracking | Left controller |
| 5 | M25 Smooth Tracking | Autonomous M25 lap | Approve → Smooth → A = start |
| 6 | EV Charger Status | Charger locations | — |
| 7 | Truck Positions | Fleet positions | — |

---

## 5. Mode 2 — User Trajectory

### Workflow
1. Draw red path with left controller (recorded as `trajectoryPoints`)
2. Select smoothing method: **ARC** or **SPLINE**
3. Adjust turning radius slider (5–75 cm)
4. **APPROVE** path
5. **SMOOTH PATH** → green Dubins/spline path + 20 cm waypoints
6. Press **Button A** → vehicle follows waypoints at 2 Hz

### Path Smoothing Algorithms

**ARC (Bezier corner-cut):**
- Pre-resamples input to ≥ 2.5R spacing (prevents corner overlap)
- `T = R·tan(θ/2)` clamped to 45% of segment length
- Quadratic Bezier arc at each corner
- **No loops guaranteed** by correct `segEnd[i] = pts[i+1]` initialisation

**SPLINE (Catmull-Rom):**
- Pre-thins waypoints to ≥ 2R spacing
- Natural CR curvature stays above R without post-filtering
- Smoother visual appearance, same execution path

### Control Loop (Mode 2)
```
headingError = targetHeading - robotHeading
steeringAngleDeg = headingError × (180/π) + crossTrackComponent
S2 = 90 − steeringAngleDeg × (40/30),  clamped 50–130
```
- Differential: inner wheel = `baseSpeed × differentialMode`, min 50
- If inner < 50: inner = 50, outer = min(80, 50/differential)
- Motor range: 50–80% (modes 1/2)

---

## 6. Mode 5 — M25 Smooth Tracking

### Workflow
1. Enter Mode 5 → red M25 ring loaded from GeoJSON
2. **(Optional)** Adjust map scale slider 100–150%, press **APPROVE SCALE**
3. Select ARC or SPLINE smoothing method
4. Adjust turning radius slider (5–75 cm)
5. **APPROVE PATH**
6. **SMOOTH PATH** → green path + 20 cm execution waypoints
7. Place vehicle at magenta cone (within 20 cm tolerance)
8. Press **Button A** (right controller) → autonomous lap begins
9. **Thumbstick** (right controller) → emergency stop at any time

### Successful Run Parameters (Final)
| Parameter | Value |
|-----------|-------|
| Map scale | 110% |
| Smoothing method | Spline |
| Turning radius | 45 cm |
| Waypoints | 28 @ 20 cm spacing |
| Commands sent | 820 (800 motion + 20 stop) |
| Arduino errors | 0 |
| Completion | 28/28 waypoints |
| Duration | ~2 minutes |
| Path deviation | Typically 0–7 cm |

### Mode 5 Extended Ranges (Only)
| Parameter | Value |
|-----------|-------|
| S2 servo | 40°–140° (±50° from centre) |
| Motors | 50–100% |
| Typical sharp turn | M1:100 M2:50 S2:40 or M1:50 M2:100 S2:140 |
| Straight | M1:85 M2:85 S2:90 |

### Control Loop (Mode 5)
```
steeringAngleDeg = headingError × (180/π) + crossTrackComponent
S2 = 90 − steeringAngleDeg × (50/30),  clamped 40–140

CrossTrack: Stanley formula atan(k×e/v), k=2.0, v=0.5 m/s, capped ±15°
Proximity stop: only after 80% of waypoints (ring path start==end guard)
Abort: if distance to waypoint > 80 cm
```

---

## 7. Map & Coordinate System

### M25 GeoJSON → AR Space
```
canvas_x = (lon − lonCentre + lonRange/2) / lonRange × 4096
canvas_y = 2048 − (lat − latCentre + latRange/2) / latRange × 2048

x_3d = (canvas_x/4096 − 0.5) × 4.2 × S   [S = map scale, default 1.0]
z_3d = (canvas_y/2048 − 0.5) × 2.1 × S + (S−1)×1.05

lonCentre = 0.000045, latCentre = 0.000125
lonRange  = latRange  = 0.0037
```

**Top edge of map** always aligned with panel plane bottom (`userZ − MAP_SIZE/2`).  
Scaling expands sideways and downward only.

### Grid
- Base MAP_SIZE = 2.1 m
- Full map: 4.2 m × 2.1 m (unscaled)
- Grid squares: 10 cm × 10 cm
- At 110% scale: 4.62 m × 2.31 m

---

## 8. Controller Mapping (Meta Quest 3)

### Right Controller (mode-dependent autonomous control)
| Input | Function |
|-------|---------|
| Trigger | Panel ray-cast interaction |
| A button | Start path following (Mode 2 & 5) |
| B button | Gripper close (Mode 1) |
| Right joystick X | Steering (Mode 1) |
| Right joystick Y | Forward/reverse (Mode 1) |
| Thumbstick press | Emergency stop (Mode 2 & 5) / Delete last point (Mode 2) |

### Left Controller (position tracking)
| Input | Function |
|-------|---------|
| Position (Kalman filtered) | Vehicle/robot position in AR space |
| Grip | Clear path (Mode 1) |
| Trigger | Draw trajectory (Mode 2) |
| X button | Mode 6 camera reset |

---

## 9. WebSocket Command Protocol

### Arduino Commands
```
ALL:M1:{0|40-100}:M2:{0|40-100}:S1:{40-140}:S2:{40-140}   # Differential (recommended)
ALL:M{0|40-100}:S1:{40-140}:S2:{40-140}                     # Same speed (legacy)
MODE2_PATH:{json}    # Upload path (Quest → Server)
MODE2_TRACK:{...}    # Tracking telemetry (Quest → Server → Arduino)
MODE2_STOP           # Stop signal
MODE5_PATH:{json}    # Same as MODE2 equivalents
MODE5_TRACK:{...}
MODE5_STOP
```

### Arduino Responses
```
OK:M1:{v}:M2:{v}:S1:{v}:S2:{v}   # Confirmed execution
ERR:RANGE:{command}                # Value out of range (< 40 or > 100 for motors)
```

---

## 10. Known Limitations & Considerations

### Tracking Accuracy
- Position tracking relies on Quest 3 left controller Kalman-filtered pose
- Occasional Quest tracking loss causes position jumps (visible in WS log as sudden coordinate change)
- No wheel odometry — dead reckoning not implemented
- Path deviation typically 0–7 cm; spikes during tracking loss

### Path Smoothing
- ARC method: guaranteed loop-free; corners approximate, not exact Dubins
- SPLINE method: visually smoother; effective radius ≈ selected × 0.8 for tight corners
- Both methods require re-smoothing after map scale change
- Minimum practical turning radius: ~40 cm at 110% scale

### Mode 5 Stopping
- M25 is a ring (start == end coordinates). The 80% progress guard prevents premature stop at launch.
- Final waypoint proximity threshold: 20 cm

### Motor Behaviour
- Below 40%: motors stall, Arduino returns `ERR:RANGE`
- Below 50%: torque adequate for steering but weak on slopes
- Mode 5 uses 50–100%; all other modes capped at 50–80%

### AR Session
- `debugLog` network fetch removed — was causing ~100 HTTP requests at init, delaying AR button by ~10 s
- `requiredFeatures: ['hit-test', 'local-floor']` — Quest must detect floor before scene builds
- Floor detection drives all panel and map placement

---

## 11. File Reference

| File | Purpose |
|------|---------|
| `trajectory_6modes_tracker0.html` | Complete AR client — all 7 modes |
| `trajectory_websocket_server_m2.py` | Python WSS server, Arduino bridge |
| `arduino_actuator_controller_expanded_ranges.ino` | Arduino firmware — extended ranges |
| `https_server.py` | TLS file server for Quest browser |
| `cert.pem` / `key.pem` | Self-signed SSL (generate with openssl) |
| `sample_campus_map.geojson` | M25 ring + London map data |

---

## 12. Startup Sequence

```bash
# Terminal 1 — WebSocket server
cd /path/to/project
python3.13 trajectory_websocket_server_m2.py

# Terminal 2 — HTTPS file server
python3.13 https_server.py --ip 192.168.100.10

# Quest 3
# Browser → https://192.168.100.10:8443/trajectory_6modes_tracker.html
# Accept certificate → Grant permissions → START AR
```

---

## 13. Extension Recommendations

### Near-term
1. **Wheel odometry** — add encoder feedback via Arduino `ODOM:left:right` messages to reduce tracking loss impact
2. **Speed control in Mode 2** — currently fixed base speed; modulate by path curvature (already partially implemented via `curvature × 200` term)
3. **Mode 5 loop repeat** — after lap complete, automatically restart rather than stopping
4. **Cross-track sign fix** — validate Stanley cross-track direction sign against real vehicle behaviour; consider switching to pure heading-only if oscillation observed

### Medium-term
5. **Real GeoJSON path** — replace simulated M25 with actual GPS-surveyed campus route
6. **Multiple laps counter** — track how many times vehicle completes the ring
7. **Battery/IMU telemetry** — read Arduino analog inputs for battery voltage, surface tilt
8. **Obstacle detection** — ultrasonic sensors → `OBSTACLE:{dist}` message → auto-stop

### Long-term
9. **GPS integration** — replace Quest controller tracking with RTK GPS for outdoor use
10. **Multi-vehicle** — WebSocket server can support multiple connections; coordinate ID in commands
11. **Recorded path replay** — save Mode 2 path to JSON, reload and re-execute without AR session

---

*Report generated from WS output, source HTML, Arduino firmware, and server code — April 2026*

---

## 14. Test Results

### Test 1 — Successful Lap Completion
| Metric | Value |
|--------|-------|
| Date | April 2026 |
| Map scale | 110% |
| Smoothing | Spline |
| Turning radius | 45 cm |
| Waypoints | 28/28 completed ✅ |
| Commands sent | 820 |
| Arduino errors | 0 |
| Path deviation | 0–7 cm typical |
| Stop reason | Autonomous lap complete |

---

### Test 2 — Second Successful Run (Partial + Manual Stop)
| Metric | Value |
|--------|-------|
| Date | April 2026 (same session, command #830 onward) |
| Map scale | 110% |
| Smoothing | Spline |
| Turning radius | 45 cm |
| Waypoints reached | WP 3 → WP 23/28 before manual stop |
| Commands sent | 456 (total session #830–#1286) |
| Arduino errors | **0** |
| Server uptime | 2396 s (~40 min continuous) |
| Stop reason | Manual (Ctrl+C) |

#### Test 2 — Observations

**Tracking quality:** Deviation consistently 0–5 cm through WP 3–22. Excellent path following through the full outer ring arc and descent sections.

**WP 23 drift event (18:23:17–18:23:35):** Vehicle deviated progressively to ~18 cm as it approached a tight outer corner. The cross-track Stanley controller responded correctly — S2 graduated from 40° toward 90° (reducing right-turn authority) then began correcting back. By 18:23:35 deviation had reduced from 18.3 cm to 0.3 cm showing the correction was working. Stop was manual before the vehicle could return to path.

**Sharp turn commands confirmed working:**
- Right turns: `ALL:M1:100:M2:50:S1:90:S2:40` (outer left at 100%, inner right at 50%, full right steer)
- Left turns: `ALL:M1:50:M2:100:S1:90:S2:140` (outer right at 100%, inner left at 50%, full left steer)

**Motor/servo response verified:** Arduino confirmations matched commands throughout. No `ERR:RANGE` at any point. Extended ranges (40–140° servo, 50–100% motor) fully validated over 1286 total commands across both runs.

**Combined two-run summary:**
| | Run 1 | Run 2 |
|-|-------|-------|
| Commands | 820 | 456 |
| Errors | 0 | 0 |
| Max deviation | ~7 cm | ~18 cm (corner, self-correcting) |
| Completion | Full lap | Manual stop at WP 23/28 |
| Conclusion | ✅ Full autonomous lap | ✅ Stable tracking confirmed |

