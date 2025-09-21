"""
Time window optimization for finding best running times
"""

import numpy as np
from typing import List, Dict, Tuple, Optional
from datetime import datetime, timedelta
import logging
from dataclasses import dataclass

from ..models import TimeWindow, UserProfile
from .air_quality_service import AirQualityService

logger = logging.getLogger(__name__)


@dataclass
class WeatherConditions:
    """Weather conditions for a time period"""
    temperature: float
    humidity: float
    wind_speed: float
    uv_index: float
    precipitation_probability: float
    visibility: float
    

class TimeWindowOptimizer:
    """
    Finds optimal time windows for running based on:
    - Air quality forecasts
    - Weather conditions
    - User preferences
    - Historical patterns
    """
    
    def __init__(self, air_quality_service: AirQualityService):
        self.air_quality_service = air_quality_service
        
        # Ideal conditions for running
        self.ideal_conditions = {
            'temperature': (10, 20),  # Celsius
            'humidity': (40, 60),     # Percentage
            'wind_speed': (0, 15),    # km/h
            'uv_index': (0, 5),       # UV index
            'precipitation': 0.2      # Max 20% chance
        }
        
    def find_optimal_windows(
        self,
        location: Tuple[float, float],
        user_profile: UserProfile,
        duration_minutes: int,
        lookahead_hours: int = 24,
        min_windows: int = 3
    ) -> List[TimeWindow]:
        """
        Find optimal time windows for outdoor running
        
        Args:
            location: (latitude, longitude)
            user_profile: User health and preferences
            duration_minutes: Planned activity duration
            lookahead_hours: How far ahead to look
            min_windows: Minimum number of windows to return
            
        Returns:
            List of optimal time windows ranked by quality
        """
        logger.info(f"Finding optimal windows for {duration_minutes}min run in next {lookahead_hours}h")
        
        # Get air quality forecast
        aqi_forecast = self.air_quality_service.get_forecast(location, lookahead_hours)
        
        # Get weather forecast (would integrate with weather API)
        weather_forecast = self._get_weather_forecast(location, lookahead_hours)
        
        # Calculate personalized AQI threshold
        from ..core.health_risk import HealthRiskCalculator
        risk_calc = HealthRiskCalculator()
        aqi_threshold = risk_calc.calculate_personal_threshold(user_profile, 'moderate')
        
        # Find candidate windows
        candidate_windows = self._identify_candidate_windows(
            aqi_forecast,
            weather_forecast,
            aqi_threshold,
            duration_minutes
        )
        
        # Score and rank windows
        scored_windows = self._score_windows(
            candidate_windows,
            user_profile,
            weather_forecast
        )
        
        # Ensure minimum windows
        if len(scored_windows) < min_windows:
            # Add suboptimal windows if necessary
            scored_windows.extend(
                self._find_fallback_windows(
                    aqi_forecast,
                    weather_forecast,
                    min_windows - len(scored_windows)
                )
            )
            
        return scored_windows[:min_windows]
        
    def _identify_candidate_windows(
        self,
        aqi_forecast: List[Dict],
        weather_forecast: List[WeatherConditions],
        aqi_threshold: float,
        duration_minutes: int
    ) -> List[Dict]:
        """Identify continuous time windows meeting criteria"""
        
        windows = []
        duration_hours = np.ceil(duration_minutes / 60)
        
        i = 0
        while i < len(aqi_forecast) - duration_hours + 1:
            # Check if window meets AQI criteria
            window_aqi = [aqi_forecast[j]['aqi'] for j in range(i, i + int(duration_hours))]
            
            if all(aqi < aqi_threshold for aqi in window_aqi):
                # Window meets AQI criteria
                window = {
                    'start_idx': i,
                    'end_idx': i + int(duration_hours),
                    'avg_aqi': np.mean(window_aqi),
                    'max_aqi': max(window_aqi),
                    'weather_score': self._calculate_weather_score(
                        weather_forecast[i:i + int(duration_hours)]
                    )
                }
                windows.append(window)
                
                # Skip ahead to avoid overlapping windows
                i += int(duration_hours)
            else:
                i += 1
                
        return windows
        
    def _score_windows(
        self,
        windows: List[Dict],
        user_profile: UserProfile,
        weather_forecast: List[WeatherConditions]
    ) -> List[TimeWindow]:
        """Score and rank time windows"""
        
        scored_windows = []
        current_time = datetime.now()
        
        for window in windows:
            start_time = current_time + timedelta(hours=window['start_idx'])
            end_time = current_time + timedelta(hours=window['end_idx'])
            
            # Calculate comprehensive score
            score = 0
            
            # AQI score (lower is better, normalize to 0-1)
            aqi_score = 1.0 - (window['avg_aqi'] / 200)  # Normalize to 200 AQI
            score += aqi_score * 0.4  # 40% weight
            
            # Weather score (already 0-1)
            score += window['weather_score'] * 0.3  # 30% weight
            
            # Time preference score
            time_score = self._calculate_time_preference_score(
                start_time,
                user_profile
            )
            score += time_score * 0.2  # 20% weight
            
            # Circadian rhythm score
            circadian_score = self._calculate_circadian_score(start_time.hour)
            score += circadian_score * 0.1  # 10% weight
            
            # Create TimeWindow object
            time_window = TimeWindow(
                start=start_time,
                end=end_time,
                avg_aqi=window['avg_aqi'],
                weather_score=window['weather_score'],
                confidence=0.8,  # Forecast confidence
                factors={
                    'aqi_score': aqi_score,
                    'weather_score': window['weather_score'],
                    'time_preference': time_score,
                    'circadian_score': circadian_score,
                    'overall_score': score
                }
            )
            scored_windows.append(time_window)
            
        # Sort by overall score (descending)
        scored_windows.sort(key=lambda x: x.factors['overall_score'], reverse=True)
        
        return scored_windows
        
    def _calculate_weather_score(self, weather_conditions: List[WeatherConditions]) -> float:
        """Calculate weather quality score (0-1)"""
        
        if not weather_conditions:
            return 0.5  # Neutral score if no data
            
        scores = []
        
        for conditions in weather_conditions:
            score = 1.0
            
            # Temperature score
            temp = conditions.temperature
            if self.ideal_conditions['temperature'][0] <= temp <= self.ideal_conditions['temperature'][1]:
                temp_score = 1.0
            else:
                # Penalize based on deviation
                if temp < self.ideal_conditions['temperature'][0]:
                    temp_score = max(0, 1 - (self.ideal_conditions['temperature'][0] - temp) / 10)
                else:
                    temp_score = max(0, 1 - (temp - self.ideal_conditions['temperature'][1]) / 10)
            score *= temp_score
            
            # Humidity score
            humidity = conditions.humidity
            if self.ideal_conditions['humidity'][0] <= humidity <= self.ideal_conditions['humidity'][1]:
                humidity_score = 1.0
            else:
                humidity_score = max(0, 1 - abs(humidity - 50) / 50)
            score *= humidity_score
            
            # Wind score
            wind = conditions.wind_speed
            if wind <= self.ideal_conditions['wind_speed'][1]:
                wind_score = 1.0 - (wind / 30)  # Gradually decrease
            else:
                wind_score = 0.3  # High wind penalty
            score *= wind_score
            
            # Precipitation penalty
            if conditions.precipitation_probability > self.ideal_conditions['precipitation']:
                score *= (1 - conditions.precipitation_probability)
                
            # UV index consideration
            if conditions.uv_index > self.ideal_conditions['uv_index'][1]:
                score *= 0.7  # High UV penalty
                
            scores.append(score)
            
        return np.mean(scores)
        
    def _calculate_time_preference_score(
        self,
        start_time: datetime,
        user_profile: UserProfile
    ) -> float:
        """Calculate score based on user's time preferences"""
        
        hour = start_time.hour
        preferred_time = getattr(user_profile, 'preferred_time_of_day', 'morning')
        
        if preferred_time == 'morning':
            if 5 <= hour <= 9:
                return 1.0
            elif 9 < hour <= 11:
                return 0.7
            else:
                return 0.3
                
        elif preferred_time == 'evening':
            if 17 <= hour <= 20:
                return 1.0
            elif 15 <= hour < 17:
                return 0.7
            else:
                return 0.3
                
        elif preferred_time == 'afternoon':
            if 12 <= hour <= 16:
                return 1.0
            elif 10 <= hour < 12 or 16 < hour <= 18:
                return 0.7
            else:
                return 0.3
                
        else:  # any time
            return 0.8
            
    def _calculate_circadian_score(self, hour: int) -> float:
        """Calculate score based on circadian rhythm for exercise"""
        
        # Optimal exercise times based on circadian biology
        if 6 <= hour <= 8:  # Early morning
            return 0.9
        elif 16 <= hour <= 19:  # Late afternoon/early evening
            return 1.0  # Peak performance time
        elif 9 <= hour <= 11:  # Mid-morning
            return 0.8
        elif 14 <= hour <= 16:  # Mid-afternoon
            return 0.7
        elif 5 <= hour < 6 or 19 < hour <= 20:  # Very early/late
            return 0.5
        else:  # Night time
            return 0.2
            
    def _get_weather_forecast(
        self,
        location: Tuple[float, float],
        hours: int
    ) -> List[WeatherConditions]:
        """
        Get weather forecast
        Note: This would integrate with a weather API
        """
        # Placeholder implementation
        # In production, this would call OpenWeatherMap or similar
        forecast = []
        
        for i in range(hours):
            # Simulate weather conditions
            hour_of_day = (datetime.now().hour + i) % 24
            
            # Simple temperature model
            if 6 <= hour_of_day <= 10:
                temp = 15 + i * 0.5
            elif 11 <= hour_of_day <= 16:
                temp = 20 + (16 - hour_of_day) * 0.5
            else:
                temp = 15 - (hour_of_day - 16) * 0.3
                
            conditions = WeatherConditions(
                temperature=temp,
                humidity=50 + np.random.normal(0, 10),
                wind_speed=10 + np.random.normal(0, 5),
                uv_index=max(0, 5 * np.sin(np.pi * hour_of_day / 24)),
                precipitation_probability=0.1,
                visibility=10
            )
            forecast.append(conditions)
            
        return forecast
        
    def _find_fallback_windows(
        self,
        aqi_forecast: List[Dict],
        weather_forecast: List[WeatherConditions],
        num_windows: int
    ) -> List[TimeWindow]:
        """Find suboptimal windows when not enough ideal windows exist"""
        
        # Relax criteria and find best available windows
        all_windows = []
        current_time = datetime.now()
        
        for i in range(len(aqi_forecast) - 1):
            score = (200 - aqi_forecast[i]['aqi']) / 200  # Simple AQI score
            
            all_windows.append(TimeWindow(
                start=current_time + timedelta(hours=i),
                end=current_time + timedelta(hours=i+1),
                avg_aqi=aqi_forecast[i]['aqi'],
                weather_score=0.5,  # Neutral
                confidence=0.6,  # Lower confidence
                factors={'overall_score': score}
            ))
            
        # Sort by score and return requested number
        all_windows.sort(key=lambda x: x.factors['overall_score'], reverse=True)
        return all_windows[:num_windows]
        
    def suggest_weekly_schedule(
        self,
        location: Tuple[float, float],
        user_profile: UserProfile,
        runs_per_week: int = 3
    ) -> Dict[str, List[TimeWindow]]:
        """
        Suggest optimal running schedule for the week
        
        Args:
            location: Running location
            user_profile: User profile
            runs_per_week: Target number of runs
            
        Returns:
            Dictionary with daily recommendations
        """
        schedule = {}
        
        # Get 7-day forecast
        windows_per_day = []
        
        for day in range(7):
            day_windows = self.find_optimal_windows(
                location,
                user_profile,
                duration_minutes=45,  # Standard run
                lookahead_hours=24,
                min_windows=2
            )
            windows_per_day.append(day_windows)
            
        # Distribute runs across week
        # Prefer non-consecutive days for recovery
        selected_days = []
        day_scores = []
        
        for day, windows in enumerate(windows_per_day):
            best_window_score = max(w.factors['overall_score'] for w in windows)
            day_scores.append((day, best_window_score))
            
        # Sort days by best window score
        day_scores.sort(key=lambda x: x[1], reverse=True)
        
        # Select days with spacing
        for day, score in day_scores:
            if len(selected_days) >= runs_per_week:
                break
                
            # Check spacing (prefer at least 1 day gap)
            if not selected_days or all(abs(day - d) > 1 for d in selected_days):
                selected_days.append(day)
                
        # Fill schedule
        for day in range(7):
            date = datetime.now().date() + timedelta(days=day)
            if day in selected_days:
                schedule[date.strftime('%A')] = windows_per_day[day][:1]  # Best window
            else:
                schedule[date.strftime('%A')] = []  # Rest day
                
        return schedule