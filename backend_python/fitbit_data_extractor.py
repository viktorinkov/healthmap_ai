import wearipedia
import json
import pandas as pd
from datetime import datetime, timedelta
from typing import Dict, List, Optional

class FitbitDataExtractor:
    def __init__(self, use_synthetic: bool = True):
        """
        Initialize Fitbit Charge 6 data extractor
        Args:
            use_synthetic: True for development, False for production with real tokens
        """
        self.device = wearipedia.get_device("fitbit/fitbit_charge_6")
        self.use_synthetic = use_synthetic
        
    def authenticate(self, access_token: Optional[str] = None):
        """Authenticate with Fitbit API (only needed for real data)"""
        if not self.use_synthetic and access_token:
            self.device.authenticate(access_token)
    
    def extract_health_data(self, start_date: str, end_date: str, seed: int = 100) -> Dict:
        """
        Extract all priority health data for the date range
        Args:
            start_date: Format "YYYY-MM-DD"
            end_date: Format "YYYY-MM-DD"
            seed: Random seed for consistent synthetic data
        Returns:
            Dictionary containing all extracted data
        """
        params = {
            "seed": seed, 
            "start_date": start_date, 
            "end_date": end_date
        }
        
        print(f"Extracting data from {start_date} to {end_date}...")
        
        # Extract all data types
        data = {}
        
        # Tier 1 - Essential metrics
        print("Extracting heart rate data...")
        data['heart_rate'] = self.device.get_data("intraday_heart_rate", params)
        
        print("Extracting activity data...")
        data['activity'] = self.device.get_data("intraday_activity", params)
        
        print("Extracting SpO2 data...")
        data['spo2'] = self.device.get_data("intraday_spo2", params)
        
        # Tier 2 - Enhanced metrics
        print("Extracting HRV data...")
        data['hrv'] = self.device.get_data("intraday_hrv", params)
        
        print("Extracting breathing rate data...")
        data['breath_rate'] = self.device.get_data("intraday_breath_rate", params)
        
        print("Extracting active zone minutes...")
        data['active_zone_minutes'] = self.device.get_data("intraday_active_zone_minute", params)
        
        print("Data extraction completed!")
        return data
    
    def save_raw_data(self, data: Dict, filepath: str):
        """Save raw JSON data to file"""
        with open(filepath, 'w') as f:
            json.dump(data, f, indent=2, default=str)
        print(f"Raw data saved to {filepath}")

# Usage example
if __name__ == "__main__":
    extractor = FitbitDataExtractor(use_synthetic=True)
    
    # Extract 7 days of data
    data = extractor.extract_health_data("2024-12-01", "2024-12-07")
    
    # Save for later processing
    extractor.save_raw_data(data, "fitbit_raw_data.json")