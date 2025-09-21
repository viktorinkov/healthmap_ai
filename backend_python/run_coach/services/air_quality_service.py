"""
Air quality data aggregation service
Integrates multiple AQI data sources for comprehensive coverage
"""

import os
import requests
from typing import List, Dict, Tuple, Optional
from datetime import datetime, timedelta
import logging
import numpy as np
from dotenv import load_dotenv

from ..models import PollutantData

load_dotenv()
logger = logging.getLogger(__name__)


class AirQualityService:
    """
    Aggregates air quality data from multiple sources:
    - OpenWeatherMap Air Pollution API
    - EPA AirNow API
    - PurpleAir (if available)
    """
    
    def __init__(self):
        # API Keys
        self.openweather_key = os.getenv('OPENWEATHER_API_KEY')
        self.airnow_key = os.getenv('AIRNOW_API_KEY')
        self.purpleair_key = os.getenv('PURPLEAIR_API_KEY')
        
        # API Endpoints
        self.openweather_base = "http://api.openweathermap.org/data/2.5/air_pollution"
        self.airnow_base = "https://www.airnowapi.org/aq"
        
        # Cache for recent queries
        self.cache = {}
        self.cache_duration = 300  # 5 minutes
        
    def get_current_air_quality(
        self, 
        location: Tuple[float, float],
        radius_km: float = 50
    ) -> List[PollutantData]:
        """
        Get current air quality data from all available sources
        
        Args:
            location: (latitude, longitude) tuple
            radius_km: Search radius in kilometers
            
        Returns:
            List of PollutantData from various sources
        """
        lat, lon = location
        all_data = []
        
        # Check cache first
        cache_key = f"{lat:.3f},{lon:.3f},{radius_km}"
        if cache_key in self.cache:
            cached_time, cached_data = self.cache[cache_key]
            if datetime.now() - cached_time < timedelta(seconds=self.cache_duration):
                logger.info("Returning cached air quality data")
                return cached_data
                
        # Fetch from OpenWeatherMap
        if self.openweather_key:
            owm_data = self._fetch_openweather_data(lat, lon)
            if owm_data:
                all_data.extend(owm_data)
                
        # Fetch from AirNow
        if self.airnow_key:
            airnow_data = self._fetch_airnow_data(lat, lon, radius_km)
            if airnow_data:
                all_data.extend(airnow_data)
                
        # Fetch from PurpleAir (if available)
        if self.purpleair_key:
            purpleair_data = self._fetch_purpleair_data(lat, lon, radius_km)
            if purpleair_data:
                all_data.extend(purpleair_data)
        
        # Add synthetic data for demo purposes (hackathon)
        # REDUCED TO 15 POINTS FOR PERFORMANCE
        if os.getenv('DEMO_MODE', 'true').lower() == 'true':
            from .synthetic_data import generate_synthetic_pollution_data
            synthetic_data = generate_synthetic_pollution_data((lat, lon), radius_km, num_points=15)
            all_data.extend(synthetic_data)
            logger.info(f"Added {len(synthetic_data)} synthetic data points for demo")
                
        # Cache results
        self.cache[cache_key] = (datetime.now(), all_data)
        
        logger.info(f"Retrieved {len(all_data)} air quality measurements")
        return all_data
        
    def _fetch_openweather_data(self, lat: float, lon: float) -> List[PollutantData]:
        """Fetch data from OpenWeatherMap Air Pollution API"""
        
        try:
            url = f"{self.openweather_base}?lat={lat}&lon={lon}&appid={self.openweather_key}"
            response = requests.get(url, timeout=10)
            
            if response.status_code != 200:
                logger.error(f"OpenWeather API error: {response.status_code}")
                return []
                
            data = response.json()
            
            if 'list' not in data or not data['list']:
                return []
                
            # Parse the response
            result = []
            for item in data['list']:
                components = item.get('components', {})
                
                # Calculate AQI from components (simplified)
                aqi = self._calculate_aqi_from_components(components)
                
                pollutant_data = PollutantData(
                    location=(lat, lon),
                    timestamp=datetime.fromtimestamp(item['dt']),
                    aqi=aqi,
                    pm25=components.get('pm2_5', 0),
                    pm10=components.get('pm10', 0),
                    o3=components.get('o3', 0),
                    no2=components.get('no2', 0),
                    co=components.get('co', 0),
                    so2=components.get('so2', 0),
                    source='openweather',
                    confidence=0.9
                )
                result.append(pollutant_data)
                
            return result
            
        except Exception as e:
            logger.error(f"Error fetching OpenWeather data: {e}")
            return []
            
    def _fetch_airnow_data(self, lat: float, lon: float, radius_km: float) -> List[PollutantData]:
        """Fetch data from EPA AirNow API"""
        
        try:
            # Get data by coordinates
            url = f"{self.airnow_base}/observation/latLong/current/"
            params = {
                'format': 'application/json',
                'latitude': lat,
                'longitude': lon,
                'distance': int(radius_km),
                'API_KEY': self.airnow_key
            }
            
            response = requests.get(url, params=params, timeout=10)
            
            if response.status_code != 200:
                logger.error(f"AirNow API error: {response.status_code}")
                return []
                
            data = response.json()
            
            # Parse response and group by reporting area
            result = []
            areas = {}
            
            for obs in data:
                area_name = obs.get('ReportingArea', 'Unknown')
                if area_name not in areas:
                    areas[area_name] = {
                        'lat': obs.get('Latitude', lat),
                        'lon': obs.get('Longitude', lon),
                        'aqi': obs.get('AQI', 0)
                    }
                    
                # Store pollutant-specific data
                param = obs.get('ParameterName', '').lower()
                value = obs.get('AQI', 0)
                
                if 'pm2.5' in param:
                    areas[area_name]['pm25'] = value
                elif 'pm10' in param:
                    areas[area_name]['pm10'] = value
                elif 'ozone' in param or 'o3' in param:
                    areas[area_name]['o3'] = value
                elif 'no2' in param:
                    areas[area_name]['no2'] = value
                    
            # Convert to PollutantData objects
            for area_name, area_data in areas.items():
                pollutant_data = PollutantData(
                    location=(area_data['lat'], area_data['lon']),
                    timestamp=datetime.now(),
                    aqi=area_data.get('aqi', 0),
                    pm25=area_data.get('pm25', 0),
                    pm10=area_data.get('pm10', 0),
                    o3=area_data.get('o3', 0),
                    no2=area_data.get('no2', 0),
                    co=0,  # AirNow doesn't always provide CO
                    so2=0,  # AirNow doesn't always provide SO2
                    source='airnow',
                    confidence=1.0  # Official EPA data
                )
                result.append(pollutant_data)
                
            return result
            
        except Exception as e:
            logger.error(f"Error fetching AirNow data: {e}")
            return []
            
    def _fetch_purpleair_data(self, lat: float, lon: float, radius_km: float) -> List[PollutantData]:
        """Fetch data from PurpleAir API (crowdsourced sensors)"""
        
        # Note: PurpleAir API requires specific implementation
        # This is a placeholder for the actual implementation
        logger.info("PurpleAir integration not yet implemented")
        return []
        
    def _calculate_aqi_from_components(self, components: Dict) -> float:
        """
        Calculate AQI from pollutant components
        Uses simplified EPA formula focusing on PM2.5
        """
        pm25 = components.get('pm2_5', 0)
        
        # Simplified AQI calculation based on PM2.5
        # Real calculation would consider all pollutants
        if pm25 <= 12.0:
            aqi = self._linear_interpolation(pm25, 0, 12.0, 0, 50)
        elif pm25 <= 35.4:
            aqi = self._linear_interpolation(pm25, 12.1, 35.4, 51, 100)
        elif pm25 <= 55.4:
            aqi = self._linear_interpolation(pm25, 35.5, 55.4, 101, 150)
        elif pm25 <= 150.4:
            aqi = self._linear_interpolation(pm25, 55.5, 150.4, 151, 200)
        elif pm25 <= 250.4:
            aqi = self._linear_interpolation(pm25, 150.5, 250.4, 201, 300)
        else:
            aqi = self._linear_interpolation(pm25, 250.5, 500.4, 301, 500)
            
        return min(aqi, 500)  # Cap at 500
        
    def _linear_interpolation(
        self, 
        value: float,
        low_break: float,
        high_break: float,
        low_aqi: float,
        high_aqi: float
    ) -> float:
        """Linear interpolation for AQI calculation"""
        return ((high_aqi - low_aqi) / (high_break - low_break)) * (value - low_break) + low_aqi
        
    def get_forecast(
        self,
        location: Tuple[float, float],
        hours: int = 24
    ) -> List[Dict]:
        """
        Get air quality forecast for the next N hours
        
        Args:
            location: (latitude, longitude) tuple
            hours: Number of hours to forecast
            
        Returns:
            List of hourly forecasts with AQI predictions
        """
        lat, lon = location
        forecasts = []
        
        if self.openweather_key:
            try:
                # OpenWeatherMap provides 5-day forecast
                url = f"{self.openweather_base}/forecast?lat={lat}&lon={lon}&appid={self.openweather_key}"
                response = requests.get(url, timeout=10)
                
                if response.status_code == 200:
                    data = response.json()
                    
                    for item in data.get('list', [])[:hours]:
                        components = item.get('components', {})
                        aqi = self._calculate_aqi_from_components(components)
                        
                        forecasts.append({
                            'timestamp': datetime.fromtimestamp(item['dt']),
                            'aqi': aqi,
                            'pm25': components.get('pm2_5', 0),
                            'pm10': components.get('pm10', 0),
                            'confidence': 0.8  # Forecast confidence
                        })
                        
            except Exception as e:
                logger.error(f"Error fetching forecast: {e}")
                
        return forecasts
        
    def aggregate_measurements(
        self,
        measurements: List[PollutantData],
        method: str = 'weighted_average'
    ) -> PollutantData:
        """
        Aggregate multiple measurements into a single value
        
        Args:
            measurements: List of pollutant measurements
            method: Aggregation method ('weighted_average', 'median', 'worst_case')
            
        Returns:
            Aggregated PollutantData
        """
        if not measurements:
            raise ValueError("No measurements to aggregate")
            
        if len(measurements) == 1:
            return measurements[0]
            
        if method == 'weighted_average':
            # Weight by confidence scores
            weights = np.array([m.confidence for m in measurements])
            weights = weights / weights.sum()
            
            aqi = np.sum([m.aqi * w for m, w in zip(measurements, weights)])
            pm25 = np.sum([m.pm25 * w for m, w in zip(measurements, weights)])
            pm10 = np.sum([m.pm10 * w for m, w in zip(measurements, weights)])
            o3 = np.sum([m.o3 * w for m, w in zip(measurements, weights)])
            no2 = np.sum([m.no2 * w for m, w in zip(measurements, weights)])
            co = np.sum([m.co * w for m, w in zip(measurements, weights)])
            so2 = np.sum([m.so2 * w for m, w in zip(measurements, weights)])
            
        elif method == 'median':
            aqi = np.median([m.aqi for m in measurements])
            pm25 = np.median([m.pm25 for m in measurements])
            pm10 = np.median([m.pm10 for m in measurements])
            o3 = np.median([m.o3 for m in measurements])
            no2 = np.median([m.no2 for m in measurements])
            co = np.median([m.co for m in measurements])
            so2 = np.median([m.so2 for m in measurements])
            
        elif method == 'worst_case':
            aqi = max(m.aqi for m in measurements)
            pm25 = max(m.pm25 for m in measurements)
            pm10 = max(m.pm10 for m in measurements)
            o3 = max(m.o3 for m in measurements)
            no2 = max(m.no2 for m in measurements)
            co = max(m.co for m in measurements)
            so2 = max(m.so2 for m in measurements)
            
        else:
            raise ValueError(f"Unknown aggregation method: {method}")
            
        # Use centroid of locations
        avg_lat = np.mean([m.location[0] for m in measurements])
        avg_lon = np.mean([m.location[1] for m in measurements])
        
        return PollutantData(
            location=(avg_lat, avg_lon),
            timestamp=datetime.now(),
            aqi=aqi,
            pm25=pm25,
            pm10=pm10,
            o3=o3,
            no2=no2,
            co=co,
            so2=so2,
            source='aggregated',
            confidence=np.mean([m.confidence for m in measurements])
        )