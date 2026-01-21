# Bambulab A1 Combo 3D Printer Control Dashboard

A comprehensive R Shiny dashboard application for controlling the Bambulab A1 Combo 3D printer via **WiFi/LAN network connection using MQTT protocol**.

## ⚠️ Connection Method: WiFi/LAN Only

This application connects to your Bambulab A1 printer over your **local network** using the **MQTT protocol**. Both your computer and printer must be on the **same WiFi network**.

**NOT USB** - Bambulab printers use network communication, not USB serial.

## Features

### 1. Network Connection Management
- Connect via WiFi/LAN using MQTT protocol
- Enter printer IP address, access code, and serial number
- Real-time connection status monitoring
- Secure TLS encrypted communication

### 2. File Management
- Upload G-code files (.gcode, .gco, .3mf) via FTP
- File preview with line count and size
- Send files to printer over network
- View printer file list

### 3. Print Control
- Start, stop, pause, and resume print jobs
- Real-time print progress monitoring
- Speed and flow rate adjustment
- Fan speed control
- Temperature management (hotend, bed, chamber)

### 4. Monitoring
- Real-time temperature graphs
- Print statistics (elapsed time, remaining time, filament usage)
- Layer progress tracking
- Z-height monitoring
- Auto-refresh capability
- Live status updates via MQTT

### 5. Settings & Manual Control
- Chamber light control
- Custom G-code command execution
- Printer settings configuration
- Real-time command feedback

### 6. Communication Logs
- Complete communication logging
- Log export functionality
- Timestamped entries
- MQTT message tracking

## What You Need

### Hardware
- Bambulab A1 Combo 3D Printer
- Computer (Windows, Mac, or Linux)
- WiFi network or Ethernet connection
- Both devices on the **same network**

### From Your Printer

You need 3 pieces of information from your printer's touchscreen:

1. **IP Address**
   - Location: Settings → Network → IP Address
   - Example: `192.168.1.100`

2. **Access Code** (8-digit code)
   - Location: Settings → WLAN → Access Code
   - Example: `12345678`
   - This is your printer's "password"

3. **Serial Number**
   - Location: Settings → Device → Serial Number
   - Or check the label on your printer
   - Example: `01S00A123456789`

## Installation

### Prerequisites

1. **R** (version 4.0 or higher)
   - Download from: https://cran.r-project.org/

2. **RStudio** (recommended)
   - Download from: https://www.rstudio.com/products/rstudio/download/

3. **Python** (version 3.7 or higher)
   - Download from: https://www.python.org/downloads/
   - **Important**: Check "Add Python to PATH" during installation

### Step 1: Install Python Dependencies

Open Command Prompt or Terminal and run:

```bash
pip install paho-mqtt
```

Or use the requirements file:

```bash
cd path/to/project/folder
pip install -r requirements.txt
```

### Step 2: Install R Packages

In R or RStudio console:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "DT",
  "plotly",
  "jsonlite"
))
```

### Step 3: Network Setup

1. **Connect printer to WiFi**:
   - On printer touchscreen: Settings → Network → WiFi
   - Connect to your network

2. **Get printer IP address**:
   - Settings → Network → IP Address
   - Write this down

3. **Get access code**:
   - Settings → WLAN → Access Code
   - Write this down (8 digits)

4. **Verify connectivity**:
   ```bash
   ping 192.168.1.100  # Replace with your printer's IP
   ```

5. **Check firewall** (if connection fails):
   - Ensure ports 8883 (MQTT) and 990 (FTP) are not blocked
   - Temporarily disable firewall to test if needed

## Usage Guide

### Initial Connection

1. **Launch the Application**
   ```r
   # In R or RStudio
   setwd("path/to/project/folder")
   shiny::runApp("app.R")
   ```

2. **Enter Printer Information**
   - Navigate to the "Connection" tab
   - Enter **IP Address** (e.g., 192.168.1.100)
   - Enter **Access Code** (8 digits from printer)
   - Enter **Serial Number** (from printer)
   - Click **"Connect to Printer"**

3. **Verify Connection**
   - Status should show green "Connected"
   - Printer information will display
   - Try "Get Temperature" or "Toggle Light" to test

### Uploading and Printing Files

1. **Upload G-code File**
   - Navigate to "File Management" tab
   - Click "Choose G-code File"
   - Select your .gcode or .3mf file
   - Click "Send to Printer" (uploads via FTP)

2. **Start a Print**
   - Navigate to "Print Control" tab
   - Select file from dropdown
   - Set desired temperatures
   - Click "Start Print"

3. **Monitor Progress**
   - Navigate to "Monitor" tab
   - View real-time temperature graphs
   - Check print statistics
   - Enable auto-refresh for continuous updates

### Manual Control

1. **Control Chamber Light**
   - Connection tab → "Toggle Light" button
   - Or use custom G-code: `M1400 S1` (on) or `M1400 S0` (off)

2. **Send Custom Commands**
   - Navigate to "Settings" tab → "Advanced Commands"
   - Enter G-code (e.g., `G28` for home)
   - Click "Send Command"

## Supported G-code Commands

Via MQTT, you can send:

- `G28` - Home all axes
- `G28 X` - Home X axis only
- `G28 Y` - Home Y axis only
- `G28 Z` - Home Z axis only
- `M104 S200` - Set hotend temperature to 200°C
- `M140 S60` - Set bed temperature to 60°C
- `M106 S255` - Set fan to maximum
- `M107` - Turn fan off
- `M1400 S1` - Turn chamber light on
- `M1400 S0` - Turn chamber light off

## Network Ports Used

- **Port 8883**: MQTT (printer control and status)
- **Port 990**: FTP (file uploads)
- **Port 6000**: Camera stream (optional)

Ensure these ports are not blocked by your firewall.

## Troubleshooting

### Cannot Connect to Printer

**Check:**
- [ ] Printer is powered on
- [ ] Printer is connected to WiFi (check printer display)
- [ ] Computer and printer are on the **same network**
- [ ] IP address is correct (it may change if printer restarts)
- [ ] Access code is exactly 8 digits
- [ ] Serial number is correct
- [ ] Firewall is not blocking ports 8883 or 990

**Test:**
```bash
# Ping the printer
ping 192.168.1.100

