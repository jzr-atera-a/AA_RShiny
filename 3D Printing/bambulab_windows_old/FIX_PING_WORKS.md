# Fix: Ping Works But Connection Fails

## Your Situation

✓ Ping works (network is fine)  
✗ App connection fails  

This means the **MQTT port (8883)** is the problem, not basic network connectivity.

## Quick Test

Run this to test the MQTT connection directly:

### Option 1: Use the test script
```cmd
python test_mqtt_connection.py 192.168.100.13 YOUR_ACCESS_CODE YOUR_SERIAL
```

### Option 2: Double-click
`test_connection.bat` and enter your details when prompted

## Most Likely Causes

### 1. Wrong Access Code (MOST COMMON!)

**Symptom:** Connection fails with authentication error

**Fix:**
1. On printer: Settings → WLAN → Access Code
2. Write down ALL 8 digits exactly
3. Re-enter in app (no spaces before/after)

**Common mistakes:**
- Mixing up similar digits: 0 vs O, 1 vs l, 5 vs S
- Missing a digit (only 7 digits)
- Extra spaces

### 2. Firewall Blocking Port 8883

**Symptom:** Connection timeout, port unreachable

**Fix:**

**Windows Firewall:**
1. Windows Security → Firewall & network protection
2. Advanced settings
3. Inbound Rules → New Rule
4. Port → TCP → 8883
5. Allow the connection
6. Apply to all profiles

**Or temporarily disable to test:**
1. Windows Security → Firewall
2. Turn off Private network firewall
3. Test connection
4. Turn back on if it works
5. Add proper exception

### 3. Antivirus Blocking

**Symptom:** Connection fails, port blocked

**Fix:**
1. Temporarily disable antivirus
2. Test connection
3. If works, add Python to antivirus exceptions
4. Re-enable antivirus

### 4. Printer MQTT Service Not Running

**Symptom:** Port 8883 closed or unreachable

**Fix:**
1. Restart the printer (power cycle)
2. Wait for it to fully boot
3. Try connection again

### 5. Wrong Serial Number

**Symptom:** Authentication or connection error

**Fix:**
1. Check printer: Settings → Device → Serial Number
2. Or check label on printer
3. Must match exactly (case-sensitive)

## Step-by-Step Diagnosis

### Step 1: Test Port 8883 Specifically

**Windows:**
```cmd
telnet 192.168.100.13 8883
```

If you get a blank screen or connection, port is open ✓  
If you get "Could not open connection", port is blocked ✗

**If telnet not available:**
```cmd
# Enable telnet
dism /online /Enable-Feature /FeatureName:TelnetClient
```

### Step 2: Run Full MQTT Test

```cmd
python test_mqtt_connection.py 192.168.100.13 YOUR_CODE YOUR_SERIAL
```

This will tell you:
- ✓ Port 8883 is open
- ✓ MQTT connection works
- ✓ Credentials are correct

OR specific error about what's wrong.

### Step 3: Check Printer Logs

Some Bambulab printers have logs showing connection attempts:
1. Settings → System
2. Look for logs or diagnostics
3. Check for connection refused messages

## If Test Script Works But App Doesn't

If `test_mqtt_connection.py` succeeds but the R app fails, the issue is with R calling Python.

### Check Working Directory in R

```r
getwd()  # Should show folder with bambulab_mqtt.py
list.files()  # Should show bambulab_mqtt.py
```

### Check R Can Run Python Script

```r
# Test basic script
system("python --version")

# Test MQTT script directly
system('python bambulab_mqtt.py connect 192.168.100.13 YOUR_CODE YOUR_SERIAL')
```

### Check for Path/Quoting Issues

If IP has special characters or the path has spaces, it might fail.

Try updating app.R line ~870:
```r
python_cmd <- sprintf('python bambulab_mqtt.py connect "%s" "%s" "%s"',
```

Make sure quotes are around each parameter.

## Advanced Troubleshooting

### Check What's Listening on Port 8883

**Windows:**
```cmd
netstat -an | findstr 8883
```

Should show printer IP listening on 8883.

### Wireshark Capture

If you have Wireshark:
1. Start capture on your WiFi interface
2. Filter: `tcp.port == 8883`
3. Try connecting
4. Look for:
   - SYN sent ✓
   - SYN-ACK received ✓
   - Connection established ✓
   - If no SYN-ACK, port is blocked

### Test with Different Tool

Try connecting with MQTT Explorer or MQTT.fx:
- Host: 192.168.100.13
- Port: 8883
- Username: bblp
- Password: YOUR_ACCESS_CODE
- Enable SSL/TLS, disable certificate verification

If this works, Python/R setup is the issue.

## Quick Checklist

Before asking for more help:

- [ ] Can ping printer (you confirmed yes ✓)
- [ ] Verified Access Code on printer (8 digits exactly)
- [ ] Verified Serial Number on printer
- [ ] Tried `test_mqtt_connection.py` script
- [ ] Checked Windows Firewall for port 8883
- [ ] Temporarily disabled antivirus to test
- [ ] Restarted printer
- [ ] Checked Logs tab in R app for specific error
- [ ] Tried running Python command directly in cmd

## Most Likely Fix

**90% chance: Your access code is wrong or has a typo.**

Go to printer right now:
1. Settings → WLAN
2. Look at Access Code
3. Write it down on paper
4. Enter it EXACTLY in the app

Try again!

---

**Next Steps:**

1. Run: `test_connection.bat`
2. Enter your details carefully
3. See what error you get
4. Post the exact error message
