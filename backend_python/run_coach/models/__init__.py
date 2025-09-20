"""Data models for Run Coach system"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple
from datetime import datetime


@dataclass
class UserProfile:
    """User health and fitness profile"""
    user_id: str
    health_conditions: List[str] = field(default_factory=list)
    age_group: str = "25-34"
    fitness_level: str = "intermediate"
    resting_hr: Optional[int] = None
    avg_hrv: Optional[float] = None
    vo2_max_estimate: Optional[float] = None
    
    @property
    def has_asthma(self) -> bool:
        return "asthma" in self.health_conditions
    
    @property
    def has_copd(self) -> bool:
        return "copd" in self.health_conditions
    
    @property
    def has_allergies(self) -> bool:
        return "allergies" in self.health_conditions
    
    @property
    def is_pregnant(self) -> bool:
        return "pregnant" in self.health_conditions


@dataclass
class RunningPreferences:
    """User running preferences and constraints"""
    preferred_distance_m: int = 5000
    max_elevation_gain_m: int = 100
    avoid_traffic: bool = True
    prioritize_parks: bool = True
    max_duration_min: int = 60
    preferred_time_of_day: str = "morning"


@dataclass
class RouteSegment:
    """Individual segment of a running route"""
    start_point: Tuple[float, float]
    end_point: Tuple[float, float]
    distance_m: float
    aqi: float
    pm25: float
    elevation_change_m: float
    surface_type: str = "road"
    recommended_pace: str = "moderate"
    green_space_coverage: float = 0.0


@dataclass
class RouteRecommendation:
    """Complete route recommendation with metrics"""
    route_id: str
    geometry: List[Tuple[float, float]]
    encoded_polyline: str
    segments: List[RouteSegment]
    total_distance_m: float
    duration_min: float
    avg_aqi: float
    max_aqi: float
    exposure_score: float
    elevation_gain_m: float
    green_coverage: float
    safety_score: float
    generated_at: datetime = field(default_factory=datetime.now)


@dataclass
class TimeWindow:
    """Optimal time window for running"""
    start: datetime
    end: datetime
    avg_aqi: float
    weather_score: float
    confidence: float
    factors: Dict[str, float] = field(default_factory=dict)


@dataclass
class PollutantData:
    """Air quality and pollutant data at a location"""
    location: Tuple[float, float]
    timestamp: datetime
    aqi: float
    pm25: float
    pm10: float
    o3: float
    no2: float
    co: float
    so2: float
    source: str
    confidence: float = 1.0