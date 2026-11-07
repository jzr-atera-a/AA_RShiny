# Mode 2 Autonomous Path Following — Bug Report & Fix Recommendations

**Project:** Meta Quest 3 AR Robot Control  
**File analysed:** `trajectory_6modes_tracker.html`  
**Reference logs:** `mode2_analysis (1).txt`, `mode2_analysis (2).txt`  
**Date:** April 2026  

---

## Context

Mode 1 (manual joystick control) is working acceptably. Mode 2 (autonomous path following, where the user draws a route on the floor and the vehicle executes it) is failing completely. The vehicle exhibits violent steering oscillations within the first few seconds, travels only 18–25% of the planned path, then loses WebSocket connection to the Arduino entirely — requiring a full AR session restart or hardware reboot to recover.

---

## Observed Symptoms

| Symptom | Measured value |
|---|---|
| Path completion | ~25% average across both test runs |
| Servo 2 oscillation | Alternates 50° ↔ 130° (full left ↔ full right) continuously |
| Positional lag at every marker | ~40 cm behind planned path (ΔZ = 4 grid cells) |
| Time before connection loss | 5–8 seconds after execution starts |
| Recovery required | Full AR session restart or hardware reboot |

---

## Root Cause Analysis

### Bug 1 — Critical: Path density causes curvature formula to explode

**What is happening:**  
The path is recorded from the left Meta Quest controller at XR frame rate (~60 fps) while the user slowly moves it along the floor. The two test logs confirm **1,615 and 2,764 points over 41 cm and 57 cm respectively** — one position sample approximately every **0.25 mm**.

The steering angle for each segment is computed as:

```javascript
const curvature = headingChange / Math.max(segmentDist, 0.01);
const steeringAngleDeg = Math.max(-30, Math.min(30, curvature * 100));
const servo2 = Math.round(90 + steeringAngleDeg * (40 / 30));
```

With `segmentDist ≈ 0.00025 m`, even 1° of position noise between adjacent raw points produces a curvature of ~70 rad/m. Multiplied by 100, this always exceeds the ±30° clamp. **Every single command is computed at maximum steering — 50° or 130° — regardless of how gentle the curve is.**

**Fix:**  
Downsample the recorded trajectory to one point every **~5 cm** before calling `generatePathCommands`. This reduces ~1,600 raw points to ~20 clean waypoints for a 1 m path. Position noise averages out, and the curvature formula produces proportionate, smooth steering values.

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
    // Always include the final point
    const last = points[points.length - 1];
    if (result[result.length - 1] !== last) result.push(last);
    return result;
}

