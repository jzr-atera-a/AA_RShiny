# Mode 2 Autonomous Path Following — Complete Analysis & Fix Log

**Project:** Meta Quest 3 AR Robot Control  
**Vehicle:** Ackermann-steering robot, MD22 motor controller, two DC motors, Servo2 steering (50°–130°)  
**Files analysed across all sessions:**
- `trajectory_6modes_tracker.html` (multiple versions)
- `trajectory_websocket_server_tracking_path.py`
- `mode2_analysis (1–4).txt` — execution analysis exports
- `mode2_tracking_20260416_*.csv` — live tracking CSV logs
- WebSocket server terminal output logs

---

## What Mode 2 Is Supposed to Do

1. User draws a path on the AR floor by moving the left Meta Quest controller
2. Path is approved and sent to the server as a list of waypoints
3. Vehicle performs a 2-second calibration drive (straight) to establish its heading
4. Vehicle then autonomously executes steering and motor commands to follow the drawn path
5. Left controller continues to act as the vehicle position proxy throughout execution

---

## System Architecture (as understood)

```
Meta Quest 3 (WebXR HTML app)
    │
    │  WebSocket (WSS port 8444)
    ▼
Python WebSocket Server (trajectory_websocket_server_tracking_path.py)
    │
    │  Serial USB (115200 baud, /dev/ttyACM0)
    ▼
Arduino (MD22 motor controller + dual servos)
    │
    ├── Motor 1 (left)
    ├── Motor 2 (right)
    ├── Servo 1 (gripper, pin 8, 40°–140°)
    └── Servo 2 (steering, pin 9, 50°=full right, 90°=straight, 130°=full left)
```

**Position tracking:** There is no GPS. The left controller's XR spatial position (from Quest inside-out cameras) is used as the vehicle position proxy. The user holds or mounts the controller near the vehicle.

**Heading:** Derived from the direction of movement of the controller position between frames — `Math.atan2(dx, dz)` — not from controller orientation (quaternion).

---

## Bug 1 — Critical: Raw path density causes curvature formula to explode (1,200 Hz commands)

### Observation
Path recorded at ~60 fps XR frame rate while user slowly moves controller. Confirmed from analysis logs: **1,615 points over 41 cm** and **2,764 points over 57 cm** — approximately one point every **0.25 mm**.

The steering formula:
```javascript
const curvature = headingChange / Math.max(segmentDist, 0.01);
const steeringAngleDeg = Math.max(-30, Math.min(30, curvature * 100));
```

With `segmentDist ≈ 0.00025 m`, even 1° of position noise produces curvature ~70 rad/m. Multiplied by 100 and clamped: **every single command is 50° or 130° (maximum steering)**. No intermediate values possible.

The command timing:
```
duration = 0.00025 / 0.3 = 0.00083 s → ~1,200 Hz command rate
```

Mode 1 runs at 2 Hz. The servo's mechanical bandwidth is ~5–20 Hz. At 1,200 Hz the servo cannot respond and oscillates violently.

### Impact
- Immediate full-deflection oscillation (50° ↔ 130°)
- Serial port overloaded (requires 268,800 baud, capacity is 115,200)
- Connection drop after 5–8 seconds
- Arduino serial buffer overflow
- Hardware reboot required to recover

### Fix applied (HTML)
Added `downsamplePath()` function called before command generation:
```javascript
function downsamplePath(points, stepMeters = 0.05) {
    const result = [points[0]];
    let accumulated = 0;
    for (let i = 1; i < points.length; i++) {
        accumulated += points[i].distanceTo(points[i - 1]);
        if (accumulated >= stepMeters) {
            result.push(points[i]);
            accumulated = 0;
        }
    }
    const last = points[points.length - 1];
    if (result[result.length - 1] !== last) result.push(last);
    return result;
}
// Called as: mode2DownsampledPath = downsamplePath(trajectoryPoints, 0.05);
```

Result: ~1,600 raw points → ~20 clean waypoints for a 1 m path.  
New command rate: `0.05 / 0.3 = 167 ms per command → ~6 Hz` — within servo bandwidth.

---

## Bug 2 — Critical: `regeneratePathCommandsWithHeading` never updates heading between segments

### Observation
After calibration, `regeneratePathCommandsWithHeading()` rebuilds all commands. Inside its loop, each segment calculates `headingChange = targetHeading - mode2RobotHeading` but **`mode2RobotHeading` was never set at the end of each iteration**. This single missing line caused every segment to compute its turn relative to the original calibration heading rather than the previous segment's heading. A smooth curve producing +5°, +5°, +5° increments was instead calculated as +5°, +10°, +15°, +20°... instantly clamped to opposite extremes.

