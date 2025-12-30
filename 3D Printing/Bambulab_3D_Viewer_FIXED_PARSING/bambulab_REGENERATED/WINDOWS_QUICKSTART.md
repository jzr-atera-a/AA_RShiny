# WINDOWS QUICK START

## Step 1: Install paho-mqtt

Open **Command Prompt** and run:
```cmd
python -m pip install paho-mqtt
```

## Step 2: Test Connection

### EASIEST WAY (No batch file needed):

Open **Command Prompt**, navigate to this folder, and run:
```cmd
python test_interactive.py
```

Then enter:
- Your printer's IP address
- Your 8-digit access code
- Your serial number

### Alternative (if you prefer):

Run this command (replace with YOUR details):
```cmd
python test_mqtt_connection.py 192.168.100.13 YOUR_ACCESS_CODE YOUR_SERIAL
```

Example:
```cmd
python test_mqtt_connection.py 192.168.100.13 12345678 01S00A123456789
```

## Step 3: Interpret Results

**If you see "✓✓✓ CONNECTION SUCCESSFUL! ✓✓✓"**
- Your credentials work!
- The R Shiny app should work
- If app still fails, it's an R/Python issue

**If you see "✗ Bad username or password"**
- Your access code is WRONG
- Go to printer: Settings → WLAN → Access Code
- Must be EXACTLY 8 digits

**If you see "✗ Port 8883 is CLOSED"**
- Windows Firewall is blocking it
- Or antivirus is blocking it
- Or printer's MQTT service isn't running

## Step 4: Run the R Shiny App

If the test succeeds, run the app:

1. Open RStudio
2. Set working directory:
   ```r
   setwd("C:/path/to/this/folder")
   ```
3. Run:
   ```r
   shiny::runApp("app.R")
   ```

## Common Windows Issues

### Python Command Not Found

**Fix:**
```cmd
# Try python3 instead
python3 -m pip install paho-mqtt
python3 test_interactive.py

# Or use py launcher
py -m pip install paho-mqtt
py test_interactive.py
```

### Permission Denied

**Fix:**
- Run Command Prompt as Administrator
- Right-click Command Prompt → "Run as administrator"

### Firewall Blocking

**Fix:**
1. Windows Security → Firewall & network protection
2. Advanced settings
3. Inbound Rules → New Rule
4. Port → TCP → Specific ports: 8883
5. Allow the connection
6. Name it "Bambulab MQTT"

**Or temporarily disable:**
1. Windows Security → Firewall
2. Turn off for Private networks
3. Test connection
4. Turn back on

### Batch File Issues

Don't use the .bat file if it causes problems. Just use:
```cmd
python test_interactive.py
```

It's easier anyway!

## Getting Printer Info

### IP Address:
1. Printer touchscreen
2. Settings (gear icon)
3. Network
4. Look for "IP Address"
5. Example: 192.168.100.13

### Access Code:
1. Printer touchscreen
2. Settings
3. WLAN
4. Access Code (8 digits)
5. Example: 12345678

### Serial Number:
1. Printer touchscreen
2. Settings
3. Device
4. Serial Number
5. Example: 01S00A123456789

Or check the label on your printer.

## Still Having Issues?

### Test 1: Can you ping?
```cmd
ping 192.168.100.13
```
Should see replies. If not, network problem.

### Test 2: Is Python working?
```cmd
python --version
```
Should show Python 3.x

### Test 3: Is paho-mqtt installed?
```cmd
python -c "import paho.mqtt.client; print('OK')"
```
Should print "OK"

### Test 4: Run diagnostic
```cmd
python diagnose_network.py 192.168.100.13
```

## Quick Commands Reference

```cmd
# Install MQTT library
python -m pip install paho-mqtt

# Test connection (interactive)
python test_interactive.py

# Test connection (direct)
python test_mqtt_connection.py IP ACCESS_CODE SERIAL

# Check network
python diagnose_network.py IP

# Ping printer
ping 192.168.100.13
```

## Summary

1. Install paho-mqtt
2. Run `python test_interactive.py`
3. Enter your printer details
4. See if connection works
5. If yes, use R Shiny app
6. If no, fix the specific error shown

**Most common issue: Wrong access code!**

Check it on the printer screen RIGHT NOW before testing!
