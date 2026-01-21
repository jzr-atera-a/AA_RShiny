# Quest 3 AR → R Shiny Dashboard - Complete Setup Guide

## System Overview

```
Meta Quest 3 (AR Mode)
    ↓ WebSocket (WiFi)
Your Computer (R Shiny Dashboard)
    ↓ Display real-time metrics
Browser showing controller data
```

**What This Does:**
- Quest 3 in AR mode (see your room + virtual overlays)
- Move controllers → Data sent to R Shiny
- R Shiny displays metrics in real-time dashboard
- See angles, positions, velocities, button states

---

## Prerequisites

### On Your Computer:

```r
# Install R packages
install.packages("shiny")
install.packages("websocket")
install.packages("jsonlite")
install.packages("ggplot2")
install.packages("plotly")
install.packages("bslib")
```

### On Meta Quest 3:
- ✅ Meta Browser (pre-installed)
- ✅ Same WiFi as your computer
- ✅ Nothing else needed!

---

## Step-by-Step Setup

### Step 1: Install R Packages

Open R or RStudio:

```r
install.packages(c(
  "shiny",
  "websocket", 
  "jsonlite",
  "ggplot2",
  "plotly",
  "bslib"
))
```

### Step 2: Get Your Computer's IP Address

**Windows:**
```cmd
ipconfig
# Look for "IPv4 Address" under your WiFi adapter
# Example: 192.168.1.100
```

**Mac/Linux:**
```bash
ifconfig
# Or: hostname -I
# Look for inet address
# Example: 192.168.1.100
```

**Write this IP down!** You'll need it.

### Step 3: Place Files on Your Computer