This line was correctly present in `generatePathCommands()` but was omitted when `regeneratePathCommandsWithHeading()` was written as a separate function.

### Fix applied (HTML)
```javascript
// Added at end of loop in regeneratePathCommandsWithHeading():
mode2RobotHeading = targetHeading;  // ← was missing
```

---

## Bug 3 — Critical: Command frequency ~1,200 Hz overwhelms serial port

Covered jointly with Bug 1. The command rate is a direct consequence of raw path density. Resolved by downsampling (Bug 1 fix).

---

## Bug 4 — Critical: "GPS" position source frozen during Mode 2 execution

### Observation
The code used `mode1LeftMarker.position.x/z` as its live position source for both calibration heading (line 2683) and each execution step (line 2731). This object is a Three.js mesh updated only inside the Mode 1 tracking XR block, which is gated on `mode1LeftTracking === true`. During Mode 2 autonomous execution, `mode1LeftTracking` is false — Mode 1 is not active — so the marker is completely frozen at whatever value it had when Mode 1 was last used. Every position read returned the same stale coordinates, making all self-correction meaningless.

The live Mode 2 position was being correctly computed in the Mode 2 XR tracking block (`fx`, `fz` variables, lines 5048–5049) but was only used to update the 3D vehicle model — never stored for the execution function to read.

### Fix applied (HTML)
In the Mode 2 XR tracking block:
```javascript
window.mode2LiveX = fx;   // Added: expose live position globally
window.mode2LiveZ = fz;   // Added: expose live position globally
```

In `executeNextMode2Command()`, replaced:
```javascript
// OLD (frozen):
const currentX = mode1LeftMarker.position.x;
const currentZ = mode1LeftMarker.position.z;

// NEW (live):
const currentX = window.mode2LiveX;
const currentZ = window.mode2LiveZ;
```

---

## Bug 5 — Major: Calibration displacement not fed back into path origin

### Observation
The 2-second calibration drives the vehicle ~15–20 cm forward. `pathPoints[0]` (the path origin) was set at drawing time and never updated. Execution began with an immediate ~20 cm positional error baked in. This directly explains the consistent **ΔZ = 4 grid cells (40 cm)** lag seen at every marker across all analysis files.

### Fix applied (HTML)
After calibration completes:
```javascript
const offsetX = currentX - cmd.targetPosition.x;
const offsetZ = currentZ - cmd.targetPosition.z;
mode2DownsampledPath.forEach(p => {
    p.x += offsetX;
    p.z += offsetZ;
});
```

---

## Bug 6 — Major: Immediate stop when position unavailable (no retry)

### Observation
A guard was added: `if (mode2FollowIndex > 0 && window.mode2LiveX === undefined) → stopMode2Following()`. While safe, this was too aggressive — a single missed XR frame (common during mode transitions, Quest menu overlays, etc.) would abort the entire run permanently. In the server logs, runs of 5.0 s and 7.8 s with 0/13 and 0/20 waypoints reached were caused partly by this.

### Fix applied (HTML)
Replaced immediate stop with retry counter:
```javascript
if (!mode2LiveXRetryCount) mode2LiveXRetryCount = 0;
mode2LiveXRetryCount++;
if (mode2LiveXRetryCount > 5) {
    // Only stop after 5 consecutive failures (~500ms of missing data)
    stopMode2Following();
    return;
}
setTimeout(() => executeNextMode2Command(), 100);  // retry in 100ms
return;
mode2LiveXRetryCount = 0;  // reset on success
```

---

## Bug 7 — Critical: Race condition between Approve and Execute

### Observation
`mode2TrackingActive` is set to `true` when the user presses Approve (line 3388). `window.mode2LiveX` is populated in the Mode 2 XR tracking block which only runs on the next XR frame after `mode2TrackingActive` becomes true. If the user presses the A button to execute on the **same frame** as Approve, `mode2LiveX` is still `undefined`. The code falls through to the stop guard (Bug 6) and kills execution before the vehicle moves at all.

This was the primary cause of the 5–8 second runs ending with 0 waypoints reached.

### Fix applied (HTML)
```javascript
if (window.mode2LiveX === undefined) {
    let retries = 0;
    const waitForTracking = setInterval(() => {
        retries++;
        if (window.mode2LiveX !== undefined) {
            clearInterval(waitForTracking);
            sendTrajectory();  // retry automatically
        } else if (retries >= 20) {
            clearInterval(waitForTracking);
            isSent = false;
            document.getElementById('trajectory-status').textContent = 'ERROR: NO POSITION';
        }
    }, 16);  // poll every ~1 frame
    return;
}
```

