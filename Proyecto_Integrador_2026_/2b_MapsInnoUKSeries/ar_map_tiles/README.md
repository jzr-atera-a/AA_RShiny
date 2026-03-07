# AR Map Tiles Viewer for Meta Quest 3
## High-Quality OpenStreetMap on AR Floor

---

## 🚀 Quick Start (3 Steps)

### 1. Generate SSL Certificates
```cmd
generate_certs.bat
```

### 2. Start HTTPS Server  
```cmd
start_server.bat
```

### 3. Open on Quest 3
Navigate to: `https://192.168.100.14:8000/ar_map_viewer.html`

---

## 📋 Prerequisites

- **Windows PC** at IP: `192.168.100.14`
- **Meta Quest 3** on same WiFi
- **Python 3.7+** installed
- **OpenSSL** (Git Bash or WSL)

---

## 🗺️ What You Get

- **High-quality map tiles** from OpenStreetMap
- **London M25 area** displayed on floor
- **2.5m x 2.5m** physical size
- **9 tiles** (3x3 grid) at zoom level 11
- **Automatic floor detection**
- **72fps AR performance**

---

## ⚙️ Configuration

Edit `ar_map_viewer.html` line 32:

```javascript
const CFG = {
    LAT: 51.505,     // Map center latitude
    LON: -0.09,      // Map center longitude
    ZOOM: 11,        // 10=region, 11=city, 13=neighborhood
    MAP_SIZE: 2.5,   // Size in meters
};
```

### Change Location
```javascript
// Cambridge, UK
LAT: 52.2053,
LON: 0.1218
```

### Adjust Zoom
- `10` = Large region (full M25)
- `11` = City area (default)
- `12` = Large neighborhood
- `13` = Detailed neighborhood
- `15` = Street level

---

## 🎨 Use Mapbox (Optional)

Get free API key: https://account.mapbox.com

Edit line 41:
```javascript
TILE_URL: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=YOUR_TOKEN'
```

**Mapbox Styles:**
- `streets-v11` - Street map
- `satellite-v9` - Satellite
- `outdoors-v11` - Topographic
- `dark-v10` / `light-v10` - Themed

---

## 🔧 Troubleshooting

### Certificate Warning
- Click "Advanced" → "Proceed anyway"
- Ensure IP matches: `192.168.100.14`

### Map Not Loading
- Check internet connection
- Verify firewall allows port 8000
- Check browser console (F12)

### Floor Not Detected
- Stand up and move slowly
- Point controller at floor
- Ensure good lighting

### Wrong Position
- Adjust `FLOOR_OFFSET` in CFG (line 29)
- Try values 1.4 - 1.8 (default 1.6)

---

## 📊 Technical Details

- **Tile Provider:** OpenStreetMap (free)
- **Tile Format:** Web Mercator EPSG:3857
- **Tile Size:** 256×256px
- **Canvas:** 2048×2048px
- **Geometry:** 2 triangles (single plane)
- **Memory:** ~30MB
- **FPS:** 72 Hz

---

## 🚀 Next Steps

### Add Route Overlays
Draw your WP5 route data on top:
```javascript
// After loading tiles
ctx.strokeStyle = '#ff6600';
ctx.lineWidth = 8;
routePoints.forEach((pt, i) => {
    const [x, y] = latLonToCanvas(pt.lat, pt.lon);
    i === 0 ? ctx.moveTo(x, y) : ctx.lineTo(x, y);
});
ctx.stroke();
```

### Real-Time Updates
WebSocket for live route quality:
```javascript
websocket.onmessage = (e) => {
    updateRoute(JSON.parse(e.data));
    mapPlane.material.map.needsUpdate = true;
};
```

---

## 📁 Files

```
ar_map_tiles/
├── ar_map_viewer.html    # Main AR app
├── https_server.py       # HTTPS server
├── generate_certs.bat    # Certificate generator
├── start_server.bat      # Server launcher
├── README.md             # This file
├── cert.pem              # Generated cert
└── key.pem               # Generated key
```

---

## ✅ Success Checklist

- [ ] Python 3 installed
- [ ] OpenSSL available
- [ ] Certificates generated
- [ ] Server running
- [ ] Quest 3 on same WiFi
- [ ] Browser at correct URL
- [ ] Certificate accepted
- [ ] AR permissions granted
- [ ] Floor detected
- [ ] Map visible!

---

## 📄 Attribution

© OpenStreetMap contributors (ODbL License)
Three.js (MIT License)

Required: Display "© OpenStreetMap contributors" on maps
(Already included in code)

---

**Ready to test! 🎉**
