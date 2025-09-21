"""
Multi-objective Pareto optimization for running routes
"""

import numpy as np
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
import logging

from ..models import (
    UserProfile, RunningPreferences, RouteRecommendation, 
    RouteSegment, PollutantData
)
from .pollution_grid import PollutionGrid

logger = logging.getLogger(__name__)


class RunCoachOptimizer:
    """
    Multi-objective optimization for running routes considering:
    - Air quality exposure minimization
    - Distance/duration preferences
    - Elevation gain constraints
    - Traffic/safety factors
    - Green space maximization
    """
    
    def __init__(self, pollution_grid: PollutionGrid):
        self.pollution_grid = pollution_grid
        self.pareto_solutions = []
        
    def optimize_route(
        self, 
        start_point: Tuple[float, float],
        user_profile: UserProfile,
        preferences: RunningPreferences,
        candidate_routes: List[Dict]
    ) -> RouteRecommendation:
        """
        Find optimal running route using Pareto optimization
        
        Args:
            start_point: Starting location (lat, lon)
            user_profile: User health and fitness profile
            preferences: Running preferences and constraints
            candidate_routes: List of potential routes from route generator
            
        Returns:
            Optimal route recommendation
        """
        logger.info(f"Optimizing route from {start_point} with {len(candidate_routes)} candidates")
        
        # Calculate objectives for each route
        evaluated_routes = []
        for route in candidate_routes:
            objectives = self._calculate_objectives(route, user_profile, preferences)
            route['objectives'] = objectives
            evaluated_routes.append(route)
            
        # Find Pareto optimal solutions
        pareto_front = self._find_pareto_optimal_routes(evaluated_routes)
        logger.info(f"Found {len(pareto_front)} Pareto optimal routes")
        
        # Rank solutions based on user preferences
        best_route = self._rank_by_preferences(pareto_front, user_profile, preferences)
        
        # Convert to RouteRecommendation
        recommendation = self._create_recommendation(best_route, user_profile)
        
        return recommendation
        
    def _calculate_objectives(
        self, 
        route: Dict,
        user_profile: UserProfile,
        preferences: RunningPreferences
    ) -> Dict[str, float]:
        """Calculate multiple objective values for a route"""
        
        # Extract route geometry
        waypoints = route['geometry']
        
        # 1. Air Quality Exposure (minimize)
        exposure_score = self._calculate_exposure_score(waypoints, route.get('duration_min', 30))
        
        # 2. Distance Error (minimize deviation from preferred)
        distance_error = abs(route['distance_m'] - preferences.preferred_distance_m) / preferences.preferred_distance_m
        
        # 3. Elevation Gain (minimize if over threshold)
        elevation_penalty = max(0, route['elevation_gain_m'] - preferences.max_elevation_gain_m) / 100
        
        # 4. Green Space Coverage (maximize -> minimize negative)
        green_score = -route.get('green_coverage', 0)
        
        # 5. Safety Score (maximize -> minimize negative)
        safety_score = -route.get('safety_score', 0.5)
        
        return {
            'exposure': exposure_score,
            'distance_error': distance_error,
            'elevation_penalty': elevation_penalty,
            'green_space': green_score,
            'safety': safety_score
        }
        
    def _calculate_exposure_score(self, waypoints: List[Tuple[float, float]], duration_min: float) -> float:
        """
        Calculate cumulative pollutant exposure along route
        
        Uses time-weighted integration of pollutant concentrations
        accounting for increased breathing rate during exercise
        """
        total_exposure = 0.0
        num_points = len(waypoints)
        
        if num_points < 2:
            return 0.0
            
        # Time spent at each segment
        time_per_segment = duration_min / (num_points - 1)
        
        # Exercise ventilation multiplier (2.5x resting rate for moderate pace)
        ventilation_multiplier = 2.5
        
        for i in range(num_points - 1):
            # Get pollution data at midpoint
            midpoint = (
                (waypoints[i][0] + waypoints[i+1][0]) / 2,
                (waypoints[i][1] + waypoints[i+1][1]) / 2
            )
            
            # Get interpolated pollution values
            aqi = self.pollution_grid.get_aqi_at_point(midpoint)
            pm25 = self.pollution_grid.get_pm25_at_point(midpoint)
            
            # Calculate exposure for this segment
            # Using PM2.5 as primary metric with AQI weighting
            segment_exposure = (pm25 * 0.7 + aqi * 0.3) * time_per_segment * ventilation_multiplier
            total_exposure += segment_exposure
            
        # Normalize by duration to get exposure rate
        exposure_rate = total_exposure / duration_min
        
        return exposure_rate
        
    def _find_pareto_optimal_routes(self, routes: List[Dict]) -> List[Dict]:
        """
        Find Pareto optimal solutions using non-dominated sorting
        
        A solution dominates another if it's better in at least one objective
        and not worse in any other objective
        """
        n = len(routes)
        if n == 0:
            return []
            
        # Track domination counts
        domination_count = [0] * n
        dominated_by = [[] for _ in range(n)]
        
        # Compare all pairs
        for i in range(n):
            for j in range(i + 1, n):
                dominance = self._check_dominance(
                    routes[i]['objectives'],
                    routes[j]['objectives']
                )
                
                if dominance == 1:  # i dominates j
                    dominated_by[i].append(j)
                    domination_count[j] += 1
                elif dominance == -1:  # j dominates i
                    dominated_by[j].append(i)
                    domination_count[i] += 1
                    
        # Extract Pareto front (non-dominated solutions)
        pareto_front = []
        for i in range(n):
            if domination_count[i] == 0:
                pareto_front.append(routes[i])
                
        return pareto_front
        
    def _check_dominance(self, obj1: Dict[str, float], obj2: Dict[str, float]) -> int:
        """
        Check dominance relationship between two objective vectors
        
        Returns:
            1 if obj1 dominates obj2
            -1 if obj2 dominates obj1
            0 if neither dominates
        """
        better_in_any = False
        worse_in_any = False
        
        for key in obj1:
            if obj1[key] < obj2[key]:
                better_in_any = True
            elif obj1[key] > obj2[key]:
                worse_in_any = True
                
        if better_in_any and not worse_in_any:
            return 1
        elif worse_in_any and not better_in_any:
            return -1
        else:
            return 0
            
    def _rank_by_preferences(
        self, 
        pareto_front: List[Dict],
        user_profile: UserProfile,
        preferences: RunningPreferences
    ) -> Dict:
        """
        Rank Pareto optimal solutions based on user preferences
        
        Uses weighted scoring with personalized weights
        """
        if not pareto_front:
            raise ValueError("No Pareto optimal solutions found")
            
        # Define preference weights based on user profile
        weights = self._get_preference_weights(user_profile, preferences)
        
        best_score = float('inf')
        best_route = None
        
        for route in pareto_front:
            # Calculate weighted score
            score = 0
            for obj_name, obj_value in route['objectives'].items():
                score += weights.get(obj_name, 1.0) * abs(obj_value)
                
            if score < best_score:
                best_score = score
                best_route = route
                
        return best_route
        
    def _get_preference_weights(
        self,
        user_profile: UserProfile,
        preferences: RunningPreferences
    ) -> Dict[str, float]:
        """Get personalized objective weights based on user profile"""
        
        weights = {
            'exposure': 1.0,
            'distance_error': 0.5,
            'elevation_penalty': 0.3,
            'green_space': 0.4,
            'safety': 0.5
        }
        
        # Increase exposure weight for sensitive users
        if user_profile.has_asthma or user_profile.has_copd:
            weights['exposure'] = 2.0
            
        # Increase green space weight for allergy sufferers
        if user_profile.has_allergies:
            weights['green_space'] = 0.8
            
        # Adjust based on preferences
        if preferences.avoid_traffic:
            weights['safety'] = 0.8
            
        if preferences.prioritize_parks:
            weights['green_space'] = 0.9
            
        return weights
        
    def _create_recommendation(self, route: Dict, user_profile: UserProfile) -> RouteRecommendation:
        """Convert optimized route to RouteRecommendation format"""
        
        # Create route segments with pollution data
        segments = []
        waypoints = route['geometry']
        
        for i in range(len(waypoints) - 1):
            segment = RouteSegment(
                start_point=waypoints[i],
                end_point=waypoints[i+1],
                distance_m=self._calculate_segment_distance(waypoints[i], waypoints[i+1]),
                aqi=self.pollution_grid.get_aqi_at_point(waypoints[i]),
                pm25=self.pollution_grid.get_pm25_at_point(waypoints[i]),
                elevation_change_m=0,  # TODO: Get from elevation API
                recommended_pace=self._get_recommended_pace(
                    self.pollution_grid.get_aqi_at_point(waypoints[i]),
                    user_profile
                )
            )
            segments.append(segment)
            
        return RouteRecommendation(
            route_id=route.get('route_id', 'generated'),
            geometry=waypoints,
            encoded_polyline=route.get('encoded_polyline', ''),
            segments=segments,
            total_distance_m=route['distance_m'],
            duration_min=route['duration_min'],
            avg_aqi=route['objectives']['exposure'] / 2.5,  # Rough conversion
            max_aqi=max(s.aqi for s in segments),
            exposure_score=route['objectives']['exposure'],
            elevation_gain_m=route.get('elevation_gain_m', 0),
            green_coverage=abs(route['objectives']['green_space']),
            safety_score=abs(route['objectives']['safety'])
        )
        
    def _calculate_segment_distance(self, point1: Tuple[float, float], point2: Tuple[float, float]) -> float:
        """Calculate distance between two points using Haversine formula"""
        from math import radians, cos, sin, asin, sqrt
        
        # Radius of Earth in meters
        R = 6371000
        
        lat1, lon1 = radians(point1[0]), radians(point1[1])
        lat2, lon2 = radians(point2[0]), radians(point2[1])
        
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        
        a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
        c = 2 * asin(sqrt(a))
        
        return R * c
        
    def _get_recommended_pace(self, aqi: float, user_profile: UserProfile) -> str:
        """Get recommended pace based on AQI and user sensitivity"""
        
        # Adjust threshold based on user conditions
        threshold = 100
        if user_profile.has_asthma:
            threshold *= 0.6
        if user_profile.has_copd:
            threshold *= 0.5
            
        if aqi > threshold:
            return "walk"
        elif aqi > threshold * 0.7:
            return "easy"
        else:
            return "moderate"