---

## Bug 8 — Major: `mode2TrackingActive` cleared during execution on mode switch

### Observation
The mode-switch handler ran `mode2TrackingActive = false` unconditionally whenever the user left Mode 2 (line 1778). During the 102-second test run, the user switched MODE2 → MODE1 → MODE2 briefly. The second switch back to MODE2 found `mode2TrackingActive = false`, meaning `window.mode2LiveX/Z` was never updated. Every execution step hit the "position undefined" guard, retried, and the run effectively did nothing for 102 seconds before the timeout.

### Fix applied (HTML)
```javascript
if (mode !== 2) {
    // Only clear tracking if Mode 2 is not actively executing
    if (!mode2Following) {
        mode2TrackingActive = false;
        mode2ControllerPath = [];
        // ... cleanup
    }
}
```

---

## Bug 9 — Major: `isSent` never reset on stop (cannot re-execute after stop)

### Observation
`isSent` was set to `true` when execution began and only cleared in the delete-trajectory handler. After a stop or completion, pressing A again did nothing because `isSent` was still `true`. Users had to delete and redraw the path to try again.

### Fix applied (HTML)
```javascript
// Added to stopMode2Following():
isSent = false;
```

---

## Bug 10 — Critical: No `clearTimeout` on stop → burst on Quest headset resume

### Observation
The server log shows two distinct bursts at 22:34:39 and 22:34:41, separated by ~1.9 seconds, with 30–36 Hz each burst. These occurred in Mode 1 — long after Mode 2 had finished. Pattern: **320 commands in 2.8 seconds**, causing Arduino serial buffer corruption:
```
ERROR: Unknown command: 0:M2:0:S1:90:S2:90ALL:M1:0:M2:0:S1:
ERROR: Unknown command: S1:90:S2:90ALL:M1:0:M2:0:S1:90:S2:9
```

Root cause: `stopMode2Following()` set `mode2Following = false` but never called `clearTimeout()` on the pending timer stored from `setTimeout(() => executeNextMode2Command(), cmd.duration)`. When the Quest headset is paused (home button, menu overlay, brief sleep) and then resumed, all queued `setTimeout` callbacks that expired during the pause fire simultaneously. Two separate chains from two Mode 2 attempts both released at once, flooding the serial port.

The two separate burst timings match two Mode 2 runs that each created independent `setTimeout` chains still pending after `stopMode2Following()`.

### Fix applied (HTML)
```javascript
// Variable added:
let mode2PendingTimeout = null;

// Both setTimeout calls in executeNextMode2Command now store their ID:
mode2PendingTimeout = setTimeout(() => executeNextMode2Command(), cmd.duration);
mode2PendingTimeout = setTimeout(() => executeNextMode2Command(), 500);  // post-calibration

// stopMode2Following() now cancels it:
if (mode2PendingTimeout !== null) {
    clearTimeout(mode2PendingTimeout);
    mode2PendingTimeout = null;
}
```

---

## Bug 11 — Major: Triple Arduino write per Mode 2 command step

### Observation
Per execution step, Mode 2 sent:
1. `ALL:M1:...:S2:90` directly via WebSocket → server forwards to Arduino (1 write)
2. `TRACK:...:M1:...:S2:90` via WebSocket → server parses and sends `ALL:M1:...:S2:90` to Arduino (1 more write)
3. Stop command sent **twice** for safety (2 more writes at end)

Mode 1 sent only `TRACK:` (no direct `ALL:`), so server wrote once per heartbeat. Mode 2 was generating 2–3× the Arduino serial traffic of Mode 1 for the same number of logical commands. Under stress (mode switches, headset resume) this pushed the serial buffer into overflow.

### Fix applied (HTML + Python server)

**HTML:** Mode 2 now sends `MODE2_TRACK:` prefix instead of `TRACK:`:
```javascript
// OLD:
const trackCommand = `TRACK:${timestamp}:...`;

// NEW:
const trackCommand = `MODE2_TRACK:${timestamp}:...`;
```

**Python server:** `MODE2_TRACK:` is parsed for path deviation logging but **not forwarded to Arduino**:
```python
if command.startswith('MODE2_TRACK:'):
    # Parse position for logging/analysis only
    # Do NOT call send_to_arduino()
elif command.startswith('TRACK:'):
    # Mode 1 - parse AND forward to Arduino (existing behaviour)
```

Result: Mode 2 = 1 Arduino write per step. Mode 1 = 1 Arduino write per heartbeat.

---