Create a folder (e.g., `C:\quest-ar-dashboard\` or `~/quest-ar-dashboard/`):

```
quest-ar-dashboard/
├── quest_ar_shiny_dashboard.R          # R Shiny app
└── quest_ar_shiny_controller.html      # WebXR interface
```

### Step 4: Start R Shiny Dashboard

In R or RStudio:

```r
# Set working directory
setwd("C:/quest-ar-dashboard")  # Windows
# Or: setwd("~/quest-ar-dashboard")  # Mac/Linux

# Run the app
shiny::runApp("quest_ar_shiny_dashboard.R")
```

You should see:
```
WebSocket server started on port 8080
Quest 3 should connect to: ws://192.168.1.100:8080
```

**Leave this running!** The Shiny dashboard will open in your browser.

### Step 5: Access HTML from Quest 3

You have **2 options**:

#### Option A: Simple HTTP Server (Recommended)

In a **new terminal/command prompt** (while Shiny is running):

```bash
# Navigate to folder
cd C:\quest-ar-dashboard

# Windows (Python):
python -m http.server 8000

# Mac/Linux:
python3 -m http.server 8000
```

Then on Quest 3:
```
http://192.168.1.100:8000/quest_ar_shiny_controller.html
```

#### Option B: Copy to Quest

1. Connect Quest 3 via USB
2. Copy `quest_ar_shiny_controller.html` to Quest
3. Open file in Meta Browser
4. Edit IP in connection panel

### Step 6: Connect from Quest 3

1. **Put on Quest 3 headset**
2. **Open Meta Browser**
3. **Navigate to:** `http://192.168.1.100:8000/quest_ar_shiny_controller.html`
4. **Enter your computer's IP** (e.g., 192.168.1.100)
5. **Click "Connect to R Shiny"**
   - Status should turn green: "🟢 Connected to R Shiny"
6. **Click "Start AR Mode"**
   - Grant AR permissions
   - You now see your room through passthrough!

### Step 7: Test Controllers

1. **Point controller at floor** → See cyan reticle
2. **Press trigger** → Place virtual joystick
3. **Squeeze grip** → Activate control
4. **Move controller** → Watch R Shiny dashboard update!

---

## What You'll See

### On Quest 3 (AR Mode):
- Your real room (passthrough cameras)
- Cyan reticle on floor
- Virtual joystick (when placed)
- Info panel showing connection status

### In R Shiny Dashboard (Your Computer Browser):

```
┌─────────────────────────────────────────────────────┐
│ 🎮 Meta Quest 3 AR Controller Dashboard            │
├─────────────────────────────────────────────────────┤
│ Connection: 🟢 Connected                            │
│ Total Commands: 1,247                               │
│ Last Update: Just now                               │
├─────────────────────────────────────────────────────┤
│ LINEAR VELOCITY          ANGULAR VELOCITY           │
│     +0.75                    -0.20                  │
│  Forward/Backward         Rotation L/R              │
├─────────────────────────────────────────────────────┤
│ Controller 1 (Right)     Controller 2 (Left)        │
│ Position:                Position:                  │
│   X: 0.245                 X: -0.312                │
│   Y: 1.234                 Y: 1.156                 │
│   Z: -0.567                Z: -0.489                │
│ Rotation:                Rotation:                  │
│   X: 15.2°                 X: 12.8°                 │
│   Y: 45.6°                 Y: 38.4°                 │
│   Z: -5.3°                 Z: -3.1°                 │
│ Grip: 🟢 PRESSED          Grip: ⚫ Released         │
│ Trigger: ⚫ Released      Trigger: ⚫ Released      │
├─────────────────────────────────────────────────────┤
│ [Position Tracking Graph]  [Velocity Over Time]    │
└─────────────────────────────────────────────────────┘
```

---

## Dashboard Features

### Real-Time Metrics:

1. **Connection Status**
   - Green = Connected to Quest 3
   - Red = Disconnected
   - Shows total commands received

2. **Velocity Display**
   - Linear: -1.0 to +1.0 (backward to forward)
   - Angular: -1.0 to +1.0 (rotate left to right)
   - Updates in real-time as you move

3. **Controller Data (Both hands)**
   - **Position (X, Y, Z)** in meters
   - **Rotation (X, Y, Z)** in degrees
   - **Grip button** state (pressed/released)
   - **Trigger button** state (pressed/released)

4. **Live Graphs**
   - Position tracking over time (X, Y, Z lines)
   - Velocity over time (Linear, Angular lines)
   - Last 100 data points shown

5. **Statistics**
   - Commands per second
   - Time since last update
   - Total commands received

---

## Controls Reference

### In AR Mode (Quest 3):

| Action | Effect | R Shiny Shows |
|--------|--------|---------------|
| **Point at floor** | Reticle appears | - |
| **Press trigger** | Place joystick | Trigger = PRESSED |
| **Squeeze grip** | Activate control | Grip = PRESSED |
| **Move hand forward** | Linear velocity + | Linear increases |
| **Move hand back** | Linear velocity - | Linear decreases |
| **Move hand left** | Angular velocity - | Angular goes negative |
| **Move hand right** | Angular velocity + | Angular goes positive |
| **Release grip** | Stop control | Velocities → 0 |

### Desktop Testing (Before AR):

Use keyboard on computer:
- **W/↑** = Forward (linear +1)
- **S/↓** = Backward (linear -1)
- **A/←** = Rotate left (angular -1)
- **D/→** = Rotate right (angular +1)

Watch R Shiny dashboard update!

---

## Troubleshooting

### "Cannot connect to R Shiny"

**Problem:** Quest can't reach computer

**Solutions:**
1. Verify both on same WiFi network
2. Check computer IP: `ipconfig` (Windows) or `hostname -I` (Mac/Linux)
3. Check Windows Firewall:
   - Allow R.exe and Rscript.exe through firewall
   - Or temporarily disable firewall for testing
4. Verify R Shiny is running (check console)

### R Shiny App Won't Start

**Problem:** Error loading packages

**Solutions:**
```r
# Check if packages installed
installed.packages()

# Reinstall if needed
install.packages("websocket")
install.packages("shiny")
```

### "WebSocket connection failed"

**Problem:** Port 8080 blocked

**Solutions:**
1. Check if another app using port 8080:
   ```bash
   # Windows
   netstat -ano | findstr :8080
   
   # Mac/Linux
   lsof -i :8080
   ```
2. Change port in both files if needed:
   - In R: `start_websocket_server(8081)`
   - In HTML: `ws://${shinyIP}:8081`

### Quest Shows Black Screen in AR

**Problem:** Passthrough not working

**Solutions:**
1. Check Quest Settings → Guardian → Passthrough enabled
2. Update Quest firmware
3. Restart Quest headset

### No Controller Response

**Problem:** Controllers not tracked

**Solutions:**
1. Check controller batteries
2. Verify Meta logos glow on controllers
3. Re-pair controllers in Quest settings

### Dashboard Not Updating

**Problem:** Data not flowing

**Solutions:**
1. Check Quest info panel shows "Connected"
2. Verify R console shows "Quest 3 connected!"
3. Try clicking "Connect to R Shiny" again
4. Restart R Shiny app

---

## Network Configuration

### Ports Used:
- **8080** - WebSocket (R Shiny ↔ Quest 3)
- **8000** - HTTP server (serving HTML)
- **Auto** - Shiny dashboard (opens automatically)

### Firewall Rules (Windows):

If blocked, allow these:

```
Program: R.exe
Port: 8080
Direction: Inbound
Protocol: TCP
```

Or temporarily for testing:
```cmd
# Run as Administrator
netsh advfirewall set allprofiles state off
```

(Turn back on after testing!)

---

## File Descriptions

### quest_ar_shiny_dashboard.R

**What it does:**
- Starts WebSocket server on port 8080
- Receives controller data from Quest 3
- Displays real-time dashboard
- Shows graphs and metrics

**Key functions:**
- `start_websocket_server()` - Starts WebSocket
- `process_quest_message()` - Handles incoming data
- UI/Server - Shiny dashboard interface

### quest_ar_shiny_controller.html

**What it does:**
- Runs in Quest 3 browser
- Activates AR mode (passthrough)
- Tracks controller positions/rotations
- Sends data to R Shiny via WebSocket

**Key features:**
- WebXR AR support
- Hit testing (surface detection)
- Controller event handling
- Real-time data streaming

---

## Testing Workflow

### Phase 1: Desktop Test (No VR)
1. Start R Shiny dashboard
2. Open HTML in computer browser
3. Use keyboard (WASD) to test
4. Verify dashboard updates

### Phase 2: Quest Connection Test
1. Access HTML from Quest browser (desktop mode)
2. Verify connection to R Shiny
3. Check "Connected" status on both sides

### Phase 3: AR Mode Test
1. Enter AR mode on Quest
2. Grant permissions
3. See passthrough working
4. Test controller tracking

### Phase 4: Full Integration
1. Place joystick in AR
2. Grip controllers
3. Move hands
4. Watch dashboard update in real-time!

---

## Advanced Configuration

### Change Update Rate

In HTML file:
```javascript
// Send data at different rate (default: 20Hz)
if (commandCount % 3 === 0) {  // Change 3 to adjust
    sendControllerData();
}
```

### Adjust Graph History

In R file:
```r
# Keep more/less data points (default: 100)
controller_data$velocity_history <- rbind(
  tail(controller_data$velocity_history, 99),  # Change 99 to adjust
  new_velocity
)
```

### Custom Metrics

Add to R server:
```r
# Example: Calculate controller distance
output$controller_distance <- renderText({
  pos1 <- controller_data$controller1_position
  pos2 <- controller_data$controller2_position
  
  dist <- sqrt(
    (pos1$x - pos2$x)^2 +
    (pos1$y - pos2$y)^2 +
    (pos1$z - pos2$z)^2
  )
  
  sprintf("%.3f meters", dist)
})
```

---

## Next Steps

Once this works, you can:

1. **Add more visualizations** in R Shiny
2. **Process angles/positions** for robot control
3. **Forward commands to Jetson Nano** (add forwarding)
4. **Record sessions** for playback
5. **Add virtual elements** in AR (buildings, paths, etc.)

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────┐
│ QUICK START                                     │
├─────────────────────────────────────────────────┤
│ 1. Install R packages                           │
│ 2. Get computer IP                              │
│ 3. Run: shiny::runApp("quest_ar_shiny_...R")   │
│ 4. Quest: http://IP:8000/quest_ar_shiny_...html│
│ 5. Connect → Start AR → Move controllers!      │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ TROUBLESHOOTING                                 │
├─────────────────────────────────────────────────┤
│ Can't connect?  → Check same WiFi              │
│ Dashboard stuck? → Restart R Shiny             │
│ No AR?          → Grant permissions             │
│ Controllers?    → Check batteries               │
└─────────────────────────────────────────────────┘
```

---

**You now have a complete AR controller dashboard system!** Quest 3 sends data, R Shiny displays it beautifully in real-time. Perfect for testing before Jetson Nano integration! 🎮📊
