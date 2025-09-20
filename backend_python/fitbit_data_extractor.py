import wearipedia
import json
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Optional

class FitbitDataExtractor:
    def __init__(self, use_synthetic: bool = True):
        """
        Initialize Fitbit Charge 6 data extractor
        Args:
            use_synthetic: True for development, False for production with real tokens
        """
        try:
            self.device = wearipedia.get_device("fitbit/fitbit_charge_6")
        except:
            self.device = None
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
        print(f"Generating synthetic data from {start_date} to {end_date}...")

        # Set seed for reproducible data
        np.random.seed(seed)

        # Parse dates
        start_dt = datetime.strptime(start_date, "%Y-%m-%d")
        end_dt = datetime.strptime(end_date, "%Y-%m-%d")

        # Generate synthetic data
        data = {}

        print("Generating heart rate data...")
        data['heart_rate'] = self._generate_heart_rate_data(start_dt, end_dt)

        print("Generating activity data...")
        data['activity'] = self._generate_activity_data(start_dt, end_dt)

        print("Generating SpO2 data...")
        data['spo2'] = self._generate_spo2_data(start_dt, end_dt)

        print("Generating HRV data...")
        data['hrv'] = self._generate_hrv_data(start_dt, end_dt)

        print("Generating breathing rate data...")
        data['breath_rate'] = self._generate_breathing_rate_data(start_dt, end_dt)

        print("Data generation completed!")
        return data

    def _generate_heart_rate_data(self, start_dt: datetime, end_dt: datetime) -> List[Dict]:
        """Generate realistic heart rate data"""
        data = []
        current_date = start_dt

        while current_date <= end_dt:
            # Generate intraday heart rate data (every 5 minutes, 12 hours a day)
            date_str = current_date.strftime("%Y-%m-%d")
            dataset = []

            # Generate data from 6 AM to 11 PM (17 hours)
            for hour in range(6, 23):
                for minute in range(0, 60, 5):  # Every 5 minutes
                    time_str = f"{hour:02d}:{minute:02d}:00"

                    # Realistic heart rate based on time of day
                    base_hr = 70
                    if 6 <= hour <= 10:  # Morning
                        base_hr = 75 + np.random.normal(0, 5)
                    elif 10 <= hour <= 17:  # Day
                        base_hr = 80 + np.random.normal(0, 10)
                    elif 17 <= hour <= 22:  # Evening
                        base_hr = 72 + np.random.normal(0, 8)

                    hr_value = max(50, min(120, int(base_hr)))
                    dataset.append({"time": time_str, "value": hr_value})

            data.append({
                "heart_rate_day": [{
                    "activities-heart": [{"dateTime": date_str}],
                    "activities-heart-intraday": {"dataset": dataset}
                }]
            })

            current_date += timedelta(days=1)

        return data

    def _generate_activity_data(self, start_dt: datetime, end_dt: datetime) -> List[Dict]:
        """Generate realistic activity data"""
        data = []
        current_date = start_dt

        while current_date <= end_dt:
            date_str = current_date.strftime("%Y-%m-%d")

            # Random but realistic daily steps (5000-15000)
            steps = np.random.randint(5000, 15000)

            data.append({
                "dateTime": date_str,
                "value": steps
            })

            current_date += timedelta(days=1)

        return data

    def _generate_spo2_data(self, start_dt: datetime, end_dt: datetime) -> List[Dict]:
        """Generate realistic SpO2 data"""
        data = []
        current_date = start_dt

        while current_date <= end_dt:
            minutes = []

            # Generate SpO2 data every 15 minutes during sleep (11 PM - 7 AM)
            for hour in [23, 0, 1, 2, 3, 4, 5, 6]:
                for minute in range(0, 60, 15):
                    if hour == 23:
                        time_str = f"{current_date.strftime('%Y-%m-%d')}T{hour:02d}:{minute:02d}:00"
                    else:
                        next_day = current_date + timedelta(days=1)
                        time_str = f"{next_day.strftime('%Y-%m-%d')}T{hour:02d}:{minute:02d}:00"

                    # Normal SpO2 range: 95-100%
                    spo2_value = np.random.randint(95, 100)
                    minutes.append({"minute": time_str, "value": spo2_value})

            data.append({"minutes": minutes})
            current_date += timedelta(days=1)

        return data

    def _generate_hrv_data(self, start_dt: datetime, end_dt: datetime) -> List[Dict]:
        """Generate realistic HRV data"""
        data = []
        current_date = start_dt

        while current_date <= end_dt:
            hrv_data = []
            minutes = []

            # Generate HRV data during sleep
            for hour in [23, 0, 1, 2, 3, 4, 5, 6]:
                for minute in range(0, 60, 30):  # Every 30 minutes
                    if hour == 23:
                        time_str = f"{current_date.strftime('%Y-%m-%d')}T{hour:02d}:{minute:02d}:00"
                    else:
                        next_day = current_date + timedelta(days=1)
                        time_str = f"{next_day.strftime('%Y-%m-%d')}T{hour:02d}:{minute:02d}:00"

                    # Realistic HRV values
                    rmssd = max(10, min(100, np.random.normal(35, 10)))
                    lf = max(100, min(2000, np.random.normal(800, 200)))
                    hf = max(100, min(1500, np.random.normal(600, 150)))

                    minutes.append({
                        "minute": time_str,
                        "value": {
                            "rmssd": round(rmssd, 2),
                            "lf": round(lf, 2),
                            "hf": round(hf, 2)
                        }
                    })

            hrv_data.append({"minutes": minutes})
            data.append({"hrv": hrv_data})
            current_date += timedelta(days=1)

        return data

    def _generate_breathing_rate_data(self, start_dt: datetime, end_dt: datetime) -> List[Dict]:
        """Generate realistic breathing rate data"""
        data = []
        current_date = start_dt

        while current_date <= end_dt:
            date_str = current_date.strftime("%Y-%m-%d")

            # Realistic breathing rates during different sleep stages
            deep_br = round(np.random.normal(14, 2), 1)
            rem_br = round(np.random.normal(16, 2), 1)
            light_br = round(np.random.normal(15, 2), 1)
            full_br = round(np.random.normal(15, 1.5), 1)

            br_data = [{
                "dateTime": date_str,
                "value": {
                    "deepSleepSummary": {"breathingRate": deep_br},
                    "remSleepSummary": {"breathingRate": rem_br},
                    "lightSleepSummary": {"breathingRate": light_br},
                    "fullSleepSummary": {"breathingRate": full_br}
                }
            }]

            data.append({"br": br_data})
            current_date += timedelta(days=1)

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