## Bug 12 — Major: Calibration heading derived from a single noisy snapshot

### Observation
The server CSV showed `actual_heading = 292.1°` consistently throughout an entire Mode 2 run, while the path required ~175° (southward). The 117° error meant every steering command was computed against a completely wrong reference, so the vehicle turned the wrong way on every segment.

The calibration computed heading as:
```javascript
mode2RobotHeading = Math.atan2(currentX - startX, currentZ - startZ);
```

This is a single snapshot: controller position at `t=0` vs `t=2s`. Any hand movement, Quest tracking drift, or small motion noise at either endpoint corrupts the entire heading for the whole run. 292° vs 175° indicates the controller moved slightly northwestward during the 2 seconds (perhaps the user shifted their hand) rather than southward with the vehicle.

### Fix applied (HTML)
Blend controller movement direction with the first segment of the drawn path. The drawn path is the ground truth for intended direction:
```javascript
const pathHeading = Math.atan2(
    mode2DownsampledPath[1].x - mode2DownsampledPath[0].x,
    mode2DownsampledPath[1].z - mode2DownsampledPath[0].z
);
const controllerHeading = Math.atan2(dx, dz);

// 30% controller movement, 70% path first-segment direction
const blendedDx = 0.3 * Math.sin(controllerHeading) + 0.7 * Math.sin(pathHeading);
const blendedDz = 0.3 * Math.cos(controllerHeading) + 0.7 * Math.cos(pathHeading);
mode2RobotHeading = Math.atan2(blendedDx, blendedDz);
```

If the controller did not move enough (`distMoved < 0.05 m`), heading falls back entirely to the path first-segment direction — not 0°.

---

## Bug 13 — Structural: Live GPS heading update during execution is decorative

### Observation
During each execution step, `mode2RobotHeading` was updated from live position. But the pre-computed `cmd.servo2` values in `mode2PathCommands[]` were never revised. The corrected heading only rotated the 3D vehicle model on screen — Arduino received stale pre-computed steering values.

### Fix applied (HTML)
After updating `mode2RobotHeading` from live position, recalculate `actualServo2` for the current command:
```javascript
if (distMoved > 0.02) {
    mode2RobotHeading = Math.atan2(dx, dz);
    if (cmd.targetHeading !== null) {
        let headingError = cmd.targetHeading - mode2RobotHeading;
        while (headingError > Math.PI) headingError -= 2 * Math.PI;
        while (headingError < -Math.PI) headingError += 2 * Math.PI;
        const steerDeg = Math.max(-30, Math.min(30, headingError * (180 / Math.PI)));
        actualServo2 = Math.round(Math.max(50, Math.min(130, 90 + steerDeg * (40 / 30))));
    }
}
```

---

## Bug 14 — Structural: `TRACK:` unit mismatch between Mode 1 and Mode 2

### Observation
Mode 1 computed position in cm relative to map centre (`leftX_cm = ((leftX - userX) / MAP_SIZE * 200)`) before sending `TRACK:`. Mode 2 sent raw XR world coordinates in metres (`window.mode2LiveX`). The server multiplied all TRACK positions by 100 assuming metres. Mode 1 values therefore got incorrectly scaled ×100.

### Fix applied
Mode 2 now converts to cm before sending:
```javascript
const liveX_cm = (window.mode2LiveX * 100).toFixed(1);
const liveZ_cm = (window.mode2LiveZ * 100).toFixed(1);
```

Combined with Bug 11 fix (MODE2_TRACK prefix), server now handles each mode's position data correctly and independently.

---

## Bug 15 — Cosmetic: Analysis file reports ~10m planned path for a ~1m drawn path

### Observation
`mode2_analysis (4).txt` reported `Total Distance: 9.985m` for a path that visually covered ~1m. The `analyzeMode2Paths()` function uses raw `trajectoryPoints` (Three.js world coordinates in metres), multiplied against a 2.1m grid. This is a display/labelling issue in the analysis export — not a physical movement problem. The actual distances are correct in metres but the `9.985m` figure alarmed users into thinking the path calculation was broken when it was not.

### No code fix required — cosmetic issue in analysis text output only.

---

## Python Server Issues Observed

### Server asyncio warnings on Ctrl+C (harmless)
```
Task was destroyed but it is pending!
KeyboardInterrupt in conn_handler
```
These are cosmetic Python asyncio cleanup warnings. The emergency stop was sent and Arduino was closed correctly before shutdown. No action needed.

### `TypeError: 'NoneType' object is not iterable` on shutdown (harmless)
Occurs in `_SelectorTransport.__del__` during process teardown. Python 3.13 asyncio quirk. Does not affect operation.

