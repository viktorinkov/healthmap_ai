#!/usr/bin/env python3
"""
Startup script for backend with proper Python path
"""

import sys
import os

# Add current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Now import and run the app
from app import app

if __name__ == "__main__":
    print("Starting HealthMap AI backend with Run Coach...")
    print(f"Python path: {sys.executable}")
    print(f"Working directory: {os.getcwd()}")
    
    # Run the Flask app
    app.run(host='0.0.0.0', port=5001, debug=True)