#!/usr/bin/env python3
"""Test air quality API integration"""

import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from run_coach.services.air_quality_service import AirQualityService
from run_coach.models import PollutantData

# Test location - Rice University, Houston
location = (29.7174, -95.4018)

print("Testing Air Quality APIs for Rice University, Houston...\n")

# Initialize service
service = AirQualityService()

print("=== API Keys Status ===")
print(f"OpenWeather API Key: {'✓' if service.openweather_key else '✗'}")
print(f"AirNow API Key: {'✓' if service.airnow_key else '✗'}")
print(f"PurpleAir API Key: {'✓' if service.purpleair_key else '✗'}")

print(f"\n=== Testing OpenWeather API ===")
print(f"Location: Rice University (lat: {location[0]}, lon: {location[1]})")
try:
    # Test OpenWeather directly
    openweather_data = service._fetch_openweather_data(location[0], location[1])
    if openweather_data:
        print(f"✓ Got {len(openweather_data)} data points from OpenWeather")
        for data in openweather_data[:1]:
            print(f"  Location: {data.location}")
            print(f"  AQI: {data.aqi}")
            print(f"  PM2.5: {data.pm25} µg/m³")
            print(f"  PM10: {data.pm10} µg/m³")
            print(f"  O3: {data.o3} µg/m³")
    else:
        print("✗ No data from OpenWeather")
except Exception as e:
    print(f"✗ Error: {e}")

print(f"\n=== Testing AirNow API ===")
try:
    # Test AirNow directly
    airnow_data = service._fetch_airnow_data(location[0], location[1], 50)
    if airnow_data:
        print(f"✓ Got {len(airnow_data)} data points from AirNow")
        for data in airnow_data[:1]:
            print(f"  Location: {data.location}")
            print(f"  AQI: {data.aqi}")
            print(f"  PM2.5: {data.pm25}")
    else:
        print("✗ No data from AirNow")
except Exception as e:
    print(f"✗ Error: {e}")

print(f"\n=== Testing Combined Data ===")
try:
    # Test combined data
    all_data = service.get_current_air_quality(location, radius_km=50)
    print(f"Total data points: {len(all_data)}")
    
    if all_data:
        print("\nFirst data point:")
        data = all_data[0]
        print(f"  Source: {data.source}")
        print(f"  Location: {data.location}")
        print(f"  AQI: {data.aqi}")
        print(f"  PM2.5: {data.pm25}")
        print(f"  Timestamp: {data.timestamp}")
except Exception as e:
    print(f"Error: {e}")

print(f"\n=== Testing Forecast ===")
try:
    forecast = service.get_forecast(location, hours=6)
    if forecast:
        print(f"✓ Got {len(forecast)} hour forecast")
        for hour in forecast[:3]:
            print(f"  {hour['timestamp']}: AQI {hour['aqi']:.0f}, PM2.5 {hour['pm25']:.1f}")
    else:
        print("✗ No forecast data")
except Exception as e:
    print(f"✗ Error: {e}")