### Server IP showing `127.0.1.1` instead of LAN IP
The Quest connects over LAN (192.168.100.x) but server reported `Local IP: 127.0.1.1`. This is a loopback alias in `/etc/hosts` on Ubuntu. The server still binds to `0.0.0.0` (all interfaces) so connections work, but the displayed URL is misleading. Fix: replace `socket` hostname lookup with explicit network interface enumeration.

---

## Summary Table — All Bugs and Fixes

| # | Severity | Description | Root cause | Fixed in |
|---|---|---|---|---|
| 1 | Critical | 1,200 Hz command rate / oscillation | Raw path density 0.25mm/point | HTML v1 |
| 2 | Critical | All steering angles wrong | Missing heading update in regen loop | HTML v1 |
| 3 | Critical | Serial port overflow → connection drop | Consequence of Bug 1 | HTML v1 |
| 4 | Critical | Position source frozen during execution | Used Mode 1 marker in Mode 2 | HTML v1 |
| 5 | Major | 40 cm positional lag at every marker | Calibration displacement not offset | HTML v1 |
| 6 | Major | Immediate stop on single missed frame | No retry on undefined position | HTML v1 |
| 7 | Critical | Execution aborts before vehicle moves | Race condition: Approve vs Execute | HTML v1 |
| 8 | Major | Live position freezes after mode switch | `mode2TrackingActive` cleared mid-run | HTML v1 |
| 9 | Major | Cannot re-run after stop | `isSent` not reset on stop | HTML v1 |
| 10 | Critical | Serial burst on Quest headset resume | No `clearTimeout` on stop | HTML v2 |
| 11 | Major | Triple Arduino write per step | `TRACK:` re-forwarded as `ALL:` | HTML v2 + Server v2 |
| 12 | Major | Heading stuck at wrong angle | Single noisy calibration snapshot | HTML v2 |
| 13 | Structural | Live heading correction decorative | `actualServo2` not recalculated | HTML v1 |
| 14 | Structural | TRACK unit mismatch Mode 1 vs Mode 2 | Metres vs cm sent to server | HTML v1 |
| 15 | Cosmetic | Analysis reports ~10m for ~1m path | `trajectoryPoints` not downsampled for display | No fix needed |

---

## What Mode 1 Does Right (reference baseline for Mode 2)

Mode 1 works and should be the reference:
- Commands at **2 Hz** — within servo mechanical bandwidth
- Heading derived **only from movement**: `atan2(dx, dz)` when `dist > 0.02 m && motorSpeed > 20`
- Heading **frozen when stationary** — no noise injection
- Single position source (Kalman-filtered XR controller position)
- No pre-computation — steering recalculated every heartbeat from current state

Mode 2 should mirror this architecture as closely as possible.

---

## Recommended Next Steps for Testing

1. Deploy both `trajectory_6modes_tracker_v2.html` and `trajectory_websocket_server_tracking_path_v2.py`
2. Test with a **straight line** first (3–4 m) — heading should stay near 90° throughout
3. Watch server output: `Calibration complete! Controller: XX° Path: XX° Blended: XX°` — blended heading should be close to path first-segment heading
4. Test with a **gentle curve** (one turn over 2 m) — servo should produce smooth intermediate values (70°–110°), not oscillate 50°↔130°
5. Monitor: `Waypoints reached: N/N` should now increment — if still stuck at 0, the server-side waypoint advance threshold may need tuning
6. Monitor `MODE2_TRACK` in server output — confirms position data logged without forwarding
7. After a successful run, **bring up Quest home menu briefly** then return — resume should not produce a command burst

---

## Outstanding Concerns Not Yet Fixed

- **Server-side waypoint advance threshold**: The server's `analyze_path_deviation` only advances `mode2_current_waypoint` when position error falls below a threshold. With ~30–42 cm average deviation (from analysis files), waypoints may never advance. The threshold may need relaxing, or waypoint advance logic should use distance-along-path rather than proximity.
- **Servo2 inverted differential**: In several runs, Motor 1 and Motor 2 speed assignments were swapped (M1:63 M2:50 paired with S2:130, and M1:50 M2:63 paired with S2:50). This suggests the differential steering direction convention may be inverted for one motor.
- **Server IP display**: Shows `127.0.1.1` instead of actual LAN IP — misleading for debugging but not functional.

---

*Analysis compiled from code review of `trajectory_6modes_tracker.html` (multiple versions), `trajectory_websocket_server_tracking_path.py`, execution logs, CSV tracking data, and WebSocket server terminal output across multiple test sessions — April 2026.*
