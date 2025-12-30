# FIX: "[Errno 11001] getaddrinfo failed"

## What This Error Means

This error means Python **cannot find or reach your printer's IP address**. It's a network connectivity issue, not a code problem.

## Quick Fixes (Try in Order)

### Fix 1: Verify Printer IP Address (MOST COMMON)

**The IP address may have changed!**

1. On printer touchscreen: **Settings → Network → IP Address**
2. Write down the EXACT IP (e.g., `192.168.1.100`)
3. Enter this IP in the app (not what you think it is)
4. Try connecting again

### Fix 2: Check Printer is Connected to WiFi

1. On printer display, check WiFi icon
2. Settings → Network
3. Make sure WiFi is **connected** (not just "available")
4. If disconnected, reconnect to your WiFi

### Fix 3: Verify Same Network

**Computer and printer MUST be on the same WiFi network**

Check:
- Not on guest WiFi
- Not on different network (e.g., 2.4GHz vs 5GHz)
- Both on same router

**Test:** Can you ping the printer?
```cmd
ping 192.168.1.100
```
(Replace with your printer's IP)

Should see "Reply from..." - if you see "Request timeout", not on same network.

### Fix 4: Run Network Diagnostic

```cmd
python diagnose_network.py 192.168.1.100
```
(Replace with your printer's IP)

This will test:
- ✓ IP format is valid
- ✓ Can resolve the address
- ✓ Can reach port 8883
- ✓ Network configuration

## Common Causes

### Cause 1: IP Address Changed

**Why:** Printers get dynamic IPs that change when restarted

**Fix:** 
1. Check printer for current IP
2. Update in app
3. **OR** Set static IP in router (recommended)

### Cause 2: Printer is Off/Sleeping

**Why:** Printer went to sleep or was turned off

**Fix:**
1. Wake up printer (touch screen)
2. Check it's fully booted
3. Try connection again

### Cause 3: Wrong IP Entered

**Common mistakes:**
- Extra spaces: " 192.168.1.100" ❌
- Wrong format: "192.168.1.100." ❌ (extra dot)
- Hostname instead of IP: "bambulabprinter" ❌
- Old IP: Printer IP changed ❌

**Correct:**
- Exact format: "192.168.1.100" ✓
- No spaces, no extra characters
- Get from printer Settings → Network

### Cause 4: VPN Active

**Why:** VPN routes traffic differently

**Fix:**
1. Temporarily disable VPN
2. Test connection
3. If works, configure VPN to allow local network

### Cause 5: Firewall Blocking

**Why:** Windows Firewall or antivirus blocking

**Fix:**
1. Windows Security → Firewall
2. Allow Python through firewall
3. Or temporarily disable to test

### Cause 6: Different Subnets

**Why:** Computer on 192.168.1.x, printer on 192.168.2.x

**Fix:**
1. Check computer IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
2. Check printer IP on touchscreen
3. Both should be 192.168.X.Y where X is the same
4. Reconnect printer to correct WiFi

## Detailed Diagnostic Steps

### Step 1: Get Printer IP

On printer:
1. Touch Settings icon
2. Select "Network"
3. Note the IP Address (e.g., 192.168.1.100)

### Step 2: Test From Command Line

**Windows Command Prompt:**
```cmd
# Test basic connectivity
ping 192.168.1.100

# Test MQTT port specifically
telnet 192.168.1.100 8883
```

**Mac/Linux Terminal:**
```bash
# Test basic connectivity  
ping 192.168.1.100

# Test MQTT port
nc -zv 192.168.1.100 8883
```

### Step 3: Check Your Computer's IP

**Windows:**
```cmd
ipconfig
```
Look for "IPv4 Address" under your WiFi adapter

**Mac/Linux:**
```bash
ifconfig
# or
ip addr show
```

**They should be on same subnet:**
- Computer: 192.168.1.50 ✓
- Printer: 192.168.1.100 ✓
- SAME: 192.168.1.X

**Different subnet (won't work):**
- Computer: 192.168.1.50 ❌
- Printer: 192.168.2.100 ❌
- DIFFERENT: 192.168.X.Y

### Step 4: Run Diagnostic Script

```cmd
python diagnose_network.py 192.168.1.100
```

This will show exactly what's wrong.

## Setting Static IP (Recommended)

To prevent IP from changing:

### Method 1: Via Router (Best)

1. Log into your router (usually 192.168.1.1)
2. Find DHCP settings or "Address Reservation"
3. Find printer by MAC address
4. Assign permanent IP (e.g., 192.168.1.100)

### Method 2: Via Printer (If Supported)

Some printers allow static IP:
1. Settings → Network → Advanced
2. Set to "Static IP" instead of DHCP
3. Enter IP, subnet mask, gateway

## Still Not Working?

### Check These:

**Printer:**
- [ ] Is turned ON
- [ ] WiFi is connected (check icon on screen)
- [ ] Not in sleep mode
- [ ] Firmware is updated

**Network:**
- [ ] Printer and computer on SAME WiFi
- [ ] Not on guest network
- [ ] Can ping printer
- [ ] Ports 8883 and 990 not blocked

**App Settings:**
- [ ] IP address is correct (check printer display)
- [ ] No typos or extra spaces
- [ ] Access code is 8 digits
- [ ] Serial number is correct

### Quick Test From R

Before using the app, test in R console:

```r
# Test if R can reach the printer
system("ping 192.168.1.100")

# Test Python script directly
system('python bambulab_mqtt.py connect 192.168.1.100 12345678 01S00A123456789')
```

(Replace with YOUR IP, access code, serial)

## Error Variations

All these are the same issue (network):

- `[Errno 11001] getaddrinfo failed` ← Windows
- `[Errno -2] Name or service not known` ← Linux
- `[Errno 8] nodename nor servname provided` ← Mac
- `Network is unreachable`
- `Connection timed out`
- `No route to host`

**Solution:** Check IP address and network connection.

## Summary

**Most common fix:**
1. Check printer IP on touchscreen
2. Enter correct IP in app
3. Make sure printer is awake and connected to WiFi

**90% of the time it's just the IP address changed or was entered incorrectly!**

---

**Quick Checklist:**
- [ ] Printer is ON and awake
- [ ] WiFi connected on printer
- [ ] Got IP from Settings → Network
- [ ] Typed IP exactly, no spaces
- [ ] Can ping the IP
- [ ] Tried `python diagnose_network.py <IP>`
