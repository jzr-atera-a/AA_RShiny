# QUICK FIX: "No module named 'paho'" Error

## The Problem
The Python that R is using doesn't have `paho-mqtt` installed.

## The Solution (Windows)

### Option 1: Run the Install Script (EASIEST)
1. Double-click `install_mqtt.bat`
2. Wait for it to finish
3. Press any key to close
4. Try the app again

### Option 2: Manual Installation
Open **Command Prompt** and run:
```cmd
python -m pip install paho-mqtt
```

### Option 3: If You Have Multiple Pythons
Find which Python R is using:

**In R/RStudio:**
```r
system("python --version")
system("where python")
```

Then install to that specific Python:
```cmd
"C:\Path\To\Python\python.exe" -m pip install paho-mqtt
```

## The Solution (Mac/Linux)

### Option 1: Run the Install Script
```bash
chmod +x install_mqtt.sh
./install_mqtt.sh
```

### Option 2: Manual Installation
```bash
python3 -m pip install paho-mqtt
```

## Verify Installation

After installing, verify it worked:

**Command Prompt/Terminal:**
```bash
python -c "import paho.mqtt.client; print('SUCCESS!')"
```

Should print: `SUCCESS!`

## If It Still Doesn't Work

### Check Python Path in R
**In R console:**
```r
# See which Python R is calling
Sys.which("python")

# Or
system("python --version")
```

### Install for All Pythons (Windows)
```cmd
py -m pip install paho-mqtt
python -m pip install paho-mqtt
python3 -m pip install paho-mqtt
```

### Install for All Pythons (Mac/Linux)
```bash
python -m pip install paho-mqtt
python3 -m pip install paho-mqtt
```

## Alternative: Update App to Use Specific Python

If you know your Python path, you can update `app.R`:

Find this line (around line 870):
```r
python_cmd <- sprintf('python bambulab_mqtt.py connect "%s" "%s" "%s"',
```

Change to (with YOUR Python path):
```r
python_cmd <- sprintf('"C:/Python311/python.exe" bambulab_mqtt.py connect "%s" "%s" "%s"',
```

## Common Python Paths

**Windows:**
- `C:\Python311\python.exe`
- `C:\Users\YourName\AppData\Local\Programs\Python\Python311\python.exe`
- `C:\Program Files\Python311\python.exe`

**Mac:**
- `/usr/local/bin/python3`
- `/opt/homebrew/bin/python3`

**Linux:**
- `/usr/bin/python3`

## Still Having Issues?

### Check All Python Installations
**Windows:**
```cmd
where python
py --list
```

**Mac/Linux:**
```bash
which python
which python3
```

### Install to User Directory
```bash
pip install --user paho-mqtt
```

### Upgrade pip First
```bash
python -m pip install --upgrade pip
python -m pip install paho-mqtt
```

## Quick Test After Installing

Run this in Command Prompt/Terminal:
```bash
python bambulab_mqtt.py connect 192.168.1.100 12345678 01S00A123456789
```
(Use your actual IP, access code, and serial)

Should see: `{"status": "connected", ...}` or an error about connection, NOT about paho module.

---

**TL;DR:** 
1. Double-click `install_mqtt.bat` (Windows) 
2. Or run: `python -m pip install paho-mqtt`
3. Try app again
