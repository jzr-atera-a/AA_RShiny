# Mode 2 Autonomous Path Following — Unified Issue Analysis

**Project:** Meta Quest 3 AR Robot Control  
**Vehicle:** Ackermann-steering robot with MD22 dual DC motor controller and two servos  
**Stack:** WebXR HTML app (Meta Quest 3) → Python WebSocket server → Arduino via USB serial → MD22 + servos  
**Analysis period:** April 2026, multiple test sessions  

---

## System Overview

The robot is controlled from an AR application running in the Meta Quest 3 browser. The left controller acts as the vehicle position proxy — its XR spatial tracking position (from the headset's inside-out cameras) stands in for GPS. There is no actual GPS. Heading is derived purely from the direction of controller movement between frames using `atan2(dx, dz)`.

Mode 1 (manual joystick control) worked acceptably throughout. Mode 2 (autonomous path following, where the user draws a route on the AR floor and the vehicle executes it) failed completely across every test session until these fixes were applied.

**Key hardware constraints:**
- Serial baud rate: 115,200 baud
- Arduino serial receive buffer: 64 bytes
- OS UART kernel buffer: ~4,096 bytes
- Servo 2 mechanical bandwidth: ~5–20 Hz
- Servo 2 range: 50° (full right) to 90° (straight) to 130° (full left)
- Motor speed range: 0–80%

---

## Issue 1 — Raw path density causes 1,200 Hz command rate and full-deflection oscillation

**Severity:** Critical  
**Affects:** HTML  

### What happened
Path recording captured the left controller position at XR frame rate (~60 fps) while the user slowly moved the controller along the floor. Analysis logs confirmed **1,615 points over 41 cm** and **2,764 points over 57 cm** — one position sample approximately every **0.25 mm**.

The steering formula divides heading change by segment distance:
```javascript
const curvature = headingChange / Math.max(segmentDist, 0.01);
const steeringAngleDeg = Math.max(-30, Math.min(30, curvature * 100));
```
With `segmentDist ≈ 0.00025 m`, even 1° of position noise between adjacent raw points produces a curvature of ~70 rad/m. Multiplied by 100 and clamped: **every single command hit maximum steering (50° or 130°)** regardless of how gentle the drawn curve was. No intermediate values were ever possible.

Command timing was equally catastrophic:
```
duration = 0.00025 m / 0.3 m/s = 0.83 ms per command → ~1,200 Hz
```
Mode 1 runs at 2 Hz. The servo's mechanical bandwidth is ~5–20 Hz. At 1,200 Hz the servo received hundreds of opposing full-deflection commands per second and could not physically respond.

### Consequence chain
1,200 Hz × 26 bytes per command = **31,200 bytes/s required throughput** against a 115,200 baud (~11,520 bytes/s) serial link. The OS kernel UART buffer (4,096 bytes) filled within 130ms. Python's `serial.write()` began blocking. The WebSocket receive queue backed up. After 5–8 seconds the connection dropped and the Arduino required a hardware reboot to recover.

### Fix
Added `downsamplePath()` in HTML, called before command generation:
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
mode2DownsampledPath = downsamplePath(trajectoryPoints, 0.05);
```
Result: ~1,600 raw points → ~20 clean waypoints for a 1 m path. New command rate: `0.05 / 0.3 = 167 ms per command → ~6 Hz`, within servo bandwidth.

---

## Issue 2 — Missing heading update in regeneration loop causes compounding steering errors

**Severity:** Critical  
**Affects:** HTML  

### What happened
After calibration, `regeneratePathCommandsWithHeading()` rebuilds all steering commands. Inside its loop it computed `headingChange = targetHeading - mode2RobotHeading` but **never updated `mode2RobotHeading` at the end of each iteration**. Every segment therefore computed its turn relative to the same initial calibration heading rather than the previous segment's heading. A smooth curve requiring +5°, +5°, +5° steering increments was instead calculated as +5°, +10°, +15°, +20°... each growing until clamped to the opposite extreme. This caused alternating 50°/130° commands even on paths that should have produced smooth, gradual steering.

The equivalent line existed correctly in the original `generatePathCommands()` function. It was simply omitted when the regeneration function was written as a separate code path.

### Fix
One line added at the end of the loop in `regeneratePathCommandsWithHeading`:
```javascript
mode2RobotHeading = targetHeading;  // was missing
```

---

## Issue 3 — "GPS" position source frozen during execution

**Severity:** Critical  
**Affects:** HTML  

### What happened
The code used `mode1LeftMarker.position.x/z` as its live vehicle position during both the calibration heading calculation and each execution step. This Three.js mesh object is only updated inside the Mode 1 XR tracking block, which is gated by `mode1LeftTracking === true`. During Mode 2 autonomous execution, Mode 1 is not active, so `mode1LeftTracking` is false, that block never runs, and `mode1LeftMarker.position` is permanently frozen at whatever value it held when Mode 1 was last used.

The live Mode 2 position was being computed correctly in the Mode 2 XR tracking block (Kalman-filtered `fx`, `fz` variables) but was only used to update the 3D vehicle model on screen — never stored anywhere the execution function could read it.

### Fix
In the Mode 2 XR tracking block (within the XR animation frame loop):
```javascript
window.mode2LiveX = fx;
window.mode2LiveZ = fz;
```
In `executeNextMode2Command()`, replaced all reads of `mode1LeftMarker.position` with reads of `window.mode2LiveX/Z`.

---

## Issue 4 — Calibration displacement baked into path start, causing 40 cm positional lag

**Severity:** Major  
**Affects:** HTML  

### What happened
The 2-second calibration phase drove the vehicle straight at 60% speed, moving it approximately 15–20 cm forward. However, `pathPoints[0]` (the path origin used in all command generation) was still the controller position recorded at drawing time, never updated after calibration. Every execution step began with an immediate positional error of ~20 cm baked in. This directly explained the consistent **ΔZ = 4–5 grid cells (40–50 cm) lag** seen at every marker in all analysis files across all test sessions.

### Fix
After calibration movement is measured, all path points are shifted by the displacement delta:
```javascript
const offsetX = currentX - cmd.targetPosition.x;
const offsetZ = currentZ - cmd.targetPosition.z;
mode2DownsampledPath.forEach(p => {
    p.x += offsetX;
    p.z += offsetZ;
});
```

---

## Issue 5 — Race condition between Approve and Execute causes immediate abort

**Severity:** Critical  
**Affects:** HTML  

### What happened
`mode2TrackingActive` is set to `true` when the user presses Approve (panel button). `window.mode2LiveX/Z` is only populated in the Mode 2 XR tracking block, which runs on the **next XR animation frame** after `mode2TrackingActive` becomes true. If the user pressed the A button to execute on the same frame as Approve, `mode2LiveX` was still `undefined`. The safety guard detected this and called `stopMode2Following()` before the vehicle had moved at all. This was the primary cause of runs ending with "0/N waypoints reached" after only 5–8 seconds.

### Fix
Added a polling retry at the start of `sendTrajectory()`:
```javascript
if (window.mode2LiveX === undefined) {
    let retries = 0;
    const waitForTracking = setInterval(() => {
        retries++;
        if (window.mode2LiveX !== undefined) {
            clearInterval(waitForTracking);
            sendTrajectory();  // retry once position is ready
        } else if (retries >= 20) {
            clearInterval(waitForTracking);
            isSent = false;
            document.getElementById('trajectory-status').textContent = 'ERROR: NO POSITION';
        }
    }, 16);  // ~1 frame at 60 fps
    return;
}
```

---

## Issue 6 — Mode switch during execution wipes live position tracking

**Severity:** Major  
**Affects:** HTML  

### What happened
The mode-switch handler contained `mode2TrackingActive = false` unconditionally whenever the user left Mode 2. If the user switched away and back during an active run (observed in the 102-second test session where the user cycled MODE2 → MODE1 → MODE2), `mode2TrackingActive` was set to false. The Mode 2 XR tracking block stopped updating `window.mode2LiveX/Z`. Every subsequent execution step hit the position-undefined guard, retried 5 times, then stopped execution. The 102-second run with 0/15 waypoints reached was caused by this.

### Fix
The mode-switch handler now only clears tracking state when execution is not running:
```javascript
if (mode !== 2) {
    if (!mode2Following) {  // guard added
        mode2TrackingActive = false;
        mode2ControllerPath = [];
        // ... cleanup
    }
}
```

---

## Issue 7 — isSent flag never reset after stop, preventing re-execution

**Severity:** Major  
**Affects:** HTML  

### What happened
`isSent` was set to `true` when execution began and only cleared in the delete-trajectory handler. After any run completed or was stopped, pressing A again did nothing because `isSent` was still `true`. Users were forced to delete and redraw the entire path to attempt a second run. This made iterative testing extremely slow.

### Fix
```javascript
// Added to stopMode2Following():
isSent = false;
```

---

## Issue 8 — No clearTimeout on stop causes serial burst on Quest headset resume

**Severity:** Critical  
**Affects:** HTML  

### What happened
`stopMode2Following()` set `mode2Following = false` but never called `clearTimeout()` on the pending timer from `setTimeout(() => executeNextMode2Command(), cmd.duration)`. The JavaScript event loop continued holding references to all pending timer callbacks. When the Quest headset was briefly paused (home button press, tracking loss, menu overlay) and then resumed, all expired `setTimeout` callbacks fired simultaneously. Two separate Mode 2 execution chains from two different runs both released at once, generating 300+ commands in 2.8 seconds.

The server log confirmed two distinct bursts at 22:34:39 and 22:34:41, each at 30–36 Hz, producing severe Arduino serial corruption:
```
ERROR: Unknown command: 0:M2:0:S1:90:S2:90ALL:M1:0:M2:0:S1:
ERROR: Unknown command: S1:90:S2:90ALL:M1:0:M2:0:S1:90:S2:9
```

### Fix
```javascript
let mode2PendingTimeout = null;

// Both setTimeout calls now store their ID:
mode2PendingTimeout = setTimeout(() => executeNextMode2Command(), cmd.duration);

// stopMode2Following() now cancels it:
if (mode2PendingTimeout !== null) {
    clearTimeout(mode2PendingTimeout);
    mode2PendingTimeout = null;
}
```

---

## Issue 9 — Triple Arduino write per Mode 2 execution step

**Severity:** Major  
**Affects:** HTML + Python server  

### What happened
Per execution step, Mode 2 generated three separate Arduino serial writes:
1. `ALL:M1:...:S2:N` sent directly by the HTML → server forwards to Arduino (write 1)
2. `TRACK:...:M1:...:S2:N` sent by the HTML → server parses it and sends another `ALL:` to Arduino (write 2)
3. Emergency stop sent twice in `stopMode2Following()` (writes 3 and 4 at end of run)

Mode 1 sent only `TRACK:` (no direct `ALL:`), so the server correctly produced one Arduino write per heartbeat. Mode 2 was generating 2–3× the Arduino serial traffic of Mode 1 for the same number of logical commands. Under headset-resume burst conditions this made the overflow far worse.

### Fix
HTML now sends `MODE2_TRACK:` instead of `TRACK:` from Mode 2 execution:
```javascript
const trackCommand = `MODE2_TRACK:${timestamp}:${liveX_cm}:0:${liveZ_cm}:...`;
```
Python server handles `MODE2_TRACK:` separately — parses position for logging and analysis but does **not** forward to Arduino:
```python
if command.startswith('MODE2_TRACK:'):
    # parse for logging only — do NOT call send_to_arduino()
elif command.startswith('TRACK:'):
    # Mode 1 path — parse AND forward to Arduino (existing behaviour)
```

---

## Issue 10 — Calibration heading derived from single noisy snapshot

**Severity:** Major  
**Affects:** HTML  

### What happened
The calibration heading was computed as a single snapshot: controller position at `t=0` versus `t=2s` of the calibration drive:
```javascript
mode2RobotHeading = Math.atan2(currentX - startX, currentZ - startZ);
```
Any hand movement, Quest tracking drift, or small motion noise at either endpoint corrupted the heading for the entire run. The server CSV confirmed this precisely: `actual_heading = 292.1°` throughout an entire run while the path required ~175° (southward). The 117° error meant every steering command pushed the vehicle in the wrong direction from the first step.

### Fix
The initial heading is now blended between controller movement direction (30%) and the drawn path's own first segment direction (70%). The drawn path is ground truth for intended travel direction:
```javascript
const pathHeading = Math.atan2(
    mode2DownsampledPath[1].x - mode2DownsampledPath[0].x,
    mode2DownsampledPath[1].z - mode2DownsampledPath[0].z
);
const controllerHeading = Math.atan2(dx, dz);
const blendedDx = 0.3 * Math.sin(controllerHeading) + 0.7 * Math.sin(pathHeading);
const blendedDz = 0.3 * Math.cos(controllerHeading) + 0.7 * Math.cos(pathHeading);
mode2RobotHeading = Math.atan2(blendedDx, blendedDz);
```
If the vehicle did not move enough during calibration (`distMoved < 0.05 m`), the heading falls back entirely to the path first-segment direction rather than defaulting to 0°.

---

## Issue 11 — Immediate stop on single undefined position, no retry

**Severity:** Major  
**Affects:** HTML  

### What happened
A guard was added: if `window.mode2LiveX === undefined` at any execution step, call `stopMode2Following()` immediately. While safe in principle, a single missed XR frame (common during mode transitions, Quest menu overlays, or brief tracking loss) permanently aborted the entire run. Runs of 5.0 s and 7.8 s with 0/13 and 0/20 waypoints reached were partly caused by this.

### Fix
Replaced with a retry counter allowing up to 5 consecutive failures (~500ms) before stopping:
```javascript
mode2LiveXRetryCount++;
if (mode2LiveXRetryCount > 5) {
    stopMode2Following();
    return;
}
setTimeout(() => executeNextMode2Command(), 100);
return;
mode2LiveXRetryCount = 0;  // reset on success
```

---

## Issue 12 — Live heading correction during execution was decorative

**Severity:** Structural  
**Affects:** HTML  

### What happened
During each execution step, `mode2RobotHeading` was updated from live controller movement. But `cmd.servo2` — the steering value actually sent to Arduino — was fixed at pre-computation time and never revised. The updated heading only rotated the 3D vehicle model on screen. The Arduino received stale pre-computed steering values regardless of where the vehicle actually was.

### Fix
After updating `mode2RobotHeading` from live position, recalculate the servo angle for the current command before sending:
```javascript
let headingError = cmd.targetHeading - mode2RobotHeading;
while (headingError > Math.PI) headingError -= 2 * Math.PI;
while (headingError < -Math.PI) headingError += 2 * Math.PI;
const steerDeg = Math.max(-30, Math.min(30, headingError * (180 / Math.PI)));
actualServo2 = Math.round(Math.max(50, Math.min(130, 90 + steerDeg * (40 / 30))));
```

---

## Issue 13 — OS serial buffer survives server restarts, corrupting the next session

**Severity:** Critical  
**Affects:** Python server  

### What happened
This was the most damaging finding. When the previous session's burst (300+ commands in 2.8 seconds) filled the OS kernel UART buffer, that buffered data was **not discarded** when the Python server shut down with `Ctrl+C`. It remained in the kernel's buffer associated with `/dev/ttyACM0`. When the new server session opened the same port, the kernel immediately began draining all stacked data onto the Arduino's UART line. The Arduino received hundreds of fragmented, concatenated commands before the server had sent a single byte.

The startup log from the affected session confirmed this — the Arduino was printing error messages during `connect_arduino()` before any Quest connection or command existed:
```
Arduino: ERROR: Unknown command: :0:M2:0:S1:90:S2:90ALL:M1:
Arduino: ERROR: Unknown command: S1:90:S2:90ALL:M1:0:M2:0:S1:90:S2:90
```
The old startup code used `while arduino_serial.in_waiting > 0: readline()` which exited the moment `in_waiting` momentarily hit zero — but the Arduino was still receiving and responding to buffered garbage. Mode 1 appeared active but commands arrived at ~6 seconds per command instead of 0.5 seconds, because `readline()` was blocking on long error strings being emitted by the Arduino parser. Motors and servos received nothing usable. No CSV logs were produced because the tracking data path never activated.

### Fix (Python server)
Three-stage buffer purge at startup:

**Stage 1:** OS-level flush immediately after opening the port:
```python
arduino_serial.reset_input_buffer()   # discard OS incoming buffer
arduino_serial.reset_output_buffer()  # discard OS outgoing buffer
time.sleep(0.1)
```

**Stage 2:** Flush Arduino's own 64-byte parser buffer:
```python
arduino_serial.write(b'\n')   # send bare newline to flush partial command
time.sleep(0.15)
arduino_serial.reset_input_buffer()  # discard the resulting error response
```

**Stage 3:** Active drain loop — reads until port is silent for 500ms:
```python
last_data_time = time.time()
while time.time() - last_data_time < 0.5:
    if arduino_serial.in_waiting > 0:
        line = arduino_serial.readline().decode('utf-8', errors='ignore').strip()
        last_data_time = time.time()
    if time.time() - drain_start > 5.0:
        break  # safety: never drain for more than 5s
    time.sleep(0.01)
arduino_serial.reset_input_buffer()  # final flush
```

---

## Issue 14 — No server-side rate limiter allows burst to saturate serial port

**Severity:** Critical  
**Affects:** Python server  

### What happened
The Python server forwarded every incoming WebSocket message to Arduino with no rate limiting or pacing. At 1,200 Hz the serial port was physically overwhelmed. Even after the HTML-side `clearTimeout` fix, any future edge case — a new bug, a headset firmware change, a new mode — could recreate the burst. The server had no defence layer.

### Fix
20ms minimum spacing between serial writes in `send_to_arduino()`:
```python
now = time.time()
if hasattr(send_to_arduino, '_last_write_time'):
    elapsed = now - send_to_arduino._last_write_time
    if elapsed < 0.020:  # max 50 Hz
        time.sleep(0.020 - elapsed)
send_to_arduino._last_write_time = time.time()
```
Even if the HTML side fires a 300-command burst, the server absorbs it and paces delivery to Arduino at a maximum of 50 commands per second — 6× the normal Mode 1 rate and well within serial capacity.

---

## Issue 15 — TRACK position unit mismatch between Mode 1 and Mode 2

**Severity:** Structural  
**Affects:** HTML + Python server  

### What happened
Mode 1 computed position in cm relative to map centre before sending `TRACK:`:
```javascript
leftX_cm = ((leftX - userX) / MAP_SIZE * 200);
```
Mode 2 sent raw XR world coordinates in metres (`window.mode2LiveX`). The server multiplied all `TRACK:` positions by 100 assuming metres, making Mode 1 position values incorrect in the server's deviation analysis. The analysis was logging meaningless cross-track errors.

### Fix
Mode 2 now converts to cm before sending, and uses the `MODE2_TRACK:` prefix (Issue 9 fix) so the server handles each mode's position data on separate code paths with correct unit assumptions.

---

## Issue 16 — Analysis file reports 10× inflated path distances

**Severity:** Cosmetic  
**Affects:** HTML (analysis export)  

### What happened
`analyzeMode2Paths()` used raw `trajectoryPoints` (Three.js world coordinates in metres) for its distance calculation. The `mode2_analysis (4).txt` file reported `Total Distance: 9.985m` for a path physically covering ~1m. This was a display-only issue in the exported text file — not a movement or calculation error — but it caused confusion about whether the path generation itself was broken.

### Status
No code fix applied. The analysis export is cosmetic. The actual waypoints used for execution are from the downsampled path, which is correct.

---

## Issue 17 — Python asyncio warnings on Ctrl+C (cosmetic)

**Severity:** Cosmetic  
**Affects:** Python server  

### What happened
```
Task was destroyed but it is pending!
KeyboardInterrupt in conn_handler
TypeError: 'NoneType' object is not iterable
```
These are Python 3.13 asyncio cleanup artefacts when `Ctrl+C` interrupts an active WebSocket connection. The emergency stop was correctly sent and the Arduino serial port was correctly closed before shutdown. No operational impact.

### Status
No fix required. Normal asyncio behaviour on abrupt shutdown.

---

## Issue 18 — Server IP displayed as 127.0.1.1 instead of LAN IP

**Severity:** Minor  
**Affects:** Python server  

### What happened
The server printed `Quest 3 URL: wss://127.0.1.1:8444` because the hostname lookup resolved to a loopback alias in Ubuntu's `/etc/hosts`. The server bound correctly to `0.0.0.0` (all interfaces) so connections from the Quest worked, but the printed URL was unusable and confusing during debugging.

### Status
Not fixed in current version. Workaround: use `hostname -I` or `ip addr` to find the actual LAN IP before starting the server.

---

## Complete Fix Matrix

| # | Severity | Description | File | Version |
|---|---|---|---|---|
| 1 | Critical | 1,200 Hz command rate / oscillation from raw path density | HTML | v1 |
| 2 | Critical | All steering angles wrong — missing heading update in regen loop | HTML | v1 |
| 3 | Critical | Serial overflow and connection drop (consequence of #1) | HTML | v1 |
| 4 | Major | 40–50 cm positional lag — calibration displacement not offset | HTML | v1 |
| 5 | Critical | Execution aborts before movement — race condition at Approve/Execute | HTML | v1 |
| 6 | Major | Live position freezes after mode switch during execution | HTML | v1 |
| 7 | Major | Cannot re-run after stop — isSent never reset | HTML | v1 |
| 8 | Critical | Command burst on Quest headset resume — no clearTimeout | HTML | v2 |
| 9 | Major | Triple Arduino write per step — TRACK forwarded as extra ALL: | HTML + Server | v2 |
| 10 | Major | Heading stuck at wrong angle — single noisy calibration snapshot | HTML | v2 |
| 11 | Major | Immediate abort on single missed XR frame — no retry logic | HTML | v1 |
| 12 | Structural | Live heading correction decorative — servo not recalculated | HTML | v1 |
| 13 | Critical | OS serial buffer corruption survives restart, breaks next session | Server | v3 |
| 14 | Critical | No server-side rate limiter — burst can saturate serial at any time | Server | v3 |
| 15 | Structural | TRACK position units mismatch Mode 1 vs Mode 2 | HTML + Server | v2 |
| 16 | Cosmetic | Analysis export shows 10× inflated distances | HTML | Not fixed |
| 17 | Cosmetic | Python asyncio warnings on Ctrl+C | Server | Not fixed |
| 18 | Minor | Server displays 127.0.1.1 instead of LAN IP | Server | Not fixed |

---

## Final File Versions

| File | Fixes included |
|---|---|
| `trajectory_6modes_tracker_FINAL.html` | Issues 1–12, 15 |
| `trajectory_websocket_server_FINAL.py` | Issues 9, 13, 14, 15 |

---

## Outstanding Concerns for Next Test Session

**Server-side waypoint advance never triggered:** All test runs reported `Waypoints reached: 0/N` at completion. The server advances `mode2_current_waypoint` when position error falls below a threshold. With average deviations of 33–49 cm in the logs, the waypoint may never have been close enough to advance. This threshold may need relaxing, or waypoint advance logic should switch to distance-along-path rather than proximity to target.

**Suspected motor differential direction inversion:** In several execution logs, `M1:63 M2:50` was paired with `S2:130` (left steer) and `M1:50 M2:63` with `S2:50` (right steer). Correct Ackermann differential for left steer requires the inner (right) wheel to be slower — if M1 is the right motor, `M1:50 M2:63` should accompany left steer, not the reverse. This may mean the differential sign convention is inverted for one motor, causing the vehicle to understeer or oversteer on curves.

**Heading validation test recommended:** Before testing a full curve, test a straight 3m path. The calibration log should show `Controller: X° Path: X° Blended: X°` with all three values close together. If controller heading differs from path heading by more than 30°, the controller is wobbling during calibration and the mount should be stabilised.

---

*Compiled from code review across multiple HTML versions, Python server versions, execution log files, CSV tracking exports, and WebSocket server terminal output — April 2026.*
