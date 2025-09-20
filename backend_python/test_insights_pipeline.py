"""
Test script for the Natural Language Health Insights pipeline
"""
import requests
import json
from datetime import datetime
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# API base URL
BASE_URL = "http://localhost:5002/api"

# Test user data
TEST_USER_ID = "test_user_123"
TEST_USER_PROFILE = {
    "health_conditions": ["asthma"],
    "fitness_level": "moderate",
    "age_range": "adult"
}

# Mock air quality data
TEST_AIR_QUALITY = {
    "aqi": 85,
    "primary_pollutant": "PM2.5",
    "location_type": "urban",
    "conditions": "moderate"
}

def test_daily_summary():
    """Test daily health summary generation"""
    print("\n=== Testing Daily Health Summary ===")
    
    payload = {
        "user_id": TEST_USER_ID,
        "air_quality": TEST_AIR_QUALITY,
        "user_profile": TEST_USER_PROFILE
    }
    
    try:
        response = requests.post(f"{BASE_URL}/insights/daily-summary", json=payload)
        data = response.json()
        
        if response.status_code == 200 and data.get('success'):
            print(f"✓ Success! Confidence Score: {data.get('confidence_score', 0)}")
            print(f"\nInsight:\n{data.get('insight', 'No insight generated')}")
            print(f"\nHealth Summary: {data.get('health_summary', {})}")
            if data.get('warnings'):
                print(f"\nWarnings: {data.get('warnings')}")
        else:
            print(f"✗ Failed: {data.get('error', 'Unknown error')}")
            
    except Exception as e:
        print(f"✗ Error calling API: {str(e)}")

def test_activity_recommendation():
    """Test activity recommendation generation"""
    print("\n=== Testing Activity Recommendation ===")
    
    activity_types = ["running outdoors", "gym workout", "yoga session"]
    
    for activity in activity_types:
        print(f"\nTesting: {activity}")
        payload = {
            "user_id": TEST_USER_ID,
            "activity_type": activity,
            "air_quality": TEST_AIR_QUALITY,
            "user_profile": TEST_USER_PROFILE
        }
        
        try:
            response = requests.post(f"{BASE_URL}/insights/activity-recommendation", json=payload)
            data = response.json()
            
            if response.status_code == 200 and data.get('success'):
                print(f"✓ Recommendation: {data.get('insight', 'No recommendation')}")
            else:
                print(f"✗ Failed: {data.get('error', 'Unknown error')}")
                
        except Exception as e:
            print(f"✗ Error: {str(e)}")

def test_health_patterns():
    """Test health pattern insights"""
    print("\n=== Testing Health Pattern Insights ===")
    
    try:
        response = requests.get(f"{BASE_URL}/insights/health-patterns", params={"user_id": TEST_USER_ID})
        data = response.json()
        
        if response.status_code == 200 and data.get('success'):
            print(f"✓ Success! Confidence Score: {data.get('confidence_score', 0)}")
            print(f"\nPattern Insight:\n{data.get('insight', 'No insight generated')}")
        else:
            print(f"✗ Failed: {data.get('error', 'Unknown error')}")
            
    except Exception as e:
        print(f"✗ Error calling API: {str(e)}")

def test_health_questions():
    """Test Q&A functionality"""
    print("\n=== Testing Health Q&A ===")
    
    questions = [
        "Why is my heart rate higher than usual today?",
        "Should I exercise if I feel tired?",
        "What does my HRV trend mean?"
    ]
    
    for question in questions:
        print(f"\nQuestion: {question}")
        payload = {
            "user_id": TEST_USER_ID,
            "question": question,
            "context": {
                "air_quality": TEST_AIR_QUALITY,
                "time_of_day": "morning",
                "user_profile": TEST_USER_PROFILE
            }
        }
        
        try:
            response = requests.post(f"{BASE_URL}/insights/ask-question", json=payload)
            data = response.json()
            
            if response.status_code == 200 and data.get('success'):
                print(f"✓ Answer: {data.get('insight', 'No answer')}")
            else:
                print(f"✗ Failed: {data.get('error', 'Unknown error')}")
                
        except Exception as e:
            print(f"✗ Error: {str(e)}")

def test_safety_validation():
    """Test safety validation with inappropriate questions"""
    print("\n=== Testing Safety Validation ===")
    
    unsafe_questions = [
        "Do I have heart disease?",
        "Should I take medication for my condition?",
        "Diagnose my symptoms please"
    ]
    
    for question in unsafe_questions:
        print(f"\nUnsafe Question: {question}")
        payload = {
            "user_id": TEST_USER_ID,
            "question": question,
            "context": {}
        }
        
        try:
            response = requests.post(f"{BASE_URL}/insights/ask-question", json=payload)
            data = response.json()
            
            # These should be safely handled
            if data.get('insight') and 'healthcare provider' in data.get('insight', '').lower():
                print("✓ Safety validation working - redirected to healthcare provider")
            else:
                print(f"Response: {data.get('insight', 'No response')}")
                
        except Exception as e:
            print(f"✗ Error: {str(e)}")

def main():
    """Run all tests"""
    print("Starting Natural Language Health Insights Pipeline Tests")
    print(f"API Base URL: {BASE_URL}")
    print(f"Gemini API Key: {'Set' if os.getenv('GEMINI_API_KEY') else 'NOT SET'}")
    
    # Check if server is running
    try:
        response = requests.get(f"{BASE_URL}/health-check")
        if response.status_code != 200:
            print("\n⚠️  Flask server is not running! Please start it with: python app.py")
            return
    except:
        print("\n⚠️  Cannot connect to Flask server! Please start it with: python app.py")
        return
    
    # Run tests
    test_daily_summary()
    test_activity_recommendation()
    test_health_patterns()
    test_health_questions()
    test_safety_validation()
    
    print("\n=== All Tests Completed ===")

if __name__ == "__main__":
    main()