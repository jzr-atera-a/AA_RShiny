# Using HBV-W202012HD USB Camera with NVIDIA Jetson Nano

## Overview
This guide shows you how to connect and use your HBV-W202012HD USB camera module with the NVIDIA Jetson Nano for computer vision projects.

## Hardware Connection

### Step 1: Physical Connection
1. **Connect USB camera** to any available USB port on Jetson Nano
   - Use USB 3.0 ports (blue) for better performance if available
   - USB 2.0 ports (black) will also work fine for this camera
2. **Power on your Jetson Nano**
3. Camera should be automatically detected (no drivers needed on Linux)

### Step 2: Verify Camera Detection
Open terminal and run:
```bash
ls -l /dev/video*
```

You should see something like:
```
/dev/video0
/dev/video1
```

The camera will typically be `/dev/video0` (or video1 if you have other cameras)

To get more information:
```bash
v4l2-ctl --list-devices
```

This shows all connected video devices and their capabilities.

---

## Testing the Camera

### Quick Test with v4l2-ctl
Check camera capabilities:
```bash
v4l2-ctl --device=/dev/video0 --list-formats-ext
```

This shows supported resolutions and formats.

### Capture Test Image
```bash
v4l2-ctl --device=/dev/video0 --stream-mmap --stream-to=test.jpg --stream-count=1
```

---

## Python Integration

### Method 1: Using OpenCV (Recommended)

#### Install OpenCV (if not already installed)
```bash
sudo apt-get update
sudo apt-get install python3-opencv
```

#### Basic Camera Capture Script
```python
import cv2

# Open camera (0 = /dev/video0, 1 = /dev/video1, etc.)
cap = cv2.VideoCapture(0)

# Set resolution (adjust based on your camera's capabilities)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

# Check if camera opened successfully
if not cap.isOpened():
    print("Error: Could not open camera")
    exit()

print("Camera opened successfully!")
print(f"Resolution: {cap.get(cv2.CAP_PROP_FRAME_WIDTH)}x{cap.get(cv2.CAP_PROP_FRAME_HEIGHT)}")

while True:
    # Capture frame-by-frame
    ret, frame = cap.read()
    
    if not ret:
        print("Error: Can't receive frame")
        break
    
    # Display the frame
    cv2.imshow('USB Camera - Press Q to quit', frame)
    
    # Press 'q' to exit
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Release everything
cap.release()
cv2.destroyAllWindows()
```

Save as `camera_test.py` and run:
```bash
python3 camera_test.py
```

#### Advanced: Save Video
```python
import cv2
import datetime

cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)

# Define codec and create VideoWriter
fourcc = cv2.VideoWriter_fourcc(*'XVID')
timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
out = cv2.VideoWriter(f'output_{timestamp}.avi', fourcc, 20.0, (640, 480))

print("Recording... Press 'q' to stop")

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    # Write frame to video file
    out.write(frame)
    
    # Display frame
    cv2.imshow('Recording - Press Q to stop', frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
out.release()
cv2.destroyAllWindows()
print(f"Video saved as output_{timestamp}.avi")
```

---

### Method 2: Using GStreamer (Better Performance)

GStreamer provides hardware-accelerated video processing on Jetson Nano.

#### Test GStreamer Pipeline
```bash
gst-launch-1.0 v4l2src device=/dev/video0 ! 'video/x-raw,width=640,height=480,framerate=30/1' ! xvimagesink
```

#### Python with GStreamer
```python
import cv2

# GStreamer pipeline for USB camera
gst_str = (
    "v4l2src device=/dev/video0 ! "
    "video/x-raw, width=640, height=480, framerate=30/1 ! "
    "videoconvert ! "
    "appsink"
)

cap = cv2.VideoCapture(gst_str, cv2.CAP_GSTREAMER)

if not cap.isOpened():
    print("Error: Could not open camera with GStreamer")
    exit()

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    cv2.imshow('GStreamer Camera', frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

---

## Common Applications

### 1. Object Detection with TensorFlow Lite
```python
import cv2
import numpy as np
from tflite_runtime.interpreter import Interpreter

# Load TFLite model
interpreter = Interpreter(model_path="detect.tflite")
interpreter.allocate_tensors()

