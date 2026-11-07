# AR TRAJECTORY SYSTEM - QUICK REFERENCE GUIDE

## 🎮 CONTROLLER LAYOUT

### LEFT CONTROLLER:
- **Grip Space** → Position tracking (Modes 1, 2, 3-Virtual, 4)
- **Orientation** → Vehicle heading

### RIGHT CONTROLLER:
- **Trigger** → Panel clicks, trajectory drawing (Mode 2)
- **Grip** → (Reserved)
- **Thumbstick** → Delete last point (Mode 2)
- **A Button** → Send trajectory (Mode 2)
- **B Button** → (Reserved)
- **Joystick** → Robot control (Mode 1)

---

## 📍 MODES OVERVIEW

| Mode | Name | Left Controller | Right Controller | Panel |
|------|------|-----------------|------------------|-------|
| 0 | Map View | - | - | None |
| 1 | Manual | Vehicle position | Joystick drives | None |
| 2 | User Trajectory | Tracks after approval | Draw path | LEFT |
| 3 | M25 Highway | Virtual mode only | - | LEFT |
| 4 | Track Robot | Vehicle position | - | None |
| 5 | Anchor | - | Place anchor | None |
| 6 | EV Chargers | - | Select chargers | None |

---

## 🟢 MODE 2: USER TRAJECTORY

### **Setup:**
1. Select Mode 2 from main panel
2. Left panel appears

### **Drawing Path:**
1. Point RIGHT controller at floor
2. Hold TRIGGER to draw → **GREEN path**
3. Release trigger to stop
4. Thumbstick to delete last point

### **Tracking:**
1. Click **"APPROVE TRAJECTORY"** on left panel
2. Move LEFT controller
3. Vehicle follows → **ORANGE path** drawn
4. Click **"STOP TRACKING"** when done

### **Analysis:**
1. Click **"SEND FOR ANALYSIS"**
2. Downloads `mode2_analysis.txt`
3. Compares GREEN vs ORANGE paths

### **Button Layout:**
```
┌─────────────────────────┐
│   MODE 2 CONTROLS       │
├─────────────────────────┤
│ APPROVE TRAJECTORY      │ ← Click to start tracking
├─────────────────────────┤
│ STOP TRACKING           │ ← Click to stop tracking
├─────────────────────────┤
│ SEND FOR ANALYSIS       │ ← Click to download file
└─────────────────────────┘
```

---

## 🔵 MODE 3: M25 HIGHWAY

### **Setup:**
1. Select Mode 3 from main panel
2. Left panel appears
3. Default mode is **REAL**

### **REAL Mode** (Auto-drive):
1. REAL button highlighted
2. Vehicle auto-drives M25
3. No manual control

### **VIRTUAL Mode** (Manual drive):
1. Click **"VIRTUAL"** button
2. Move LEFT controller
3. Vehicle follows → **ORANGE path** drawn

### **SIMULATION Mode** (Auto-demo):
1. Click **"START SIMULATION"**
2. Vehicle moves at 20cm/s in circle
3. **ORANGE path** drawn
4. Click **"STOP SIMULATION"** to end
5. Loops continuously until stopped

### **Analysis:**
1. Click **"SEND FOR ANALYSIS"**
2. Downloads `mode3_analysis.txt`
3. Compares ideal M25 vs actual path

### **Button Layout:**
```
┌─────────────────────────┐
│   MODE 3 CONTROLS       │
├──────────┬──────────────┤
│   REAL   │   VIRTUAL    │ ← Toggle mode
├──────────┴──────────────┤
│ START SIMULATION        │ ← Auto-move at 20cm/s
├─────────────────────────┤
│ STOP SIMULATION         │ ← Stop auto-move
├─────────────────────────┤
│ SEND FOR ANALYSIS       │ ← Download file
└─────────────────────────┘
```

---

## ⚡ MODE 6: EV CHARGERS

### **Usage:**
1. Select Mode 6 from main panel
2. 3 chargers appear on map (random positions)
3. Point RIGHT controller at charger
4. Press TRIGGER
5. Info panel appears next to charger

---

## 🎨 COLOR GUIDE

