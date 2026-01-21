# Troubleshooting Connection Errors

## Error: "lexical error: invalid char in json text"

This error means the Python script output cannot be parsed. Here's how to fix it:

### Step 1: Test Your Python Setup

Run the test script first:

```bash
python test_setup.py
```

Or:

```bash
python3 test_setup.py
```

This will check:
- ✓ Python is installed and working
- ✓ paho-mqtt library is installed
- ✓ bambulab_mqtt.py file exists

### Step 2: Test Python Script Directly

Test the MQTT script manually from command line:

```bash
python bambulab_mqtt.py connect YOUR_IP YOUR_ACCESS_CODE YOUR_SERIAL
```

Example:
```bash
python bambulab_mqtt.py connect 192.168.1.100 12345678 01S00A123456789
```

**Expected output (success):**
```json
{"status": "connected", "message": "Successfully connected to printer"}
```

**Expected output (failure):**
```json
{"status": "error", "message": "Connection timeout"}
```

### Step 3: Common Issues and Fixes

#### Issue 1: Python Not Found

**Error:** `'python' is not recognized as an internal or external command`

**Fix (Windows):**
1. Reinstall Python from https://www.python.org/downloads/
2. **CRITICAL**: Check "Add Python to PATH" during installation
3. Restart your computer
4. Test: `python --version`

**Fix (Mac/Linux):**
```bash
# Use python3 instead
python3 --version

# Or create alias
alias python=python3
```

#### Issue 2: paho-mqtt Not Installed

**Error:** `ModuleNotFoundError: No module named 'paho'`

**Fix:**
```bash
pip install paho-mqtt
```

Or:
```bash
pip3 install paho-mqtt
```

Or with full path:
```bash
python -m pip install paho-mqtt
```

#### Issue 3: Script File Not Found

**Error:** `bambulab_mqtt.py not found`

**Fix:**
1. Verify all files are extracted from the zip
2. Navigate to the correct directory:
   ```bash
   cd C:\path\to\bambulab_controller
   ```
3. List files:
   ```bash
   dir  # Windows
   ls   # Mac/Linux
   ```
4. Ensure `bambulab_mqtt.py` is present

#### Issue 4: Wrong Network/Can't Reach Printer

**Error:** `{"status": "error", "message": "Connection timeout"}`

**Check:**
1. Printer is ON and connected to WiFi
2. Computer and printer on SAME network
3. IP address is correct

**Test connectivity:**
```bash
ping 192.168.1.100
```

Should see replies. If "Request timeout", network issue exists.

#### Issue 5: Wrong Access Code

**Error:** `{"status": "error", "message": "...authentication..."}`

**Check:**
1. On printer: Settings → WLAN → Access Code
2. Must be EXACTLY 8 digits
3. Re-enter carefully in app

### Step 4: Using the App's Test Button

In the R Shiny app:

1. Click **"Test Python Setup"** button
2. Check the Logs tab for detailed output
3. It will show:
   - Python version
   - Whether bambulab_mqtt.py exists
   - Whether paho-mqtt is installed
   - Current working directory

### Step 5: Running from Correct Directory

Make sure R is running from the correct directory:

**In R/RStudio:**
```r
# Check current directory
getwd()

# Should show path to your app folder
# If not, set it:
setwd("C:/path/to/bambulab_controller")

# List files to verify
list.files()
# Should see: app.R, bambulab_mqtt.py, etc.
```

### Step 6: Checking Python from R

Test if R can call Python:

**In R console:**
```r
# Test Python
system("python --version")

# Test script
system("python bambulab_mqtt.py")
# Should show usage instructions

# Test with your details
system("python bambulab_mqtt.py connect 192.168.1.100 12345678 01S00A123456789")
```

### Step 7: Windows-Specific Issues

#### Path with Spaces

If your path has spaces, use quotes:
```r
setwd("C:/Users/My Name/Desktop/bambulab_controller")
```

#### Script Execution Policy

If you get "script execution" errors:
```bash
# Run as Administrator
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Firewall Blocking

Temporarily disable Windows Firewall to test:
1. Windows Security → Firewall & network protection
2. Turn off for Private networks (temporarily)
3. Test connection
4. Turn back on
5. Add exception for Python

### Step 8: Mac/Linux-Specific Issues

#### Permission Denied

```bash
chmod +x bambulab_mqtt.py
chmod +x test_setup.py
```

#### Python vs Python3

On Mac/Linux, you might need to use `python3`:

**Update app.R:**
Find this line:
```r
python_cmd <- sprintf('python bambulab_mqtt.py connect "%s" "%s" "%s"',
```

Change to:
```r
python_cmd <- sprintf('python3 bambulab_mqtt.py connect "%s" "%s" "%s"',
```

### Detailed Debugging Steps

#### 1. Enable Maximum Logging

In R console while app is running:
```r
# Check the logs tab in the app after connecting
# Or view in R console
```

#### 2. Test MQTT Connection Manually

```python
# Create test file: test_mqtt.py
import paho.mqtt.client as mqtt
import ssl

ip = "192.168.1.100"
access_code = "12345678"

client = mqtt.Client()
client.username_pw_set("bblp", access_code)
client.tls_set(cert_reqs=ssl.CERT_NONE)
client.tls_insecure_set(True)

try:
    client.connect(ip, 8883, 60)
    print("Connected!")
except Exception as e:
    print(f"Failed: {e}")
```

Run:
```bash
python test_mqtt.py
```

### Getting More Help

If still having issues:

1. **Check Logs Tab** in the app for detailed error messages
2. **Run test_setup.py** and share the output
3. **Test Python script directly** from command line
4. **Verify network connectivity** with ping
5. **Check printer settings** on touchscreen

### Quick Checklist

Before reporting issues, verify:

- [ ] Python installed and in PATH
- [ ] paho-mqtt installed (`pip list | grep paho`)
- [ ] bambulab_mqtt.py in same folder as app.R
- [ ] R working directory is correct (`getwd()`)
- [ ] Printer is on and connected to WiFi
- [ ] Computer and printer on same network
- [ ] Can ping printer (`ping 192.168.1.100`)
- [ ] IP, Access Code, Serial Number are correct
- [ ] Access Code is exactly 8 digits
- [ ] Ports 8883 and 990 not blocked by firewall

---

**Still stuck?** 

Run this diagnostic and share the output:

```bash
# Run test
python test_setup.py > diagnostic.txt 2>&1

# Test connection
python bambulab_mqtt.py connect YOUR_IP YOUR_CODE YOUR_SERIAL >> diagnostic.txt 2>&1

# Check Python from R
```

Then in R:
```r
system("python --version")
getwd()
list.files()
```
