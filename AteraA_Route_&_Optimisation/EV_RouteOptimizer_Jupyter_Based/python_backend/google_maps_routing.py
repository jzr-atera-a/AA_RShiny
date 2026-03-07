"""
google_maps_routing.py
Handles route extraction from Google Maps API
"""

import googlemaps
import polyline
import json
import sys
from typing import Dict, List, Tuple

def get_route(origin: str, destination: str, api_key: str) -> Dict:
    """
    Get route from Google Maps Directions API
    
    Args:
        origin: Starting location
        destination: Ending location
        api_key: Google Maps API key
    
    Returns:
        Dictionary with route information
    """
    try:
        gmaps = googlemaps.Client(key=api_key)
        
        # Request directions
        directions = gmaps.directions(
            origin=origin,
            destination=destination,
            mode="driving",
            alternatives=False
        )
        
        if not directions:
            raise ValueError("No route found")
        
        route = directions[0]
        leg = route['legs'][0]
        
        # Extract polyline
        overview_polyline = route['overview_polyline']['points']
        
        # Decode polyline to coordinates
        coordinates = polyline.decode(overview_polyline)
        
        result = {
            'success': True,
            'origin': {
                'address': leg['start_address'],
                'lat': leg['start_location']['lat'],
                'lng': leg['start_location']['lng']
            },
            'destination': {
                'address': leg['end_address'],
                'lat': leg['end_location']['lat'],
                'lng': leg['end_location']['lng']
            },
            'distance_km': leg['distance']['value'] / 1000,
            'duration_min': leg['duration']['value'] / 60,
            'polyline_encoded': overview_polyline,
            'coordinates': coordinates,
            'steps': len(route['legs'][0]['steps'])
        }
        
        return result
        
    except Exception as e:
        return {
            'success': False,
            'error': str(e)
        }

def resample_coordinates(coordinates: List[Tuple[float, float]], 
                        spacing_meters: int = 50) -> List[Dict]:
    """
    Resample coordinates at fixed intervals
    
    Args:
        coordinates: List of (lat, lng) tuples
        spacing_meters: Distance between waypoints
    
    Returns:
        List of waypoint dictionaries
    """
    from geopy.distance import geodesic
    
    waypoints = []
    waypoints.append({
        'sequence': 1,
        'lat': coordinates[0][0],
        'lng': coordinates[0][1],
        'distance_from_start': 0
    })
    
    cumulative_distance = 0
    last_point = coordinates[0]
    
    for i, coord in enumerate(coordinates[1:], start=1):
        current_point = coord
        segment_distance = geodesic(last_point, current_point).meters
        cumulative_distance += segment_distance
        
        if cumulative_distance >= spacing_meters:
            waypoints.append({
                'sequence': len(waypoints) + 1,
                'lat': current_point[0],
                'lng': current_point[1],
                'distance_from_start': cumulative_distance
            })
            last_point = current_point
            cumulative_distance = 0
    
    # Add final point
    if coordinates[-1] != last_point:
        waypoints.append({
            'sequence': len(waypoints) + 1,
            'lat': coordinates[-1][0],
            'lng': coordinates[-1][1],
            'distance_from_start': cumulative_distance
        })
    
    return waypoints

if __name__ == "__main__":
    # CLI interface for R integration
    if len(sys.argv) < 4:
        print(json.dumps({'success': False, 'error': 'Missing arguments'}))
        sys.exit(1)
    
    origin = sys.argv[1]
    destination = sys.argv[2]
    api_key = sys.argv[3]
    spacing = int(sys.argv[4]) if len(sys.argv) > 4 else 50
    
    # Get route
    route_result = get_route(origin, destination, api_key)
    
    if not route_result['success']:
        print(json.dumps(route_result))
        sys.exit(1)
    
    # Resample waypoints
    waypoints = resample_coordinates(route_result['coordinates'], spacing)
    route_result['waypoints'] = waypoints
    
    # Output JSON
    print(json.dumps(route_result))