| Color | Meaning | Where |
|-------|---------|-------|
| GREEN | User-drawn path | Mode 2 |
| ORANGE | Controller/simulation path | Mode 2, 3 |
| CYAN | Other paths/lines | Various |
| MAGENTA | Tracking markers | Mode 4 |
| LIGHT GREY | Robot/Truck | All modes |

---

## 📊 ANALYSIS FILES

### **mode2_analysis.txt**
```
=== MODE 2 TRAJECTORY ANALYSIS ===

User Path (Green):
  Points: 45
  Total Distance: 2.356m

Controller Path (Orange):
  Points: 234
  Total Distance: 2.412m

Deviation: 0.056m (2.4%)

Sample Point Deviations:
  Point 0: 0.0cm
  Point 5: 3.2cm
  ...
```

### **mode3_analysis.txt**
```
=== MODE 3 M25 ANALYSIS ===

M25 Ideal Path:
  Circumference: 5.277m

Simulation Path (Orange):
  Points: 456
  Total Distance: 5.312m

Deviation: 0.035m (0.7%)

Radial Deviations (from ideal M25):
  Point 0: 0.0cm
  Point 46: 2.1cm
  ...
```

---

## 🔧 TROUBLESHOOTING

### **Chargers not appearing (Mode 6):**
- Check WebSocket connection
- Verify Python server running
- Check console for errors

### **Left panel not showing (Mode 2/3):**
- Ensure Mode 2 or 3 selected
- Check floor detected
- Look 1.1m to the LEFT of main panel

### **Vehicle not following controller:**
- Verify tracking started (Mode 2: click APPROVE)
- Check left controller detected
- Ensure correct mode selected

### **Analysis not downloading:**
- Check enough path data (>2 points)
- Try clicking button again
- Check browser download permissions

### **Orange path not drawing:**
- Mode 2: Click APPROVE TRAJECTORY first
- Mode 3: Select VIRTUAL or START SIMULATION
- Check tracking active

---

## 📱 PANEL POSITIONS

```
                    USER
                     👤
                     
        [LEFT]      [MAIN]      [RIGHT]
     Mode 2/3      Control      Vehicle
       Panel        Panel        Panel
       
     (-1.1m, 0)    (0, 0)     (+1.1m, 0)
```

All panels at:
- Height: `floorY + 0.80m`
- Depth: `-(MAP_SIZE/2 + 0.10)` from user

---

## 🎯 QUICK START WORKFLOW

### **Mode 2 Complete Flow:**
```
1. Select Mode 2
2. Draw green path (RIGHT trigger)
3. Click "APPROVE TRAJECTORY"
4. Move LEFT controller → orange path
5. Click "STOP TRACKING"
6. Click "SEND FOR ANALYSIS"
7. Check downloaded file
```

### **Mode 3 Simulation Flow:**
```
1. Select Mode 3
2. Click "START SIMULATION"
3. Watch vehicle move (20cm/s)
4. Wait for complete circle (or click STOP)
5. Click "SEND FOR ANALYSIS"
6. Check downloaded file
```

### **Mode 3 Virtual Flow:**
```
1. Select Mode 3
2. Click "VIRTUAL"
3. Move LEFT controller → vehicle follows
4. Orange path drawn
5. Click "SEND FOR ANALYSIS"
6. Check downloaded file
```

---

## ⚠️ IMPORTANT NOTES

1. **Tracking Starts After Approval** (Mode 2)
   - Must click "APPROVE TRAJECTORY" button
   - Left controller won't track until approved

2. **Simulation Speed** (Mode 3)
   - Fixed at 20cm/s
   - Loops continuously
   - Click STOP to end

3. **Path Colors**
   - GREEN = User drawn
   - ORANGE = Controller tracked
   - Don't confuse them!

4. **Panel Clicks**
   - Use RIGHT trigger
   - Point directly at button
   - Single click only

5. **Mode Switching**
   - Clears all paths
   - Resets tracking states
   - Removes panels

---

## 📞 SUPPORT

For issues:
1. Check console for errors (F12 in browser)
2. Verify Python servers running
3. Check debug logs
4. Test floor detection first

---

**Happy AR Tracking! 🚀**
