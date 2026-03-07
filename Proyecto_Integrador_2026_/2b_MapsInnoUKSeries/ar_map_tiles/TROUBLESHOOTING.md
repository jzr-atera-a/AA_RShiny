# TROUBLESHOOTING GUIDE
## AR Map Tiles Viewer for Quest 3

---

## 🔍 Quick Diagnostics

### Test Checklist:
```
□ Windows machine IP is 192.168.100.14
□ Python installed and in PATH
□ cert.pem and key.pem exist
□ Server shows "HTTPS SERVER RUNNING"
□ Quest 3 on same WiFi network
□ Quest Browser opened
□ Certificate warning accepted
□ Camera/sensors permissions granted
```

---

## ⚠️ Common Issues & Solutions

### 1. "Python is not recognized as internal or external command"

**Problem:** Python not installed or not in PATH

**Solutions:**
```bash
# Check if Python installed:
python --version

# If not found:
1. Download from https://www.python.org/downloads/
2. During install: ✅ CHECK "Add Python to PATH"
3. Restart command prompt
4. Try again: python --version
```

---

### 2. "OpenSSL is not recognized"

**Problem:** OpenSSL not available for certificate generation

**Solutions:**

**Option A - Use Git Bash:**
```bash
# If you have Git installed:
1. Open Git Bash (right-click folder → "Git Bash Here")
2. Run: ./generate_cert.bat
```

**Option B - Install OpenSSL:**
```
1. Download: https://slproweb.com/products/Win32OpenSSL.html
2. Install "Win64 OpenSSL v3.x.x Light"
3. Add to PATH: C:\Program Files\OpenSSL-Win64\bin
4. Restart command prompt
```

**Option C - Use PowerShell:**
```powershell
# Alternative command:
$cert = New-SelfSignedCertificate -DnsName "192.168.100.14" -CertStoreLocation "cert:\CurrentUser\My"
Export-PfxCertificate -Cert $cert -FilePath cert.pfx -Password (ConvertTo-SecureString -String "password" -Force -AsPlainText)
# Then convert with OpenSSL or use online tools
```

---

### 3. "Connection Refused" on Quest 3

**Problem:** Server not reachable from Quest

**Diagnosis Steps:**

**Step 1 - Verify Server Running:**
```bash
# Should see:
HTTPS SERVER RUNNING
Server IP: 192.168.100.14:8000
```

**Step 2 - Check Windows IP:**
```bash
ipconfig

# Look for:
IPv4 Address. . . . . . . . : 192.168.100.14
```

**Step 3 - Test from Windows Browser First:**
```
Open Chrome/Edge on Windows machine:
https://192.168.100.14:8000/test_preview.html

If this works → firewall blocking Quest
If this fails → server issue
```

**Step 4 - Check Firewall:**
```
1. Windows Security → Firewall & network protection
2. Allow an app through firewall
3. Find "Python" → ✅ Check Private and Public
4. Restart server
```

**Step 5 - Verify Same Network:**
```
Quest 3:
- Settings → WiFi → Check network name

Windows:
- ipconfig → Check WiFi name matches
```

---

### 4. Certificate Warning Won't Accept

**Problem:** Quest browser blocks self-signed certificate

**Solutions:**

**Try 1 - Type "thisisunsafe":**
```
1. When you see certificate warning
2. Click anywhere on the page
3. Type (without any textbox): thisisunsafe
4. Page should load automatically
```

**Try 2 - Clear Browser Data:**
```
Quest Browser:
1. Three dots menu → Settings
2. Privacy & Security
3. Clear browsing data
4. Select "Cached images and files"
5. Clear data
6. Restart browser
7. Try again
```

**Try 3 - Regenerate Certificate:**
```bash
# Delete old certificates
del cert.pem key.pem

# Generate new
generate_cert.bat

# Restart server
python https_server.py
```

---

### 5. Map Tiles Not Loading / Blank Map

**Problem:** Tiles failing to fetch or CORS error

**Diagnosis:**

**Check 1 - Internet Connection:**
```bash
# Test from Windows:
ping tile.openstreetmap.org

# Should respond
```

**Check 2 - Browser Console (Windows first):**
```
1. Open test_preview.html in Windows browser
2. Press F12 → Console tab
3. Look for errors:
   - "Failed to fetch" → internet issue
   - "CORS policy" → tile server issue
   - "404 Not Found" → wrong tile coordinates
```

**Solutions:**

**A. Try Different Tile Server:**

Edit `ar_map_viewer.html`, find this line:
```javascript
TILE_SERVER: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
```

Replace with:
```javascript
// Option 1: Stamen Terrain
TILE_SERVER: 'https://stamen-tiles.a.ssl.fastly.net/terrain/{z}/{x}/{y}.png'

// Option 2: Stamen Toner (B&W)
TILE_SERVER: 'https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png'
```

**B. Reduce Tile Count:**
```javascript
TILES_X: 2,  // Change from 3
TILES_Y: 2,  // Change from 3
```

**C. Check Rate Limiting:**
```
OSM tiles are rate-limited:
- Wait 5 minutes
- Try again
- Consider Mapbox for production use
```

---

### 6. Floor Not Detected

**Problem:** AR session starts but floor doesn't appear

**Solutions:**

