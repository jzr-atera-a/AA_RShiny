"""
yolo_inference.py
Run YOLO object detection on Street View images
"""

import json
import sys
import os
from pathlib import Path
from typing import List, Dict
import numpy as np
from ultralytics import YOLO
from tqdm import tqdm
import torch

# Class mapping for CAV features
CLASS_MAP = {
    0: 'roundabout',
    1: 'tunnel',
    2: 'junction',
    3: 'lane_merge',
    4: 'curve',
    5: 'pedestrian_crossing',
    6: 'construction_zone',
    7: 'traffic_signals',
    8: 'bus_stop',
    9: 'signage'
}

# Risk classification
RISK_LEVELS = {
    'roundabout': 'CRITICAL',
    'tunnel': 'CRITICAL',
    'junction': 'CRITICAL',
    'motorway_junction': 'CRITICAL',
    'pedestrian_crossing': 'CRITICAL',
    'lane_merge': 'MEDIUM',
    'construction_zone': 'MEDIUM',
    'curve': 'MEDIUM',
    'obscured_signage': 'MEDIUM',
    'traffic_signals': 'MEDIUM',
    'bus_stop': 'LOW',
    'signage': 'LOW'
}

def load_model(model_path: str, device: str = None) -> YOLO:
    """
    Load YOLO model
    
    Args:
        model_path: Path to .pt model file
        device: 'cuda', 'cpu', or None for auto
    
    Returns:
        YOLO model instance
    """
    if device is None:
        device = 'cuda' if torch.cuda.is_available() else 'cpu'
    
    model = YOLO(model_path)
    model.to(device)
    
    return model

def run_inference(model: YOLO, image_path: str, 
                 confidence_threshold: float = 0.5) -> List[Dict]:
    """
    Run YOLO inference on single image
    
    Args:
        model: YOLO model instance
        image_path: Path to image
        confidence_threshold: Minimum confidence score
    
    Returns:
        List of detection dictionaries
    """
    results = model(image_path, verbose=False)
    
    detections = []
    
    for result in results:
        boxes = result.boxes
        
        for i, box in enumerate(boxes):
            conf = float(box.conf[0])
            
            if conf >= confidence_threshold:
                cls_id = int(box.cls[0])
                feature_type = CLASS_MAP.get(cls_id, f'class_{cls_id}')
                risk_level = RISK_LEVELS.get(feature_type, 'LOW')
                
                # Get bounding box coordinates (normalized)
                x, y, w, h = box.xywhn[0].tolist()
                
                detection = {
                    'image_path': image_path,
                    'class_id': cls_id,
                    'feature_type': feature_type,
                    'confidence': round(conf, 4),
                    'risk_level': risk_level,
                    'bbox_x': round(x, 4),
                    'bbox_y': round(y, 4),
                    'bbox_width': round(w, 4),
                    'bbox_height': round(h, 4)
                }
                
                detections.append(detection)
    
    return detections

def run_batch_inference(model_path: str, image_dir: str,
                       confidence_threshold: float = 0.5,
                       batch_size: int = 16) -> List[Dict]:
    """
    Run YOLO inference on directory of images
    
    Args:
        model_path: Path to YOLO model
        image_dir: Directory containing images
        confidence_threshold: Minimum confidence
        batch_size: Number of images to process at once
    
    Returns:
        List of all detections
    """
    # Load model
    print(f"Loading model from {model_path}...", file=sys.stderr)
    model = load_model(model_path)
    
    # Get image files
    image_files = []
    for ext in ['*.jpg', '*.jpeg', '*.png']:
        image_files.extend(Path(image_dir).glob(ext))
    
    image_files = sorted(image_files)
    
    if not image_files:
        return {'success': False, 'error': 'No images found'}
    
    print(f"Found {len(image_files)} images", file=sys.stderr)
    
    # Run inference
    all_detections = []
    
    for img_path in tqdm(image_files, desc="Running YOLO inference"):
        detections = run_inference(model, str(img_path), confidence_threshold)
        all_detections.extend(detections)
    
    return all_detections

def save_detections_csv(detections: List[Dict], output_path: str):
    """Save detections to CSV file"""
    import csv
    
    if not detections:
        return
    
    fieldnames = ['image_path', 'class_id', 'feature_type', 'confidence', 
                  'risk_level', 'bbox_x', 'bbox_y', 'bbox_width', 'bbox_height']
    
    with open(output_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(detections)

if __name__ == "__main__":
    # CLI interface for R integration
    if len(sys.argv) < 3:
        print(json.dumps({'success': False, 'error': 'Missing arguments'}))
        sys.exit(1)
    
    model_path = sys.argv[1]
    image_dir = sys.argv[2]
    confidence = float(sys.argv[3]) if len(sys.argv) > 3 else 0.5
    output_csv = sys.argv[4] if len(sys.argv) > 4 else None
    
    try:
        # Run inference
        detections = run_batch_inference(model_path, image_dir, confidence)
        
        # Save CSV if requested
        if output_csv and detections:
            save_detections_csv(detections, output_csv)
        
        # Output results
        result = {
            'success': True,
            'total_detections': len(detections),
            'unique_classes': len(set(d['feature_type'] for d in detections)),
            'detections': detections
        }
        
        print(json.dumps(result))
        
    except Exception as e:
        print(json.dumps({'success': False, 'error': str(e)}))
        sys.exit(1)
