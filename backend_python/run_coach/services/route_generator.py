"""
Route generation service using Google Maps APIs
"""

import os
import googlemaps
from typing import List, Dict, Tuple, Optional
import polyline
import numpy as np
from datetime import datetime
import logging

from ..models import RouteRecommendation, RouteSegment

logger = logging.getLogger(__name__)


class RouteGenerator:
    """
    Generates running route candidates using Google Maps Platform
    """
    
    def __init__(self):
        self.gmaps_key = os.getenv('GOOGLE_MAPS_API_KEY')
        if not self.gmaps_key:
            raise ValueError("Google Maps API key not found in environment")
            
        self.gmaps = googlemaps.Client(key=self.gmaps_key)
        
    def generate_route_candidates(
        self,
        start_point: Tuple[float, float],
        preferences: Dict,
        num_alternatives: int = 5
    ) -> List[Dict]:
        """
        Generate multiple route candidates for optimization
        
        Args:
            start_point: Starting location (lat, lon)
            preferences: User preferences (distance, avoid highways, etc.)
            num_alternatives: Number of alternative routes to generate
            
        Returns:
            List of route dictionaries with geometry and metadata
        """
        routes = []
        target_distance = preferences.get('preferred_distance_m', 5000)
        
        # Strategy 1: Loop routes using waypoints
        loop_routes = self._generate_loop_routes(start_point, target_distance)
        routes.extend(loop_routes)
        
        # Strategy 2: Out-and-back routes
        out_back_routes = self._generate_out_and_back_routes(start_point, target_distance)
        routes.extend(out_back_routes)
        
        # Strategy 3: Park-focused routes
        if preferences.get('prioritize_parks', True):
            park_routes = self._generate_park_routes(start_point, target_distance)
            routes.extend(park_routes)
            
        # Add metadata to all routes
        for route in routes:
            self._add_route_metadata(route)
            
        # Return top N routes based on initial scoring
        return self._select_best_candidates(routes, num_alternatives)
        
    def _generate_loop_routes(
        self, 
        start: Tuple[float, float],
        target_distance: float
    ) -> List[Dict]:
        """Generate circular/loop routes"""
        
        routes = []
        
        # Calculate radius for circular route (rough approximation)
        # Circumference = 2 * pi * r, so r = distance / (2 * pi)
        radius_m = target_distance / (2 * np.pi)
        radius_deg = radius_m / 111000  # Rough conversion to degrees
        
        # Generate waypoints in different directions
        directions = [(0, 1), (1, 0), (0, -1), (-1, 0), (1, 1), (-1, 1), (1, -1), (-1, -1)]
        
        for dx, dy in directions[:4]:  # Limit to 4 main directions
            # Create waypoint at roughly 1/3 distance
            waypoint1 = (
                start[0] + dx * radius_deg * 0.6,
                start[1] + dy * radius_deg * 0.6
            )
            
            # Create waypoint at roughly 2/3 distance (perpendicular)
            waypoint2 = (
                start[0] + dy * radius_deg * 0.6,
                start[1] - dx * radius_deg * 0.6
            )
            
            try:
                # Request route through waypoints
                result = self.gmaps.directions(
                    origin=start,
                    destination=start,
                    waypoints=[waypoint1, waypoint2],
                    mode="walking",
                    alternatives=False,
                    optimize_waypoints=True,
                    avoid=["highways", "tolls", "ferries"]
                )
                
                if result:
                    route = self._parse_gmaps_route(result[0])
                    route['type'] = 'loop'
                    routes.append(route)
                    
            except Exception as e:
                logger.error(f"Error generating loop route: {e}")
                
        return routes
        
    def _generate_out_and_back_routes(
        self,
        start: Tuple[float, float],
        target_distance: float
    ) -> List[Dict]:
        """Generate out-and-back routes"""
        
        routes = []
        half_distance = target_distance / 2
        
        # Search for interesting destinations at half distance
        try:
            # Find parks, landmarks, or other points of interest
            places_result = self.gmaps.places_nearby(
                location=start,
                radius=half_distance,
                type='park'
            )
            
            for place in places_result.get('results', [])[:3]:
                destination = (
                    place['geometry']['location']['lat'],
                    place['geometry']['location']['lng']
                )
                
                # Get route to destination
                result = self.gmaps.directions(
                    origin=start,
                    destination=destination,
                    mode="walking",
                    alternatives=True,
                    avoid=["highways", "tolls", "ferries"]
                )
                
                for route_option in result[:2]:  # Take up to 2 alternatives
                    route = self._parse_gmaps_route(route_option)
                    
                    # Double the distance for out-and-back
                    route['distance_m'] *= 2
                    route['duration_min'] *= 2
                    route['type'] = 'out_and_back'
                    route['destination_name'] = place.get('name', 'Unknown')
                    
                    routes.append(route)
                    
        except Exception as e:
            logger.error(f"Error generating out-and-back routes: {e}")
            
        return routes
        
    def _generate_park_routes(
        self,
        start: Tuple[float, float],
        target_distance: float
    ) -> List[Dict]:
        """Generate routes that prioritize parks and green spaces"""
        
        routes = []
        
        try:
            # Find nearby parks
            # Note: radius and rank_by='distance' are mutually exclusive
            parks = self.gmaps.places_nearby(
                location=start,
                radius=int(target_distance * 0.7),
                type='park'
            )
            
            park_locations = []
            for park in parks.get('results', [])[:5]:
                park_locations.append({
                    'location': (
                        park['geometry']['location']['lat'],
                        park['geometry']['location']['lng']
                    ),
                    'name': park.get('name', 'Unknown Park')
                })
                
            # Create routes that visit multiple parks
            if len(park_locations) >= 2:
                for i in range(min(3, len(park_locations) - 1)):
                    waypoints = [p['location'] for p in park_locations[i:i+2]]
                    
                    result = self.gmaps.directions(
                        origin=start,
                        destination=start,
                        waypoints=waypoints,
                        mode="walking",
                        optimize_waypoints=True,
                        avoid=["highways", "tolls", "ferries"]
                    )
                    
                    if result:
                        route = self._parse_gmaps_route(result[0])
                        route['type'] = 'park_route'
                        route['parks_visited'] = [p['name'] for p in park_locations[i:i+2]]
                        routes.append(route)
                        
        except Exception as e:
            logger.error(f"Error generating park routes: {e}")
            
        return routes
        
    def _parse_gmaps_route(self, gmaps_route: Dict) -> Dict:
        """Parse Google Maps route response into our format"""
        
        if not gmaps_route.get('legs'):
            raise ValueError("Invalid route response")
            
        # Combine all legs
        all_points = []
        total_distance = 0
        total_duration = 0
        
        for leg in gmaps_route['legs']:
            # Decode polyline
            if 'steps' in leg:
                for step in leg['steps']:
                    if 'polyline' in step and 'points' in step['polyline']:
                        points = polyline.decode(step['polyline']['points'])
                        all_points.extend(points)
                        
            total_distance += leg['distance']['value']
            total_duration += leg['duration']['value']
            
        # Remove duplicates while preserving order
        seen = set()
        unique_points = []
        for point in all_points:
            if point not in seen:
                seen.add(point)
                unique_points.append(point)
                
        return {
            'route_id': f"gmaps_{datetime.now().timestamp()}",
            'geometry': unique_points,
            'encoded_polyline': gmaps_route['overview_polyline']['points'],
            'distance_m': total_distance,
            'duration_min': total_duration / 60,
            'waypoint_order': gmaps_route.get('waypoint_order', [])
        }
        
    def _add_route_metadata(self, route: Dict):
        """Add additional metadata to route"""
        
        geometry = route['geometry']
        
        # Calculate elevation gain (would need Elevation API)
        route['elevation_gain_m'] = self._estimate_elevation_gain(geometry)
        
        # Estimate green space coverage
        route['green_coverage'] = self._estimate_green_coverage(geometry)
        
        # Calculate safety score based on road types
        route['safety_score'] = self._calculate_safety_score(geometry)
        
    def _estimate_elevation_gain(self, geometry: List[Tuple[float, float]]) -> float:
        """
        Estimate elevation gain for route
        Note: This would use Google Elevation API in production
        """
        # Simplified estimation based on number of turns and distance
        # Real implementation would query elevation API
        return np.random.uniform(0, 50)  # Placeholder
        
    def _estimate_green_coverage(self, geometry: List[Tuple[float, float]]) -> float:
        """
        Estimate percentage of route through green spaces
        Uses Places API to check proximity to parks along the route
        """
        if not geometry or len(geometry) < 2:
            return 0.0

        # Sample points along the route (every 10th point to avoid too many API calls)
        sample_points = geometry[::max(1, len(geometry)//10)]
        if len(sample_points) < 2:
            sample_points = [geometry[0], geometry[-1]]

        green_segments = 0
        total_segments = len(sample_points)

        # Check each sample point for nearby parks
        for point in sample_points:
            try:
                parks = self.gmaps.places_nearby(
                    location=point,
                    radius=100,  # 100m radius for green space detection
                    type='park'
                )

                # If parks found within 100m, consider this segment "green"
                if parks.get('results'):
                    green_segments += 1

            except Exception as e:
                logger.warning(f"Error checking green coverage at {point}: {e}")
                continue

        # Return percentage of green segments
        green_percentage = green_segments / total_segments if total_segments > 0 else 0.0
        return min(green_percentage, 1.0)  # Cap at 100%
        
    def _calculate_safety_score(self, geometry: List[Tuple[float, float]]) -> float:
        """
        Calculate safety score based on road types and traffic
        Note: This would use Roads API to identify road types
        """
        # Simplified scoring
        # Real implementation would analyze road types, sidewalk availability, etc.
        return np.random.uniform(0.5, 0.9)  # Placeholder
        
    def _select_best_candidates(
        self,
        routes: List[Dict],
        num_candidates: int
    ) -> List[Dict]:
        """Select best route candidates based on initial scoring"""
        
        if len(routes) <= num_candidates:
            return routes
            
        # Score routes based on multiple factors
        for route in routes:
            score = 0
            
            # Prefer routes close to target distance
            distance_error = abs(route['distance_m'] - 5000) / 5000
            score -= distance_error
            
            # Prefer routes with green coverage
            score += route['green_coverage'] * 2
            
            # Prefer safer routes
            score += route['safety_score']
            
            # Prefer loop routes
            if route.get('type') == 'loop':
                score += 0.5
                
            route['initial_score'] = score
            
        # Sort by score and return top N
        routes.sort(key=lambda x: x['initial_score'], reverse=True)
        return routes[:num_candidates]
        
    def get_elevation_profile(self, route: Dict) -> List[float]:
        """
        Get elevation profile for a route
        
        Args:
            route: Route dictionary with geometry
            
        Returns:
            List of elevation values in meters
        """
        geometry = route['geometry']
        
        if len(geometry) > 512:
            # Google Elevation API has a limit of 512 points per request
            # Sample points evenly
            indices = np.linspace(0, len(geometry) - 1, 512, dtype=int)
            sampled_points = [geometry[i] for i in indices]
        else:
            sampled_points = geometry
            
        try:
            # Query elevation API
            elevations = self.gmaps.elevation(sampled_points)
            
            return [e['elevation'] for e in elevations]
            
        except Exception as e:
            logger.error(f"Error fetching elevation data: {e}")
            # Return flat profile as fallback
            return [0.0] * len(sampled_points)
            
    def get_nearby_amenities(self, route: Dict) -> Dict[str, List]:
        """
        Find amenities near the route (water fountains, restrooms, etc.)
        
        Args:
            route: Route dictionary with geometry
            
        Returns:
            Dictionary of amenity types and their locations
        """
        amenities = {
            'water_fountains': [],
            'restrooms': [],
            'convenience_stores': []
        }
        
        # Sample points along route
        geometry = route['geometry']
        sample_points = geometry[::max(1, len(geometry) // 10)]  # Sample every 10%
        
        for point in sample_points:
            try:
                # Search for amenities near this point
                places = self.gmaps.places_nearby(
                    location=point,
                    radius=200,  # 200m radius
                    type='convenience_store'
                )
                
                for place in places.get('results', [])[:2]:
                    amenities['convenience_stores'].append({
                        'name': place.get('name'),
                        'location': (
                            place['geometry']['location']['lat'],
                            place['geometry']['location']['lng']
                        )
                    })
                    
            except Exception as e:
                logger.error(f"Error searching for amenities: {e}")
                
        return amenities