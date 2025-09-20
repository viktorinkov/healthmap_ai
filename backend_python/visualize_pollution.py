#!/usr/bin/env python3
"""Visualize pollution heatmap data"""

import requests
import numpy as np
import json

# Rice University location
TEST_LOCATION = {"lat": 29.7174, "lon": -95.4018}

print("Fetching pollution heatmap data...")

params = {
    "lat": TEST_LOCATION["lat"],
    "lon": TEST_LOCATION["lon"],
    "radius_km": 5,
    "pollutant": "aqi"
}

response = requests.get(
    "http://localhost:5001/api/run-coach/pollution-heatmap",
    params=params
)

if response.status_code == 200:
    data = response.json()
    
    print(f"\nPollution Heatmap Summary:")
    print(f"Bounds: ({data['bounds']['min_lat']:.4f}, {data['bounds']['min_lon']:.4f}) to ({data['bounds']['max_lat']:.4f}, {data['bounds']['max_lon']:.4f})")
    print(f"Resolution: {data['resolution']}m")
    print(f"Grid size: {len(data['values'])}x{len(data['values'][0])}")
    
    # Convert to numpy array for analysis
    values = np.array(data['values'])
    
    print(f"\nAQI Statistics:")
    print(f"Min AQI: {np.min(values):.1f}")
    print(f"Max AQI: {np.max(values):.1f}")
    print(f"Mean AQI: {np.mean(values):.1f}")
    print(f"Std Dev: {np.std(values):.1f}")
    
    # Find high pollution zones (AQI > 80)
    high_pollution = np.where(values > 80)
    print(f"\nHigh pollution zones (AQI > 80): {len(high_pollution[0])} grid points")
    
    # Find clean zones (AQI < 40)
    clean_zones = np.where(values < 40)
    print(f"Clean zones (AQI < 40): {len(clean_zones[0])} grid points")
    
    # Sample some high pollution coordinates
    if len(high_pollution[0]) > 0:
        print("\nSample high pollution locations:")
        for i in range(min(3, len(high_pollution[0]))):
            row = high_pollution[0][i]
            col = high_pollution[1][i]
            lat = data['bounds']['min_lat'] + (row / len(values)) * (data['bounds']['max_lat'] - data['bounds']['min_lat'])
            lon = data['bounds']['min_lon'] + (col / len(values[0])) * (data['bounds']['max_lon'] - data['bounds']['min_lon'])
            print(f"  - ({lat:.4f}, {lon:.4f}): AQI = {values[row, col]:.1f}")
    
    print("\n✅ Synthetic pollution data successfully integrated!")
    print("The algorithm should now avoid high-pollution areas when generating routes.")
    
else:
    print(f"Error: {response.status_code}")
    print(response.text)