# Test with Python script
python bambulab_mqtt.py connect 192.168.1.100 12345678 01S00A123456789
```

### "Connection Timeout" Error

**Solutions:**
1. Verify printer IP address hasn't changed
2. Check WiFi connection on printer
3. Ensure both devices on same network (not guest network)
4. Restart printer and try again
5. Check router settings - ensure devices can communicate

### "Invalid Access Code" Error

**Solutions:**
1. Go to printer: Settings → WLAN → Access Code
2. Verify it's exactly 8 digits
3. Re-enter carefully (no spaces)

### Python Script Not Found

**Solutions:**
1. Ensure `bambulab_mqtt.py` is in the same folder as `app.R`
2. Check Python is installed: `python --version`
3. Check Python is in PATH

### File Upload Fails

**Solutions:**
1. Verify file is valid G-code or .3mf format
2. Check file size (very large files take time)
3. Ensure FTP port 990 is not blocked
4. Verify printer has storage space

### Temperature Not Updating

**Solutions:**
1. Enable "Auto-refresh" in Monitor tab
2. Click "Manual Refresh"
3. Check printer is responding (try toggle light)
4. Verify MQTT connection is active

## Network Configuration Tips

### Static IP Address (Recommended)

To prevent IP address from changing:

1. **Via Router**:
   - Log into your router
   - Find DHCP settings
   - Reserve IP for printer's MAC address

2. **Via Printer** (if supported):
   - Settings → Network → Advanced
   - Set static IP

### Finding Printer on Network

If you lost the IP address:

**Option 1**: Check printer display
- Settings → Network → IP Address

**Option 2**: Check router
- Log into router
- View connected devices
- Look for "Bambulab" or printer's hostname

**Option 3**: Network scanner
- Download "Advanced IP Scanner" (Windows)
- Scan your network range (e.g., 192.168.1.0/24)
- Look for devices on port 8883

## Safety Warnings

⚠️ **IMPORTANT:**

1. **Never leave printer unattended** during operation
2. **Monitor temperatures** - verify safe ranges
3. **Use proper ventilation** when printing
4. **Keep flammable materials away**
5. **Emergency stop**: Use "Stop Print" button immediately if needed
6. **Network security**: Keep access code private

## Technical Details

### Communication Protocol
- **Protocol**: MQTT over TLS
- **Port**: 8883 (secure MQTT)
- **Authentication**: Username + Access Code
- **Encryption**: TLS 1.2+

### File Transfer
- **Protocol**: FTP
- **Port**: 990
- **Authentication**: bblp + Access Code

### Supported File Formats
- `.gcode` - Standard G-code files
- `.gco` - G-code files
- `.3mf` - 3D Manufacturing Format (recommended)

### Temperature Limits
- **Hotend**: 0-300°C
- **Bed**: 0-120°C
- **Chamber**: Ambient monitoring

### Build Volume
- **X**: 256mm
- **Y**: 256mm
- **Z**: 256mm

## Known Limitations

1. **Network Dependency**: Requires stable WiFi connection
2. **Same Network**: Computer and printer must be on same network
3. **IP Changes**: Printer IP may change on reboot (use static IP)
4. **Camera**: Live camera feed not included in this version
5. **Cloud Features**: This is LAN-only, doesn't use Bambu Cloud

## Future Enhancements

- [ ] Live camera integration
- [ ] Print history database
- [ ] Multi-printer support
- [ ] Mobile responsive design
- [ ] Advanced slicer integration
- [ ] Filament usage tracking

## Project Files

- **app.R** - Main Shiny dashboard application
- **bambulab_mqtt.py** - Python MQTT communication script
- **requirements.txt** - Python dependencies
- **test_print.gcode** - Sample test print file
- **README.md** - This file
- **INSTALLATION.md** - Detailed setup guide
- **CONNECTION_GUIDE.md** - Network connection help

## Support & Resources

- **Bambulab Wiki**: https://wiki.bambulab.com/
- **Network Ports**: https://wiki.bambulab.com/en/general/printer-network-ports
- **Community Forum**: https://forum.bambulab.com/
- **API Documentation**: https://github.com/coelacant1/Bambu-Lab-Cloud-API

## Version History

### v2.0.0 (Current)
- **Network connection via MQTT**
- **WiFi/LAN support only**
- File upload via FTP
- Real-time MQTT monitoring
- Temperature tracking
- Print control features
- Communication logging

---

**Last Updated**: December 2024  
**Connection Type**: WiFi/LAN (MQTT + FTP)  
**Tested With**: Bambulab A1 Combo
