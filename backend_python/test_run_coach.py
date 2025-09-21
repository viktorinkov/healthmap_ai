#!/usr/bin/env python3
"""
Test script for Run Coach API endpoints
"""

import requests
import json
from datetime import datetime

# Base URL for the API
BASE_URL = "http://localhost:5001/api/run-coach"

# Test location (Rice University, Houston)
TEST_LOCATION = {"lat": 29.7174, "lon": -95.4018}

# Mock user profile
TEST_USER_PROFILE = {
    "user_id": "test_user_123",
    "health_conditions": ["asthma"],
    "age_group": "25-34",
    "fitness_level": "intermediate",
    "resting_hr": 55,
    "avg_hrv": 45,
    "vo2_max_estimate": 48
}

# Test preferences
TEST_PREFERENCES = {
    "preferred_distance_m": 5000,
    "max_elevation_gain_m": 100,
    "avoid_traffic": True,
    "prioritize_parks": True
}


def test_health_check():
    """Test the health check endpoint"""
    print("\n1. Testing health check endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health-check")
        print(f"Status: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False


def test_route_recommendation():
    """Test the route recommendation endpoint"""
    print("\n2. Testing route recommendation endpoint...")
    try:
        payload = {
            "location": TEST_LOCATION,
            "user_profile": TEST_USER_PROFILE,
            "preferences": TEST_PREFERENCES
        }
        
        response = requests.post(
            f"{BASE_URL}/recommend-route",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"Route ID: {data['route']['id']}")
            print(f"Distance: {data['route']['distance_m']}m")
            print(f"Duration: {data['route']['duration_min']} min")
            print(f"Avg AQI: {data['route']['avg_aqi']}")
            print(f"Green Coverage: {data['route']['green_coverage'] * 100:.1f}%")
            print(f"Safety Score: {data['route']['safety_score'] * 100:.1f}%")
            print(f"Time Windows: {len(data['time_windows'])} found")
            return True
        else:
            print(f"Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"Error: {e}")
        return False


def test_optimal_times():
    """Test the optimal times endpoint"""
    print("\n3. Testing optimal times endpoint...")
    try:
        payload = {
            "location": TEST_LOCATION,
            "user_profile": TEST_USER_PROFILE,
            "duration_minutes": 45,
            "lookahead_hours": 24
        }
        
        response = requests.post(
            f"{BASE_URL}/optimal-times",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"Personal AQI Threshold: {data['personalized_threshold']}")
            print(f"\nOptimal Time Windows:")
            for window in data['optimal_windows']:
                start = datetime.fromisoformat(window['start'].replace('Z', '+00:00'))
                print(f"  - {start.strftime('%H:%M')} | AQI: {window['avg_aqi']} | Quality: {window['quality_rating']}")
            return True
        else:
            print(f"Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"Error: {e}")
        return False


def test_health_risk_assessment():
    """Test the health risk assessment endpoint"""
    print("\n4. Testing health risk assessment endpoint...")
    try:
        payload = {
            "user_profile": TEST_USER_PROFILE,
            "current_aqi": 75,
            "activity_type": "running"
        }
        
        response = requests.post(
            f"{BASE_URL}/health-risk-assessment",
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"Personal Threshold: {data['personal_threshold']} AQI")
            print(f"Current Risk Level: {data['current_risk_level']}")
            print(f"Exposure Budget:")
            budget = data['exposure_budget']
            print(f"  - Daily Limit: {budget['daily_limit']}")
            print(f"  - Weekly Limit: {budget['weekly_limit']}")
            print(f"  - Current Usage: {budget['usage_percentage']:.1f}%")
            return True
        else:
            print(f"Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"Error: {e}")
        return False


def test_pollution_heatmap():
    """Test the pollution heatmap endpoint"""
    print("\n5. Testing pollution heatmap endpoint...")
    try:
        params = {
            "lat": TEST_LOCATION["lat"],
            "lon": TEST_LOCATION["lon"],
            "radius_km": 5,
            "pollutant": "aqi"
        }
        
        response = requests.get(
            f"{BASE_URL}/pollution-heatmap",
            params=params
        )
        
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"Pollutant: {data['pollutant']}")
            print(f"Resolution: {data['resolution']}m")
            print(f"Grid Points: {len(data['values'])}x{len(data['values'][0]) if data['values'] else 0}")
            print(f"Timestamp: {data.get('timestamp', 'N/A')}")
            return True
        else:
            print(f"Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"Error: {e}")
        return False


def main():
    """Run all tests"""
    print("=" * 60)
    print("Run Coach API Test Suite")
    print("=" * 60)
    
    tests = [
        test_health_check,
        test_route_recommendation,
        test_optimal_times,
        test_health_risk_assessment,
        test_pollution_heatmap
    ]
    
    results = []
    for test in tests:
        results.append(test())
        print("-" * 60)
    
    # Summary
    print("\nTest Summary:")
    print("=" * 60)
    passed = sum(results)
    total = len(results)
    print(f"Passed: {passed}/{total} ({passed/total*100:.0f}%)")
    
    if passed == total:
        print("✅ All tests passed!")
    else:
        print("❌ Some tests failed. Check the output above.")


if __name__ == "__main__":
    main()