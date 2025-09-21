#!/usr/bin/env python3
"""Detailed test of route recommendation"""

import requests
import json

# Test with a specific San Francisco location
payload = {
    "location": {"lat": 29.7174, "lon": -95.4018},  # Rice University, Houston
    "user_profile": {
        "user_id": "test_user",
        "health_conditions": ["asthma"],  # Test with health condition
        "age_group": "25-34",
        "fitness_level": "intermediate",
        "resting_hr": 55,
        "avg_hrv": 45
    },
    "preferences": {
        "preferred_distance_m": 5000,
        "max_elevation_gain_m": 100,
        "avoid_traffic": True,
        "prioritize_parks": True
    }
}

print("Testing Run Coach Route Recommendation with detailed output...\n")

response = requests.post(
    "http://localhost:5001/api/run-coach/recommend-route",
    json=payload,
    headers={"Content-Type": "application/json"}
)

if response.status_code == 200:
    data = response.json()
    
    print("=== ROUTE DETAILS ===")
    route = data['route']
    print(f"Route ID: {route['id']}")
    print(f"Distance: {route['distance_m']/1000:.2f} km")
    print(f"Duration: {route['duration_min']:.1f} minutes")
    print(f"Pace: {route['duration_min']/(route['distance_m']/1000):.1f} min/km")
    print(f"Elevation Gain: {route['elevation_gain_m']}m")
    print(f"\nAir Quality:")
    print(f"  Average AQI: {route['avg_aqi']}")
    print(f"  Max AQI: {route['max_aqi']}")
    print(f"  Exposure Score: {route['exposure_score']}")
    print(f"\nRoute Features:")
    print(f"  Green Coverage: {route['green_coverage']*100:.1f}%")
    print(f"  Safety Score: {route['safety_score']*100:.1f}%")
    
    print(f"\n=== ROUTE SEGMENTS ({len(data['segments'])} segments) ===")
    for i, segment in enumerate(data['segments'][:3]):  # Show first 3 segments
        print(f"\nSegment {i+1}:")
        print(f"  Distance: {segment['distance_m']:.0f}m")
        print(f"  AQI: {segment['aqi']}")
        print(f"  PM2.5: {segment['pm25']} µg/m³")
        print(f"  Recommended Pace: {segment['recommended_pace']}")
    
    print(f"\n=== OPTIMAL TIME WINDOWS ===")
    for window in data['time_windows'][:3]:
        print(f"\n{window['start'].split('T')[1][:5]} - {window['end'].split('T')[1][:5]}")
        print(f"  AQI: {window['avg_aqi']:.0f}")
        print(f"  Quality: {window['quality']}")
        print(f"  Confidence: {window['confidence']*100:.0f}%")
    
    print(f"\n=== HEALTH RECOMMENDATIONS ===")
    rec = data['health_recommendation']['current']
    print(f"Status: {rec['status']}")
    print(f"Advice: {rec['advice']}")
    print(f"Personal AQI Threshold: {rec['threshold']}")
    
else:
    print(f"Error: {response.status_code}")
    print(response.text)