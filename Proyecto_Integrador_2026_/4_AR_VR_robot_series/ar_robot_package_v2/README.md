# 🤖 Robot AR — MetaQuest WebXR Package

## Files
| File | Description |
|------|-------------|
| `robot_ar_map.html` | Main AR page — 3D robot + GeoJSON map on floor |
| `https_server.py`   | HTTPS server (required for WebXR) |
| `sample_campus_map.geojson` | London/M25 map data |
| `cert.pem` / `key.pem` | Self-signed SSL certificates |

## Quick Start (Windows)

1. Open **Command Prompt** or **PowerShell** in this folder
2. Run:
   ```
   python https_server.py
   ```
   Or with a custom IP:
   ```
   python https_server.py 192.168.1.X
   ```
3. On MetaQuest Browser, go to:
   ```
   https://10.5.21.31:8443/robot_ar_map.html
   ```
4. Tap **Advanced → Proceed** to accept the cert warning
5. Tap **▶ START AR**

## Robot Physical Specs (from config)
- Body length:   60 cm
- Wheel track:   30 cm (outer to outer)
- Wheelbase:     34 cm (front to rear axle)
- Turning radius: 50 cm (Ackermann steering)
- Max speed:     20 cm/s
- Servo range:   45°–135°, centre 90°
- Rear drive:    2× independent DC motors via MD22 H-bridge

## AR Behaviour
- As soon as the AR session starts, the floor is detected automatically
- The GeoJSON map loads and renders on the floor (scaled down, 2.1×2.1 m)
- The robot 3D model is placed at 1:1 real size on the floor at map centre
- N/S/E/W compass markers appear at map edges

## If Certs Expire
```
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days 365 -nodes -subj "/CN=10.5.21.31"
```
