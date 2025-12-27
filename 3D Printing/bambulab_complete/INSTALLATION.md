# Installation & Setup Guide
## Bambulab A1 Combo - WiFi/LAN Network Connection

Complete setup guide for the 3D printer control dashboard using **WiFi/LAN connection only**.

## ⚠️ Important: Network Connection Only

This application connects via **WiFi/LAN** using **MQTT protocol**, NOT USB. Ensure your printer and computer are on the same network.

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Step-by-Step Installation](#step-by-step-installation)
3. [Getting Printer Network Information](#getting-printer-network-information)
4. [Running the Application](#running-the-application)
5. [Troubleshooting](#troubleshooting)

## System Requirements

### Hardware
- **Computer**: Windows 10/11, macOS, or Linux
- **RAM**: Minimum 4GB (8GB recommended)
- **Network**: WiFi or Ethernet connection
- **Printer**: Bambulab A1 Combo 3D Printer (connected to same network)

### Software
- **R**: Version 4.0.0 or higher
- **Python**: Version 3.7 or higher
- **Network**: Both devices must be on the same WiFi/LAN

## Step-by-Step Installation

### Part 1: Install R and RStudio

#### 1.1 Install R

**Windows:**
1. Visit: https://cran.r-project.org/bin/windows/base/
2. Download "R 4.x.x for Windows"
3. Run installer with default settings

**macOS:**
1. Visit: https://cran.r-project.org/bin/macosx/
2. Download appropriate version for your macOS
3. Run .pkg installer

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install r-base r-base-dev
```

#### 1.2 Install RStudio (Recommended)

1. Visit: https://posit.co/download/rstudio-desktop/
2. Download for your operating system
3. Run installer with default settings

### Part 2: Install R Packages

Open RStudio (or R console) and run:

```r
# Install required packages
install.packages("shiny")
install.packages("shinydashboard")
install.packages("DT")
install.packages("plotly")
install.packages("jsonlite")
```

Wait for all packages to install successfully.

### Part 3: Install Python

#### 3.1 Install Python

**Windows:**
1. Visit: https://www.python.org/downloads/
2. Download Python 3.11 or later
3. **CRITICAL**: Check "Add Python to PATH" during installation
4. Click "Install Now"

**macOS:**
```bash
# Using Homebrew
brew install python3
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install python3 python3-pip
```

#### 3.2 Verify Python Installation

Open Terminal/Command Prompt:

```bash
python --version
# or
python3 --version
```

Should show: `Python 3.x.x`

#### 3.3 Install Python MQTT Library

**Windows Command Prompt:**
```bash
pip install paho-mqtt
```

**macOS/Linux Terminal:**
```bash
pip3 install paho-mqtt
```

Or navigate to project folder and use requirements file:
```bash
cd path/to/project/folder
pip install -r requirements.txt
```

### Part 4: Network Setup

#### 4.1 Connect Printer to WiFi

1. On printer touchscreen: **Settings → Network**
2. Select your WiFi network
3. Enter WiFi password
4. Wait for connection confirmation

#### 4.2 Get Printer Information

You need 3 pieces of information:

**1. IP Address:**
- Printer touchscreen: **Settings → Network → IP Address**
- Write this down (e.g., `192.168.1.100`)

**2. Access Code (8 digits):**
- Printer touchscreen: **Settings → WLAN → Access Code**
- Write this down (e.g., `12345678`)
- This is like a password for your printer

**3. Serial Number:**
- Printer touchscreen: **Settings → Device → Serial Number**
- OR check the label on your printer
- Write this down (e.g., `01S00A123456789`)

#### 4.3 Verify Network Connectivity

Test that your computer can reach the printer:

**Windows Command Prompt:**
```bash
ping 192.168.1.100
```

**macOS/Linux Terminal:**
```bash
ping 192.168.1.100
```

Replace `192.168.1.100` with your printer's actual IP.

You should see replies. If you get "Request timeout", see troubleshooting.

### Part 5: Download and Extract Application

1. Download the `bambulab_controller.zip` file
2. Extract to a folder (e.g., `C:\BambulabController\` or `~/BambulabController/`)
3. Verify these files are present:
   - `app.R`
   - `bambulab_mqtt.py`
   - `requirements.txt`
   - `test_print.gcode`
   - `README.md`
   - `INSTALLATION.md`
   - `CONNECTION_GUIDE.md`

## Getting Printer Network Information

### Step-by-Step Guide

1. **Turn on your Bambulab A1 printer**

2. **Navigate to Settings:**
   - Tap the settings icon on touchscreen

3. **Get IP Address:**
   - Go to: **Network**
   - Find: **IP Address**
   - Example: `192.168.1.100`
   - **Write this down**

4. **Get Access Code:**
   - Go to: **WLAN**
   - Find: **Access Code**
   - Example: `12345678` (exactly 8 digits)
   - **Write this down** (keep it private!)

5. **Get Serial Number:**
   - Go to: **Device**
   - Find: **Serial Number**
   - Example: `01S00A123456789`
   - OR look at the label on your printer
   - **Write this down**

### Important Notes:

- **IP Address may change** if printer reconnects to WiFi
- Consider setting a **static IP** in your router settings
- **Access Code** is like a password - keep it secure
- Both computer and printer must be on **same network** (not guest WiFi)

## Running the Application

### Method 1: Using RStudio (Recommended)

1. **Open RStudio**

2. **Set Working Directory:**
   ```r
   setwd("C:/BambulabController")  # Windows
   # or
   setwd("~/BambulabController")   # macOS/Linux
   ```

3. **Run the Application:**
   ```r
   shiny::runApp("app.R")
   ```

4. **Application Opens:**
   - Dashboard opens in your web browser
   - Or go to the address shown (e.g., `http://127.0.0.1:xxxx`)

### Method 2: Using R Console

1. **Open R Console**

2. **Navigate and Run:**
   ```r
   setwd("C:/BambulabController")
   library(shiny)
   runApp("app.R")
   ```

### Method 3: Command Line

**Windows:**
```batch
cd C:\BambulabController
Rscript -e "shiny::runApp('app.R')"
```

**macOS/Linux:**
```bash
cd ~/BambulabController
Rscript -e "shiny::runApp('app.R')"
```

## First-Time Connection

### 1. Launch Application

Run using one of the methods above.

### 2. Enter Printer Information

1. Navigate to **"Connection"** tab
2. Enter **IP Address** (from printer)
3. Enter **Access Code** (8 digits from printer)
4. Enter **Serial Number** (from printer)
5. Click **"Connect to Printer"**

### 3. Verify Connection

- Connection status should show **green "Connected"**
- Printer information will display
- Try clicking **"Toggle Light"** to test
- Check **"Get Temperature"** button

### 4. Test Upload (Optional)

1. Go to **"File Management"** tab
2. Click **"Choose G-code File"**
3. Select `test_print.gcode` (included)
4. Click **"Send to Printer"**

## Troubleshooting

### Issue: Cannot Find Printer IP

**Solutions:**

**Option 1** - Check Printer Display:
- Settings → Network → IP Address

**Option 2** - Check Router:
1. Log into your router (usually 192.168.1.1 or 192.168.0.1)
2. View connected devices/DHCP clients
3. Look for "Bambulab" or similar

**Option 3** - Network Scanner (Windows):
1. Download "Advanced IP Scanner"
2. Scan your network (e.g., 192.168.1.0-255)
3. Look for device on port 8883

### Issue: "Connection Timeout"

**Check:**
- [ ] Printer is powered on
- [ ] Printer WiFi is connected (check display)
- [ ] Computer and printer on **same network**
- [ ] Not using guest WiFi network
- [ ] IP address is correct

**Test:**
```bash
ping 192.168.1.100
```

If ping fails, network issue exists.

### Issue: Python Not Found

**Windows:**
```bash
# Check if Python is installed
python --version

# If not found, check:
where python
```

Re-install Python with "Add to PATH" checked.

**macOS/Linux:**
```bash
# Check Python
python3 --version

# If not found:
which python3
```

### Issue: "Access Denied" or "Invalid Credentials"

**Solutions:**
1. Verify Access Code is exactly 8 digits
2. Re-check on printer: Settings → WLAN → Access Code
3. No spaces before/after when entering
4. Access Code is case-sensitive (if letters)

### Issue: Firewall Blocking Connection

**Windows:**
1. Windows Security → Firewall & network protection
2. Allow an app through firewall
3. Add Python and R to allowed apps
4. Ensure private network is allowed

**Temporary Test:**
- Temporarily disable firewall
- Try connection
- If works, add firewall exception
- Re-enable firewall

### Issue: Ports Blocked

Required ports:
- **8883** - MQTT (main communication)
- **990** - FTP (file uploads)

**Check ports are open:**

**Windows:**
```bash
netstat -an | findstr "8883"
```

**macOS/Linux:**
```bash
netstat -an | grep 8883
```

### Issue: R Packages Won't Install

**Solution 1** - Run as Administrator:
- Close R/RStudio
- Right-click → "Run as administrator"
- Try installing packages again

**Solution 2** - Choose CRAN Mirror:
```r
chooseCRANmirror()
# Select a mirror close to you
install.packages("shiny")
```

**Solution 3** - Update R:
- Download latest R version
- Reinstall

### Issue: Application Won't Load

**Check:**
1. All R packages installed:
   ```r
   library(shiny)
   library(shinydashboard)
   library(DT)
   library(plotly)
   library(jsonlite)
   ```

2. Python script present:
   - `bambulab_mqtt.py` in same folder as `app.R`

3. Working directory correct:
   ```r
   getwd()  # Should show app folder
   ```

### Issue: Different Network/Subnet

If computer is on `192.168.1.x` and printer on `192.168.2.x`:

**Solutions:**
1. Reconnect printer to same network as computer
2. Configure router to bridge subnets
3. Use single network for both devices

## Advanced Configuration

### Setting Static IP for Printer

**Via Router (Recommended):**
1. Log into router admin panel
2. Find DHCP settings or Address Reservation
3. Find printer by MAC address
4. Reserve/assign a static IP (e.g., 192.168.1.100)

**Benefits:**
- IP won't change on restart
- Easier to remember
- More reliable connection

### Opening Firewall Ports

**Windows Firewall:**
```
1. Windows Security → Firewall
2. Advanced settings
3. Inbound Rules → New Rule
4. Port → TCP → 8883, 990
5. Allow the connection
6. Apply to all profiles
```

### Testing MQTT Connection Manually

Using the Python script directly:

```bash
# Test connection
python bambulab_mqtt.py connect 192.168.1.100 12345678 01S00A123456789

# Get temperatures
python bambulab_mqtt.py temps 192.168.1.100 12345678 01S00A123456789

# Toggle light
python bambulab_mqtt.py light 192.168.1.100 12345678 01S00A123456789 on
```

## Network Requirements Checklist

Before connecting, verify:

- [ ] Printer connected to WiFi
- [ ] Computer on same WiFi network
- [ ] Know printer IP address
- [ ] Know 8-digit access code
- [ ] Know serial number
- [ ] Can ping printer successfully
- [ ] Ports 8883 and 990 not blocked
- [ ] Python installed with paho-mqtt
- [ ] R packages installed
- [ ] bambulab_mqtt.py in app folder

## Getting Help

### Check These Resources:

1. **README.md** - Features and usage
2. **CONNECTION_GUIDE.md** - Detailed connection help
3. **Bambulab Wiki**: https://wiki.bambulab.com/
4. **Community Forum**: https://forum.bambulab.com/

### Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "Connection timeout" | Can't reach printer | Check IP, WiFi, network |
| "Invalid credentials" | Wrong access code | Verify 8-digit code from printer |
| "Python not found" | Python not in PATH | Reinstall Python with PATH option |
| "Package not found" | Missing R package | Install required packages |
| "Port already in use" | Another app using port | Close other apps, restart R |

## Next Steps

Once installed and connected:

1. ✅ Test basic connection
2. ✅ Toggle chamber light
3. ✅ Check temperatures
4. ✅ Upload test file
5. ✅ Try printing test file
6. ✅ Explore monitoring features
7. ✅ Customize to your needs

## Support

For issues not covered:
- Review CONNECTION_GUIDE.md
- Check Bambulab community forums
- Verify network configuration
- Test with Python script directly

---

**Last Updated**: December 2024  
**Connection Type**: WiFi/LAN (MQTT)  
**Tested With**: Bambulab A1 Combo, Windows/macOS/Linux
