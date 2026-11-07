"""
streetview_downloader.py
Download Google Street View images at waypoints
"""

import requests
import json
import sys
import os
from typing import List, Dict
from tqdm import tqdm
import time

def download_streetview_image(lat: float, lng: float, 
                             output_path: str, api_key: str,
                             size: str = "640x640", 
                             fov: int = 90,
                             heading: int = 0,
                             pitch: int = 0) -> Dict:
    """
    Download single Street View image
    
    Args:
        lat: Latitude
        lng: Longitude
        output_path: Where to save image
        api_key: Google Maps API key
        size: Image dimensions
        fov: Field of view (degrees)
        heading: Compass heading (0-360)
        pitch: Camera pitch (-90 to 90)
    
    Returns:
        Dictionary with download status
    """
    try:
        url = "https://maps.googleapis.com/maps/api/streetview"
        
        params = {
            'size': size,
            'location': f"{lat},{lng}",
            'fov': fov,
            'heading': heading,
            'pitch': pitch,
            'key': api_key
        }
        
        response = requests.get(url, params=params, timeout=30)
        
        if response.status_code == 200:
            # Check if image is valid (not "no imagery" placeholder)
            if len(response.content) > 5000:  # Placeholder images are ~2KB
                with open(output_path, 'wb') as f:
                    f.write(response.content)
                
                return {
                    'success': True,
                    'filepath': output_path,
                    'size_bytes': len(response.content)
                }
            else:
                return {
                    'success': False,
                    'error': 'No Street View imagery available'
                }
        else:
            return {
                'success': False,
                'error': f'HTTP {response.status_code}'
            }
            
    except Exception as e:
        return {
            'success': False,
            'error': str(e)
        }

def download_batch(waypoints: List[Dict], output_dir: str, 
                  api_key: str, sample_rate: int = 1,
                  size: str = "640x640", fov: int = 90) -> List[Dict]:
    """
    Download Street View images for multiple waypoints
    
    Args:
        waypoints: List of waypoint dicts with lat/lng
        output_dir: Directory to save images
        api_key: Google Maps API key
        sample_rate: Download every Nth waypoint
        size: Image dimensions
        fov: Field of view
    
    Returns:
        List of download results
    """
    os.makedirs(output_dir, exist_ok=True)
    
    results = []
    sampled_waypoints = waypoints[::sample_rate]
    
    for i, wp in enumerate(tqdm(sampled_waypoints, desc="Downloading images")):
        # Generate filename
        filename = f"streetview_{wp['sequence']:04d}_{wp['lat']:.6f}_{wp['lng']:.6f}.jpg"
        filepath = os.path.join(output_dir, filename)
        
        # Download image
        result = download_streetview_image(
            lat=wp['lat'],
            lng=wp['lng'],
            output_path=filepath,
            api_key=api_key,
            size=size,
            fov=fov
        )
        
        result['waypoint_sequence'] = wp['sequence']
        result['lat'] = wp['lat']
        result['lng'] = wp['lng']
        
        results.append(result)
        
        # Rate limiting - avoid hitting API limits
        time.sleep(0.1)
    
    return results

if __name__ == "__main__":
    # CLI interface for R integration
    if len(sys.argv) < 4:
        print(json.dumps({'success': False, 'error': 'Missing arguments'}))
        sys.exit(1)
    
    waypoints_json = sys.argv[1]  # JSON string of waypoints
    output_dir = sys.argv[2]
    api_key = sys.argv[3]
    sample_rate = int(sys.argv[4]) if len(sys.argv) > 4 else 1
    size = sys.argv[5] if len(sys.argv) > 5 else "640x640"
    fov = int(sys.argv[6]) if len(sys.argv) > 6 else 90
    
    # Parse waypoints
    waypoints = json.loads(waypoints_json)
    
    # Download images
    results = download_batch(waypoints, output_dir, api_key, sample_rate, size, fov)
    
    # Output results
    output = {
        'success': True,
        'total_waypoints': len(waypoints),
        'sampled_waypoints': len(waypoints[::sample_rate]),
        'successful_downloads': sum(1 for r in results if r['success']),
        'failed_downloads': sum(1 for r in results if not r['success']),
        'results': results
    }
    
    print(json.dumps(output))
