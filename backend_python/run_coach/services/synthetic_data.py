"""
Synthetic air quality data for demonstration purposes
Simulates pollution hotspots around Houston for hackathon demo
"""

import random
from datetime import datetime
from typing import List, Tuple
import numpy as np

from ..models import PollutantData


def generate_synthetic_pollution_data(
    center: Tuple[float, float], 
    radius_km: float = 10,
    num_points: int = 50
) -> List[PollutantData]:
    """
    Generate synthetic pollution data with realistic patterns for Houston area
    
    Creates:
    - High pollution zones near highways (I-610, US-59)
    - Moderate pollution in industrial areas
    - Lower pollution in residential/park areas
    - Clean air zones around Rice University campus
    """
    synthetic_data = []
    center_lat, center_lon = center
    
    # Define pollution zones around Houston
    pollution_zones = [
        # High pollution areas (highways and industrial)
        {"center": (29.7304, -95.4248), "radius": 0.02, "aqi_range": (100, 150), "name": "I-610 West"},
        {"center": (29.7404, -95.3648), "radius": 0.015, "aqi_range": (80, 120), "name": "US-59"},
        {"center": (29.6904, -95.4148), "radius": 0.018, "aqi_range": (90, 140), "name": "Industrial Area"},
        {"center": (29.7504, -95.4348), "radius": 0.02, "aqi_range": (85, 125), "name": "Galleria Traffic"},
        
        # Moderate pollution areas
        {"center": (29.7204, -95.3848), "radius": 0.015, "aqi_range": (60, 90), "name": "Medical Center"},
        {"center": (29.7004, -95.4048), "radius": 0.012, "aqi_range": (50, 80), "name": "West University"},
        
        # Clean areas (parks and campus)
        {"center": (29.7174, -95.4018), "radius": 0.008, "aqi_range": (20, 40), "name": "Rice University"},
        {"center": (29.7274, -95.3918), "radius": 0.01, "aqi_range": (25, 45), "name": "Hermann Park"},
        {"center": (29.7074, -95.3818), "radius": 0.008, "aqi_range": (30, 50), "name": "Brays Bayou"},
    ]
    
    # Generate points
    for i in range(num_points):
        # Randomly select a zone or create a background point
        if random.random() < 0.7:  # 70% chance of being in a zone
            zone = random.choice(pollution_zones)
            
            # Generate point within zone
            angle = random.uniform(0, 2 * np.pi)
            distance = random.uniform(0, zone["radius"])
            lat = zone["center"][0] + distance * np.cos(angle)
            lon = zone["center"][1] + distance * np.sin(angle) / np.cos(np.radians(zone["center"][0]))
            
            # Generate AQI based on zone and distance from center
            zone_center_distance = distance / zone["radius"]  # 0 to 1
            aqi_min, aqi_max = zone["aqi_range"]
            # Higher pollution at center of zone
            aqi = aqi_max - (aqi_max - aqi_min) * zone_center_distance
            aqi += random.uniform(-10, 10)  # Add noise
            
        else:
            # Background pollution
            angle = random.uniform(0, 2 * np.pi)
            distance = random.uniform(0, radius_km / 111)  # Convert km to degrees
            lat = center_lat + distance * np.cos(angle)
            lon = center_lon + distance * np.sin(angle) / np.cos(np.radians(center_lat))
            
            # Background AQI
            aqi = random.uniform(40, 70)
        
        # Ensure AQI is positive
        aqi = max(0, aqi)
        
        # Calculate other pollutants based on AQI
        # Simplified relationships
        pm25 = aqi * 0.3 + random.uniform(-5, 5)
        pm10 = pm25 * 1.8 + random.uniform(-10, 10)
        o3 = 50 + aqi * 0.5 + random.uniform(-10, 10)
        no2 = aqi * 0.4 + random.uniform(-5, 5)
        
        # Ensure all values are positive
        pm25 = max(0, pm25)
        pm10 = max(0, pm10)
        o3 = max(0, o3)
        no2 = max(0, no2)
        
        synthetic_data.append(
            PollutantData(
                location=(lat, lon),
                timestamp=datetime.now(),
                aqi=aqi,
                pm25=pm25,
                pm10=pm10,
                o3=o3,
                no2=no2,
                co=random.uniform(0, 2),  # Low CO levels
                so2=random.uniform(0, 5),  # Low SO2 levels
                source="synthetic_demo",
                confidence=0.95
            )
        )
    
    return synthetic_data


def add_traffic_pollution_corridor(
    data: List[PollutantData],
    start: Tuple[float, float],
    end: Tuple[float, float],
    width_deg: float = 0.005,
    aqi_range: Tuple[float, float] = (80, 120),
    num_points: int = 20
) -> List[PollutantData]:
    """
    Add a corridor of high pollution along a road/highway
    """
    start_lat, start_lon = start
    end_lat, end_lon = end
    
    for i in range(num_points):
        # Point along the line
        t = i / (num_points - 1)
        lat = start_lat + t * (end_lat - start_lat)
        lon = start_lon + t * (end_lon - start_lon)
        
        # Add perpendicular offset
        perpendicular_angle = np.arctan2(end_lon - start_lon, end_lat - start_lat) + np.pi/2
        offset = random.uniform(-width_deg, width_deg)
        lat += offset * np.cos(perpendicular_angle)
        lon += offset * np.sin(perpendicular_angle)
        
        # AQI varies along the corridor
        aqi = random.uniform(*aqi_range)
        pm25 = aqi * 0.3 + random.uniform(-5, 5)
        
        data.append(
            PollutantData(
                location=(lat, lon),
                timestamp=datetime.now(),
                aqi=aqi,
                pm25=max(0, pm25),
                pm10=max(0, pm25 * 1.8),
                o3=max(0, 50 + aqi * 0.5),
                no2=max(0, aqi * 0.4),
                co=random.uniform(0, 3),
                so2=random.uniform(0, 5),
                source="synthetic_traffic",
                confidence=0.9
            )
        )
    
    return data