# Get input and output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Open camera
cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    # Preprocess frame for model
    input_shape = input_details[0]['shape']
    input_data = cv2.resize(frame, (input_shape[1], input_shape[2]))
    input_data = np.expand_dims(input_data, axis=0)
    
    # Run inference
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    
    # Get results
    boxes = interpreter.get_tensor(output_details[0]['index'])[0]
    classes = interpreter.get_tensor(output_details[1]['index'])[0]
    scores = interpreter.get_tensor(output_details[2]['index'])[0]
    
    # Draw detections
    for i in range(len(scores)):
        if scores[i] > 0.5:  # Confidence threshold
            # Draw bounding box
            ymin, xmin, ymax, xmax = boxes[i]
            # ... draw on frame ...
    
    cv2.imshow('Object Detection', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

### 2. Face Detection
```python
import cv2

# Load Haar Cascade for face detection
face_cascade = cv2.CascadeClassifier(
    cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
)

cap = cv2.VideoCapture(0)

while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    # Convert to grayscale
    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
    
    # Detect faces
    faces = face_cascade.detectMultiScale(gray, 1.1, 4)
    
    # Draw rectangles around faces
    for (x, y, w, h) in faces:
        cv2.rectangle(frame, (x, y), (x+w, y+h), (0, 255, 0), 2)
        cv2.putText(frame, 'Face', (x, y-10), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.9, (0, 255, 0), 2)
    
    cv2.imshow('Face Detection', frame)
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

### 3. Motion Detection
```python
import cv2

cap = cv2.VideoCapture(0)

# Read first frame
ret, frame1 = cap.read()
ret, frame2 = cap.read()

while True:
    # Calculate difference between frames
    diff = cv2.absdiff(frame1, frame2)
    gray = cv2.cvtColor(diff, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    _, thresh = cv2.threshold(blur, 20, 255, cv2.THRESH_BINARY)
    dilated = cv2.dilate(thresh, None, iterations=3)
    
    # Find contours
    contours, _ = cv2.findContours(dilated, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE)
    
    # Draw contours on frame
    for contour in contours:
        if cv2.contourArea(contour) < 5000:  # Filter small movements
            continue
        x, y, w, h = cv2.boundingRect(contour)
        cv2.rectangle(frame1, (x, y), (x+w, y+h), (0, 255, 0), 2)
        cv2.putText(frame1, "Motion Detected", (10, 30),
                   cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
    
    cv2.imshow('Motion Detection', frame1)
    
    # Update frames
    frame1 = frame2
    ret, frame2 = cap.read()
    
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()
```

---

## Troubleshooting

### Camera Not Detected
```bash
# Check USB devices
lsusb

# Check dmesg for camera messages
dmesg | grep video

# Install v4l-utils if not present
sudo apt-get install v4l-utils
```

### Permission Issues
```bash
# Add user to video group
sudo usermod -a -G video $USER

# Log out and log back in for changes to take effect
```

### Low Frame Rate / Performance
1. **Reduce resolution:**
   ```python
   cap.set(cv2.CAP_PROP_FRAME_WIDTH, 320)
   cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 240)
   ```

2. **Use GStreamer instead of OpenCV V4L2**

3. **Enable maximum performance mode:**
   ```bash
   sudo nvpmodel -m 0
   sudo jetson_clocks
   ```

4. **Check available formats:**
   ```bash
   v4l2-ctl --list-formats-ext
   ```
   Use MJPEG format if available for better performance.

### "Can't open camera" Error
```python
# Try different camera indices
for i in range(5):
    cap = cv2.VideoCapture(i)
    if cap.isOpened():
        print(f"Camera found at index {i}")
        cap.release()
```

### No Display (Headless Setup)
If running without monitor:
```python
# Save frames instead of displaying
cv2.imwrite('frame.jpg', frame)

# Or stream over network using Flask/FastAPI
```

---

## Performance Tips

1. **Use CUDA-accelerated OpenCV** (if installed with CUDA support)
2. **Reduce resolution** for faster processing
3. **Use hardware encoding** for video recording
4. **Enable Jetson performance mode:**
   ```bash
   sudo nvpmodel -m 0  # Max performance
   sudo jetson_clocks   # Max clock speeds
   ```
5. **Use GStreamer** for hardware-accelerated pipelines

---

## Remote Access / Streaming

### Stream over Network with Flask
```python
from flask import Flask, Response
import cv2

app = Flask(__name__)

def generate_frames():
    cap = cv2.VideoCapture(0)
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        
        # Encode frame
        ret, buffer = cv2.imencode('.jpg', frame)
        frame = buffer.tobytes()
        
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(),
                   mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
```

Access stream at: `http://<jetson-ip>:5000/video_feed`

---

## Resources

- [NVIDIA Jetson Developer Zone](https://developer.nvidia.com/embedded/jetson-nano-developer-kit)
- [JetsonHacks - Camera tutorials](https://www.jetsonhacks.com/)
- [OpenCV Documentation](https://docs.opencv.org/)
- [GStreamer Documentation](https://gstreamer.freedesktop.org/documentation/)

---

## Quick Reference Commands

```bash
# List cameras
ls -l /dev/video*

# Camera info
v4l2-ctl --device=/dev/video0 --all

# Supported formats
v4l2-ctl --device=/dev/video0 --list-formats-ext

# Test camera
gst-launch-1.0 v4l2src device=/dev/video0 ! xvimagesink

# Check Jetson stats
jtop  # (install with: sudo -H pip install jetson-stats)
```

Good luck with your computer vision project!
