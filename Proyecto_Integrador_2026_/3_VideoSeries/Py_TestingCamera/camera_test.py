#!/usr/bin/env python3
"""
Simple USB Camera Test for NVIDIA Jetson Nano
HBV-W202012HD Camera Module

This script will:
1. Detect your USB camera
2. Display live video feed
3. Show FPS counter
4. Allow you to capture images

Controls:
- Press 'q' to quit
- Press 's' to save a snapshot
- Press 'i' to show camera info
"""

import cv2
import sys
import time
from datetime import datetime

def find_camera():
    """Try to find the USB camera on different video device indices"""
    print("Searching for USB camera...")
    for i in range(5):
        cap = cv2.VideoCapture(i)
        if cap.isOpened():
            ret, frame = cap.read()
            if ret:
                print(f"✓ Camera found at /dev/video{i}")
                return cap, i
            cap.release()
    return None, None

def get_camera_info(cap):
    """Get and display camera information"""
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = int(cap.get(cv2.CAP_PROP_FPS))
    
    info = f"""
    ╔══════════════════════════════════════╗
    ║       CAMERA INFORMATION             ║
    ╠══════════════════════════════════════╣
    ║ Resolution: {width}x{height}              ║
    ║ FPS: {fps} fps                          ║
    ║ Backend: {cap.getBackendName()}                    ║
    ╚══════════════════════════════════════╝
    """
    return info

def main():
    print("="*50)
    print("USB Camera Test - NVIDIA Jetson Nano")
    print("="*50)
    
    # Find camera
    cap, camera_index = find_camera()
    
    if cap is None:
        print("✗ ERROR: No USB camera detected!")
        print("\nTroubleshooting:")
        print("1. Check USB connection")
        print("2. Run: ls -l /dev/video*")
        print("3. Run: v4l2-ctl --list-devices")
        sys.exit(1)
    
    # Configure camera
    print("\nConfiguring camera...")
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
    cap.set(cv2.CAP_PROP_FPS, 30)
    
    # Display camera info
    print(get_camera_info(cap))
    
    print("\n" + "="*50)
    print("CONTROLS:")
    print("  Q - Quit")
    print("  S - Save snapshot")
    print("  I - Show camera info")
    print("="*50 + "\n")
    
    # FPS calculation variables
    fps_start_time = time.time()
    fps_frame_count = 0
    fps_display = 0
    
    snapshot_count = 0
    show_info = False
    
    while True:
        ret, frame = cap.read()
        
        if not ret:
            print("✗ ERROR: Failed to read frame from camera")
            break
        
        # Calculate FPS
        fps_frame_count += 1
        if (time.time() - fps_start_time) > 1:
            fps_display = fps_frame_count / (time.time() - fps_start_time)
            fps_start_time = time.time()
            fps_frame_count = 0
        
        # Add FPS counter to frame
        cv2.putText(frame, f"FPS: {fps_display:.1f}", (10, 30),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        
        # Add timestamp
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cv2.putText(frame, timestamp, (10, frame.shape[0] - 10),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)
        
        # Add camera index
        cv2.putText(frame, f"Camera: /dev/video{camera_index}", (10, 60),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 0), 1)
        
        # Show info overlay if requested
        if show_info:
            cv2.putText(frame, "Press 'I' to hide info", (10, 90),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 255), 1)
            cv2.putText(frame, f"Resolution: {frame.shape[1]}x{frame.shape[0]}", (10, 120),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 255), 1)
        
        # Display frame
        cv2.imshow('USB Camera Test - Press Q to quit', frame)
        
        # Handle keyboard input
        key = cv2.waitKey(1) & 0xFF
        
        if key == ord('q') or key == ord('Q'):
            print("\nQuitting...")
            break
        
        elif key == ord('s') or key == ord('S'):
            # Save snapshot
            snapshot_count += 1
            filename = f"snapshot_{snapshot_count}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.jpg"
            cv2.imwrite(filename, frame)
            print(f"✓ Snapshot saved: {filename}")
        
        elif key == ord('i') or key == ord('I'):
            # Toggle info display
            show_info = not show_info
            if show_info:
                print(get_camera_info(cap))
    
    # Cleanup
    cap.release()
    cv2.destroyAllWindows()
    print("\n" + "="*50)
    print("Camera test completed successfully!")
    print(f"Snapshots saved: {snapshot_count}")
    print("="*50)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        cv2.destroyAllWindows()
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()
