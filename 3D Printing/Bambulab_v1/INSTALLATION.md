# Installation & Setup Guide
## Bambulab A1 Combo 3D Printer Control Dashboard

This guide will walk you through the complete setup process for the printer control dashboard.

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Step-by-Step Installation](#step-by-step-installation)
3. [Configuring the Printer Connection](#configuring-the-printer-connection)
4. [Running the Application](#running-the-application)
5. [Troubleshooting](#troubleshooting)

## System Requirements

### Hardware
- **Computer**: Windows 10 or Windows 11 PC
- **RAM**: Minimum 4GB (8GB recommended)
- **Processor**: Intel Core i3 or equivalent (i5 recommended)
- **USB Port**: USB 2.0 or higher
- **Printer**: Bambulab A1 Combo 3D Printer

### Software
- **Operating System**: Windows 10/11 (64-bit)
- **R**: Version 4.0.0 or higher
- **Python**: Version 3.7 or higher (optional, for enhanced serial communication)
- **USB Drivers**: Bambulab printer drivers

## Step-by-Step Installation

### Part 1: Install R and RStudio

#### 1.1 Install R

1. **Download R**:
   - Visit: https://cran.r-project.org/bin/windows/base/
   - Click "Download R 4.x.x for Windows"
   - Run the downloaded installer

2. **Install R**:
   - Accept default settings
   - Complete the installation wizard
   - Click "Finish"

#### 1.2 Install RStudio (Recommended)

1. **Download RStudio**:
   - Visit: https://posit.co/download/rstudio-desktop/
   - Click "Download RStudio Desktop for Windows"
   - Run the downloaded installer

2. **Install RStudio**:
   - Accept default settings
   - Complete the installation
   - Launch RStudio

### Part 2: Install R Packages

#### 2.1 Open R or RStudio

Launch RStudio (or R if not using RStudio)

#### 2.2 Install Required Packages

Copy and paste the following commands into the R console:

```r
# Install CRAN packages
install.packages("shiny")
install.packages("shinydashboard")
install.packages("DT")
install.packages("plotly")

# For serial communication (optional - may require Rtools)
install.packages("serial")
```

**Note**: If you encounter errors installing the `serial` package, you can skip it and use the Python helper script instead.

#### 2.3 Install Rtools (If Needed)

If the `serial` package fails to install:

1. Download Rtools from: https://cran.r-project.org/bin/windows/Rtools/
2. Run the installer with default settings
3. Retry installing the `serial` package

### Part 3: Install Python (Optional but Recommended)

For more robust serial communication:

#### 3.1 Install Python

1. **Download Python**:
   - Visit: https://www.python.org/downloads/
   - Download Python 3.11 or later
   - Run the installer

2. **During Installation**:
   - ✅ **IMPORTANT**: Check "Add Python to PATH"
   - Click "Install Now"
   - Wait for completion

#### 3.2 Verify Python Installation

Open Command Prompt (Win + R, type `cmd`, press Enter):

```bash
python --version
```

You should see: `Python 3.x.x`

#### 3.3 Install Python Packages

In Command Prompt:

```bash
pip install pyserial
```

Or using the requirements file:

```bash
cd path\to\project\folder
pip install -r requirements.txt
```

### Part 4: Install USB Drivers

#### 4.1 Automatic Installation

1. Connect your Bambulab A1 Combo to your PC via USB
2. Windows should automatically install drivers
3. Wait for the "Device is ready to use" notification

#### 4.2 Manual Installation (If Needed)

1. Visit: https://wiki.bambulab.com/
2. Navigate to Downloads → Drivers
3. Download the appropriate driver for Windows
4. Run the installer
5. Restart your computer

#### 4.3 Verify Driver Installation

1. Press `Win + X`, select "Device Manager"
2. Expand "Ports (COM & LPT)"
3. Look for your printer (e.g., "USB Serial Port (COM3)")
4. Note the COM port number

### Part 5: Download the Dashboard Application

#### 5.1 Download Files

Download the following files to a folder on your computer:
- `app.R` (main application)
- `bambulab_serial.py` (Python helper script)
- `requirements.txt` (Python dependencies)
- `README.md` (documentation)
- `INSTALLATION.md` (this file)

#### 5.2 Organize Files

Create a project folder structure:

```
C:\BambulabController\
├── app.R
├── bambulab_serial.py
├── requirements.txt
├── README.md
└── INSTALLATION.md
```

## Configuring the Printer Connection

### Step 1: Connect the Printer

1. **Power on** your Bambulab A1 Combo printer
2. **Connect USB cable** from printer to PC
3. **Wait** for Windows to recognize the device (notification will appear)

### Step 2: Identify COM Port

**Method 1: Device Manager**

1. Press `Win + X`, select "Device Manager"
2. Expand "Ports (COM & LPT)"
3. Find your printer (typically "USB Serial Port (COMx)")
4. Note the COM port number (e.g., COM3, COM5, COM7)

**Method 2: In the Application**

The dashboard has a "Scan Ports" feature that will detect available COM ports automatically.

### Step 3: Configure Baud Rate

For Bambulab A1 Combo, the recommended baud rate is:
- **115200** (default)

Alternative rates to try if connection fails:
- 250000
- 9600

## Running the Application

### Method 1: Using RStudio (Recommended)

1. **Open RStudio**

2. **Set Working Directory**:
   ```r
   setwd("C:/BambulabController")  # Adjust path as needed
   ```

3. **Run the Application**:
   ```r
   shiny::runApp("app.R")
   ```

4. **Access the Dashboard**:
   - The app will open in your default web browser
   - Alternatively, note the local address (e.g., http://127.0.0.1:xxxx)

### Method 2: Using R Console

1. **Open R Console**

2. **Navigate to Project Folder**:
   ```r
   setwd("C:/BambulabController")
   ```

3. **Run the App**:
   ```r
   library(shiny)
   runApp("app.R")
   ```

### Method 3: Double-Click (Advanced)

Create a batch file `run_app.bat`:

```batch
@echo off
cd /d "C:\BambulabController"
"C:\Program Files\R\R-4.x.x\bin\R.exe" -e "shiny::runApp('app.R')"
pause
```

Double-click the batch file to launch the app.

## First-Time Setup Checklist

After launching the application:

### 1. Connection Tab

- [ ] Click "Scan Ports"
- [ ] Select your printer's COM port
- [ ] Set baud rate to 115200
- [ ] Click "Connect to Printer"
- [ ] Verify green connection status

### 2. Test Basic Commands

- [ ] Click "Home All Axes" (printer should move to home position)
- [ ] Click "Get Temperature" (should display current temps)
- [ ] Navigate to Monitor tab to see real-time data

### 3. Upload a Test File

- [ ] Navigate to "File Management" tab
- [ ] Click "Choose G-code File"
- [ ] Select a small test file
- [ ] Click "Send to Printer"
- [ ] Wait for transfer confirmation

### 4. Test Print (Optional)

- [ ] Navigate to "Print Control" tab
- [ ] Select uploaded file
- [ ] Set appropriate temperatures
- [ ] Click "Start Print"
- [ ] Monitor progress in "Monitor" tab

## Troubleshooting

### Issue: R Packages Won't Install

**Solution**:
1. Close RStudio/R completely
2. Run RStudio as Administrator (right-click → Run as administrator)
3. Try installing packages again
4. If still failing, install Rtools

### Issue: COM Port Not Found

**Solutions**:
1. Check physical USB connection
2. Try different USB port
3. Verify printer is powered on
4. Check Device Manager for driver issues
5. Reinstall USB drivers

### Issue: Connection Fails

**Try these steps**:
1. Disconnect and reconnect USB cable
2. Try different baud rates (250000, 9600)
3. Close any other software using the COM port (Bambu Studio, Cura, etc.)
4. Restart the printer
5. Restart your computer

### Issue: "Permission Denied" on COM Port

**Solutions**:
1. Close all other applications that might use the printer
2. Run RStudio as Administrator
3. Check Windows Firewall settings
4. Verify user has permissions to access COM ports

### Issue: Application Crashes

**Solutions**:
1. Check R console for error messages
2. Ensure all packages are installed correctly
3. Update R to latest version
4. Clear R workspace: `rm(list=ls())`
5. Restart R session

### Issue: Python Script Not Working

**Solutions**:
1. Verify Python is in PATH:
   ```bash
   python --version
   ```
2. Reinstall pyserial:
   ```bash
   pip install --upgrade pyserial
   ```
3. Check Python script permissions
4. Run Command Prompt as Administrator

### Issue: Slow Performance

**Solutions**:
1. Disable auto-refresh in Monitor tab
2. Reduce refresh frequency
3. Close unnecessary browser tabs
4. Increase R memory limit:
   ```r
   memory.limit(size=8000)  # Set to 8GB
   ```

## Advanced Configuration

### Customizing the Dashboard

The CSS styling can be modified in `app.R`. Look for the `tags$style(HTML('...'))` section.

### Adding Custom Commands

To add custom G-code commands, modify the server logic in `app.R` to include new command buttons.

### Changing Port Range for Scanning

In `app.R`, locate the port scanning loop and adjust the range (default: COM1-COM20).

## Getting Help

### Resources

1. **R Shiny Documentation**: https://shiny.rstudio.com/
2. **Bambulab Wiki**: https://wiki.bambulab.com/
3. **PySerial Documentation**: https://pyserial.readthedocs.io/

### Common Error Messages

| Error | Likely Cause | Solution |
|-------|--------------|----------|
| "Port not found" | Incorrect COM port | Scan ports, verify in Device Manager |
| "Access denied" | Port in use | Close other applications |
| "Timeout" | No response from printer | Check connection, try different baud rate |
| "Package not found" | Missing R package | Install required packages |

## Next Steps

Once installed and running:

1. Read the [README.md](README.md) for usage instructions
2. Practice with the manual controls
3. Upload and print a test file
4. Explore the monitoring features
5. Customize settings to your preferences

## Support

For issues not covered in this guide:
1. Check the GitHub issues page
2. Review Bambulab community forums
3. Consult R Shiny community resources

---

**Last Updated**: December 2024
**Tested On**: Windows 10/11, R 4.3.x, Python 3.11