**Try 1 - Point Directly Down:**
```
- Look straight down at floor
- Move head slowly side to side
- Wait 5-10 seconds
- Green grid should appear
```

**Try 2 - Better Lighting:**
```
- Quest 3 needs good lighting for tracking
- Turn on room lights
- Avoid very bright/dark floors
- Plain floors work better than patterned
```

**Try 3 - Adjust Height Offset:**

Edit `ar_map_viewer.html`:
```javascript
FLOOR_OFFSET: 1.6,  // Try different values

// Too high? Try: 1.4
// Too low? Try: 1.8
```

**Try 4 - Clear Guardian:**
```
Quest 3:
- Settings → Guardian
- Clear Guardian History
- Redraw guardian
- Try AR app again
```

---

### 7. Map Appears Distorted or Wrong Size

**Problem:** Map too small, too large, or stretched

**Solutions:**

**Adjust Map Size:**
```javascript
MAP_SIZE: 3.0,  // Meters on floor

// Larger: 4.0 or 5.0
// Smaller: 2.0 or 1.5
```

**Fix Aspect Ratio:**
```javascript
// If tiles look stretched, try different grid:
TILES_X: 3,
TILES_Y: 2,  // Not square = different aspect ratio
```

---

### 8. Tiles Load Slowly / Timeout

**Problem:** Takes >30 seconds or never completes

**Solutions:**

**Reduce Tile Count:**
```javascript
TILES_X: 2,
TILES_Y: 2,
// = 4 tiles instead of 9
```

**Lower Zoom Level:**
```javascript
ZOOM_LEVEL: 12,  // Less detail = faster
```

**Check Network Speed:**
```bash
# Windows command prompt:
speedtest-cli

# Or visit: https://fast.com
```

---

### 9. Wrong Location Displayed

**Problem:** Map shows wrong area

**Verification:**

**Check Coordinates:**
```javascript
CENTER_LAT: 51.5074,  // London
CENTER_LON: -0.1278,

// Verify with Google Maps:
// https://www.google.com/maps/@51.5074,-0.1278,13z
```

**Common Mistakes:**
- Swapped lat/lon (lon should be negative for west)
- Wrong decimal places (51.5074 not 51.50740000)
- Zoom too high/low for area

**Get Correct Coordinates:**
```
1. Go to Google Maps
2. Right-click location
3. Click coordinates (e.g. "51.5074, -0.1278")
4. Copy to config
```

---

### 10. Server Starts But Shows Wrong IP

**Problem:** Server says 192.168.100.14 but machine has different IP

**Solution:**

**Find Your Real IP:**
```bash
ipconfig

# Look for:
Wireless LAN adapter Wi-Fi:
   IPv4 Address. . . : 192.168.X.X
```

**Update Files:**

**File 1: `https_server.py`**
```python
# Line ~30, change:
print(f"  📍 Server IP: 192.168.YOUR.IP:{PORT}")
```

**File 2: `START_SERVER.bat`**
```batch
REM Line ~50, change:
echo    https://192.168.YOUR.IP:8000/ar_map_viewer.html
```

**Use on Quest 3:**
```
https://192.168.YOUR.IP:8000/ar_map_viewer.html
```

---

## 🧪 Testing Without Quest 3

### Desktop Browser Test:

**Step 1 - Start Server:**
```bash
python https_server.py
```

**Step 2 - Open Test Page:**
```
Windows Browser:
https://192.168.100.14:8000/test_preview.html
```

**Step 3 - Verify Tiles Load:**
- Should see map
- Try different locations
- Download PNG to save

**If test_preview.html works but Quest doesn't:**
→ Problem is AR/Quest specific (permissions, AR session, floor detection)

**If test_preview.html doesn't work:**
→ Problem is network/server/tiles (fix before trying Quest)

---

## 📋 Verification Commands

```bash
# Check Python
python --version
# Should show: Python 3.x.x

# Check OpenSSL
openssl version
# Should show: OpenSSL 3.x.x

# Check IP Address
ipconfig
# Look for: IPv4 Address. . . : 192.168.100.14

# Check certificates exist
dir cert.pem key.pem
# Should list both files

# Check server listening
netstat -an | find "8000"
# Should show: TCP 0.0.0.0:8000 ... LISTENING
```

---

## 🚨 Emergency Reset

**If nothing works, start fresh:**

```bash
# 1. Stop server (Ctrl+C)

# 2. Delete certificates
del cert.pem key.pem

# 3. Regenerate
generate_cert.bat

# 4. Restart server
python https_server.py

# 5. Clear Quest Browser
Quest: Settings → Apps → Browser → Clear Data

# 6. Reboot Quest
Quest: Settings → System → Power Off → Power On

# 7. Try again from scratch
```

---

## 📞 Still Not Working?

### Information to Collect:

**Windows Machine:**
```bash
python --version
ipconfig
dir cert.pem key.pem
```

**Quest 3:**
- Browser version
- Guardian set up? (Yes/No)
- WiFi network name
- Error messages shown

**Network:**
- Same WiFi network name for both?
- 2.4GHz or 5GHz?
- Router model?

**Test Results:**
- Does test_preview.html work?
- Can you ping from Windows to Quest?
- Firewall completely disabled for test?

---

**Last Updated:** February 2026
**Contact:** Check project documentation
