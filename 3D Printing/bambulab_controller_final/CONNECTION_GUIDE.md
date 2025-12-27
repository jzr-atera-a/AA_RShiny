# Quick Connection Setup Guide
## Bambulab A1 Combo - Network Connection

## ⚠️ IMPORTANT: Connection Method

**Bambulab printers use MQTT over LAN/WiFi, NOT USB serial!**

The printer connects to your local network and you communicate with it using:
- **MQTT protocol** (port 8883) for commands and status
- **FTP protocol** (port 990) for file uploads
- **Your local network** (WiFi or Ethernet)

## What You Need

### 1. Printer Network Information

You need to get 3 pieces of information from your printer:

#### A. **IP Address**
1. On printer touchscreen, go to: **Settings → Network**
2. Look for **IP Address** (e.g., `192.168.1.100`)
3. Write this down

#### B. **Access Code** (8-digit password)
1. On printer touchscreen, go to: **Settings → WLAN**
2. Look for **Access Code** (e.g., `12345678`)
3. This is like a password for your printer
4. Write this down

#### C. **Serial Number**
1. Look at the label on your printer, OR
2. On printer touchscreen, go to: **Settings → Device**
3. Look for **Serial Number** (e.g., `01S00A123456789`)
4. Write this down

### 2. Network Requirements

- Your **computer** and **printer** must be on the **same network**
- Make sure these ports are NOT blocked by your firewall:
  - Port **8883** (MQTT - for commands)
  - Port **990** (FTP - for file uploads)
  - Port **6000** (Camera stream - optional)

## Quick Test Connection

### Using Python Script

1. **Install Python requirements**:
   ```bash
   pip install paho-mqtt
   ```

2. **Test connection**:
   ```bash
   python bambulab_mqtt.py connect YOUR_IP YOUR_ACCESS_CODE YOUR_SERIAL
   ```
   
   Example:
   ```bash
   python bambulab_mqtt.py connect 192.168.1.100 12345678 01S00A123456789
   ```

3. **If successful, you'll see**:
   ```
   {"status": "connected", "message": "Successfully connected to printer"}
   ```

### Common Connection Issues

#### Issue: "Connection timeout"
- **Check**: Printer is on and connected to WiFi
- **Check**: Computer and printer are on same network
- **Check**: IP address is correct (it may change if printer restarts)
- **Try**: Ping the printer: `ping 192.168.1.100`

#### Issue: "Connection refused" 
- **Check**: Access code is correct (8 digits)
- **Check**: Firewall isn't blocking port 8883
- **Try**: Temporarily disable firewall to test

#### Issue: Can't find IP address
- **Option 1**: Check your router's DHCP client list
- **Option 2**: Use network scanner tool (e.g., Advanced IP Scanner)
- **Option 3**: Assign a static IP to the printer in router settings

## Test Commands

Once connected, try these commands:

### Get Current Status
```bash
python bambulab_mqtt.py status 192.168.1.100 12345678 01S00A123456789
```

### Get Temperatures
```bash
python bambulab_mqtt.py temps 192.168.1.100 12345678 01S00A123456789
```

### Get Print Information
```bash
python bambulab_mqtt.py print_info 192.168.1.100 12345678 01S00A123456789
```

### Control Chamber Light
```bash
# Turn light on
python bambulab_mqtt.py light 192.168.1.100 12345678 01S00A123456789 on

# Turn light off
python bambulab_mqtt.py light 192.168.1.100 12345678 01S00A123456789 off
```

### Upload a File
```bash
python bambulab_mqtt.py upload 192.168.1.100 12345678 01S00A123456789 test_print.gcode
```

### Send Custom G-code
```bash
python bambulab_mqtt.py gcode 192.168.1.100 12345678 01S00A123456789 "G28"
```

## Using with R Shiny App

The R Shiny app will call these Python scripts in the background. You'll need to:

1. Enter your IP, Access Code, and Serial Number in the Connection tab
2. Click "Connect to Printer"
3. The app will use the Python script to establish connection

## Network Security Notes

- **Access Code** acts as your printer password
- Keep it private - anyone with this code can control your printer
- Your printer communicates only on your local network (unless you enable Bambu Cloud)
- The connection uses TLS encryption (secure)

## Advanced: Finding Your Printer on Network

### Windows
```bash
# Install nmap (download from nmap.org)
nmap -p 8883 192.168.1.0/24
```

### Check if printer is reachable
```bash
ping 192.168.1.100
telnet 192.168.1.100 8883
```

## Alternative: Using Bambulab Python API

For more advanced usage, you can also use the official Python library:

```bash
pip install bambulabs-api
```

Then in Python:
```python
import bambulabs_api as bl

IP = '192.168.1.100'
ACCESS_CODE = '12345678'
SERIAL = '01S00A123456789'

printer = bl.Printer(IP, ACCESS_CODE, SERIAL)
printer.connect()

# Get status
status = printer.get_state()
print(status)

# Get temperature
temps = printer.get_temperature()
print(temps)

printer.disconnect()
```

## Next Steps

Once you've confirmed connection works:

1. Update the R Shiny app with your printer details
2. Test basic operations (lights, temperatures)
3. Try uploading and printing a test file
4. Explore monitoring features

## Support Resources

- **Bambulab Wiki**: https://wiki.bambulab.com/
- **Network Ports Info**: https://wiki.bambulab.com/en/general/printer-network-ports
- **API Documentation**: https://github.com/coelacant1/Bambu-Lab-Cloud-API

---

**Remember**: Your printer's IP address may change if it reconnects to WiFi. Consider:
- Setting a static IP in your router
- Or using the printer's hostname if your network supports it