// Call before generating commands:
const cleanPath = downsamplePath(trajectoryPoints, 0.05);
mode2PathCommands = generatePathCommands(cleanPath);
```

---

### Bug 2 — Critical: `regeneratePathCommandsWithHeading` never updates heading between segments

**What is happening:**  
After the 2-second calibration drive, `regeneratePathCommandsWithHeading()` is called to rebuild all steering commands using the correct initial heading. Inside its loop, it computes each segment's heading change as:

```javascript
let headingChange = targetHeading - mode2RobotHeading;
```

But **`mode2RobotHeading` is never updated at the end of each iteration**. Every segment therefore computes its turn relative to the same calibrated initial heading — not the previous segment's heading. On a smooth curve that should produce +5°, +5°, +5°, the code calculates +5°, +10°, +15°, growing without bound until clamped to opposite extremes. This is the primary cause of alternating 50°/130° commands.

Note: `generatePathCommands` has this line correctly — it was simply omitted from the regenerate function.

**Fix:**  
Add one missing line at the end of the loop in `regeneratePathCommandsWithHeading`:

```javascript
for (let i = 1; i < pathPoints.length; i++) {
    // ... existing calculations ...

    mode2RobotHeading = targetHeading;  // ← ADD THIS LINE (was missing)
}
```

---

### Bug 3 — Critical: Command frequency is ~1,200 Hz — 600× faster than Mode 1

**What is happening:**  
Mode 2 executes one command per path segment, held for a duration calculated as:

```javascript
const duration = segmentDist / speedMetersPerSec;  // in seconds
setTimeout(() => executeNextMode2Command(), cmd.duration);  // cmd.duration in ms
```

With raw path segments of 0.25 mm and vehicle speed ~0.3 m/s:

```
duration = 0.00025 / 0.3 = 0.00083 s = 0.83 ms per command → ~1,200 Hz
```

For comparison, Mode 1 sends commands at **2 Hz** (one every 500 ms). The servo's mechanical bandwidth is approximately 5–20 Hz. At 1,200 Hz the servo receives hundreds of opposing full-deflection commands per second and cannot physically respond — it just vibrates. The Arduino's serial buffer fills up almost instantly, causing the WebSocket connection to saturate and drop after 5–8 seconds.

**Fix:**  
Path downsampling (Bug 1 fix) directly solves this. With 5 cm segments:

```
duration = 0.05 / 0.3 = 0.167 s = 167 ms per command → ~6 Hz
```

This is within the servo's mechanical response range and consistent with what Mode 1 does.

---

### Bug 4 — Major: "GPS" position read during execution is frozen

**What is happening:**  
The code uses `mode1LeftMarker.position` as its live position source during Mode 2 calibration (line 2683) and each execution step (line 2731). This object is a Three.js marker that is only updated inside the Mode 1 tracking block:

```javascript
// Line 4949 — only runs when mode1LeftTracking === true
if (source.handedness === 'left' && mode1LeftTracking && source.gripSpace) {
    mode1LeftMarker.position.set(fx, controllerY, fz);  // line 5001
}
```

`mode1LeftTracking` is only ever set to `true` inside `startManualControl()`. During Mode 2 autonomous execution, Mode 1 is not active, so this block never runs and `mode1LeftMarker.position` is completely frozen at whatever value it held when Mode 1 was last used.

The **live** controller position during Mode 2 execution is available in the Mode 2 tracking block (lines 5041–5072), stored locally as `fx` and `fz` — but never exposed for the execution function to read.

**Fix:**  
In the Mode 2 tracking block (around line 5049), write the live position to a shared variable:

```javascript
// Add inside Mode 2 tracking block, after line 5049:
window.mode2LiveX = fx;
window.mode2LiveZ = fz;
```

Then replace both reads of `mode1LeftMarker` in the execution function:

```javascript
// Lines 2683–2685 (calibration) and 2731–2733 (execution steps):
// Replace:
if (mode1LeftMarker && mode2CalibrationComplete) {
    const currentX = mode1LeftMarker.position.x;
    const currentZ = mode1LeftMarker.position.z;

// With:
if (window.mode2LiveX !== undefined && mode2CalibrationComplete) {
    const currentX = window.mode2LiveX;
    const currentZ = window.mode2LiveZ;
```

---

### Bug 5 — Major: Calibration displacement offsets path start by ~20 cm

**What is happening:**  
The 2-second calibration phase drives the vehicle straight at 60% speed, moving it approximately 15–20 cm forward before path following begins. However, `pathPoints[0]` (the origin used for all command generation) is the controller position recorded at drawing time. Execution therefore begins with an immediate built-in positional error of ~20 cm. This directly explains the consistent **ΔZ = 4 grid cells (40 cm)** lag seen at every marker in both analysis files.

**Fix:**  
After calibration completes and the GPS displacement is measured, shift the entire path by that delta before calling `regeneratePathCommandsWithHeading`:

```javascript
// After measuring dx, dz from calibration movement:
const offsetX = currentX - cmd.targetPosition.x;
const offsetZ = currentZ - cmd.targetPosition.z;
trajectoryPoints.forEach(p => {
    p.x += offsetX;
    p.z += offsetZ;
});
// Then regenerate:
regeneratePathCommandsWithHeading();
```

---

### Bug 6 — Structural: Live GPS heading update during execution is decorative

**What is happening:**  
During each execution step, the code reads the live position and updates `mode2RobotHeading`:

```javascript
mode2RobotHeading = Math.atan2(dx, dz);  // line 2741
```

However, the pre-computed `cmd.servo2` values in `mode2PathCommands[]` are never recalculated from this updated heading. The corrected heading only rotates the 3D vehicle model on screen — the Arduino continues receiving the stale pre-computed steering values.

**Fix:**  
After updating `mode2RobotHeading` from live position, compute a corrected servo2 for the next upcoming command and patch it before sending:

```javascript
if (distMoved > 0.02) {
    mode2RobotHeading = Math.atan2(dx, dz);

    // Recalculate steering for next command using actual heading
    if (mode2FollowIndex < mode2PathCommands.length) {
        const nextCmd = mode2PathCommands[mode2FollowIndex];
        if (nextCmd.targetHeading !== null) {
            let headingError = nextCmd.targetHeading - mode2RobotHeading;
            while (headingError > Math.PI) headingError -= 2 * Math.PI;
            while (headingError < -Math.PI) headingError += 2 * Math.PI;
            const steerDeg = Math.max(-30, Math.min(30, headingError * (180 / Math.PI)));
            nextCmd.servo2 = Math.round(Math.max(50, Math.min(130, 90 + steerDeg * (40 / 30))));
        }
    }
}
```

---

## Connection Loss Explanation

The 5–8 second connection drop is a direct consequence of Bugs 1 and 3 combined. At ~1,200 Hz, the Quest is sending a new `ALL:M1:...:S2:...` command to the Python WebSocket server every 0.83 ms. The Python server forwards each one to the Arduino over serial at 115,200 baud. Each command string is approximately 28 bytes, giving a required throughput of:

```
28 bytes × 1,200 commands/s = 33,600 bytes/s = 268,800 baud
```

This is **2.3× the serial baud rate capacity**. The Arduino's serial receive buffer (64 bytes) overflows almost immediately. The Python server begins blocking on `serial.write()`, causing the WebSocket receive queue to back up. After a few seconds the WebSocket connection times out or the Quest drops it. The Arduino may also enter an error state from the buffer overflow, which is why a hardware reboot is sometimes needed.

Fixing Bug 1 (downsampling to 5 cm) reduces throughput to:

```
28 bytes × 6 commands/s = 168 bytes/s
```

Well within serial and WebSocket capacity.

---

## Summary — Priority Order

| Priority | Bug | Impact | Fix complexity |
|---|---|---|---|
| 1 | Path density → 1,200 Hz command rate | Oscillation + connection loss | Low — add downsample function |
| 2 | Missing heading update in regen loop | All steering angles wrong | Trivial — one missing line |
| 3 | Frozen "GPS" position source | Self-correction never works | Low — shared variable |
| 4 | Calibration offset not applied to path | Systematic 40 cm positional lag | Low — shift path points |
| 5 | Live heading not fed back to commands | No in-flight correction | Medium — patch next command |

**Fixes 1 and 2 alone should eliminate the oscillation and the connection drops.** Fixes 3, 4, and 5 are needed for accurate path following once the oscillation is resolved.

---

## What Mode 1 Does Right (reference for Mode 2)

- Sends commands at **2 Hz** — within servo mechanical bandwidth
- Derives heading **only from movement** (`atan2(dx, dz)` when `dist > 0.02 m && motorSpeed > 20`) — never from controller orientation
- Freezes heading when stationary — no noise injection
- Uses the same Kalman-filtered position throughout

Mode 2 should mirror this architecture: a low fixed command rate, heading derived from actual movement, and a single authoritative live position source.

---

*Report generated from code analysis of `trajectory_6modes_tracker.html` and execution logs `mode2_analysis (1).txt` / `mode2_analysis (2).txt`.*
