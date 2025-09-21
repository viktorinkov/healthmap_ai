#!/usr/bin/env python3
"""Test script to diagnose import issues"""

import sys
import os

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

print("Python executable:", sys.executable)
print("Python version:", sys.version)
print("\nPython path:")
for p in sys.path:
    print(f"  - {p}")

print("\n--- Testing imports ---")

try:
    import googlemaps
    print("✓ googlemaps imported successfully")
except ImportError as e:
    print(f"✗ Failed to import googlemaps: {e}")

try:
    import geopandas
    print("✓ geopandas imported successfully")
except ImportError as e:
    print(f"✗ Failed to import geopandas: {e}")

try:
    import shapely
    print("✓ shapely imported successfully")
except ImportError as e:
    print(f"✗ Failed to import shapely: {e}")

try:
    from run_coach.models import UserProfile
    print("✓ run_coach.models imported successfully")
except ImportError as e:
    print(f"✗ Failed to import run_coach.models: {e}")

try:
    from run_coach.services.air_quality_service import AirQualityService
    print("✓ run_coach.services.air_quality_service imported successfully")
except ImportError as e:
    print(f"✗ Failed to import run_coach.services.air_quality_service: {e}")

try:
    from run_coach.services.route_generator import RouteGenerator
    print("✓ run_coach.services.route_generator imported successfully")
except ImportError as e:
    print(f"✗ Failed to import run_coach.services.route_generator: {e}")

try:
    from run_coach.api import run_coach_bp
    print("✓ run_coach.api imported successfully")
except ImportError as e:
    print(f"✗ Failed to import run_coach.api: {e}")

print("\n--- Checking googlemaps installation ---")
import subprocess
result = subprocess.run([sys.executable, "-m", "pip", "show", "googlemaps"], capture_output=True, text=True)
print(result.stdout)