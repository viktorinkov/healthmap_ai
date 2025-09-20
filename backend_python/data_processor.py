import pandas as pd
import numpy as np
from datetime import datetime
from typing import Dict, List
import json

class FitbitDataProcessor:
    def __init__(self, raw_data: Dict):
        self.raw_data = raw_data
    
    def process_heart_rate_data(self) -> pd.DataFrame:
        """Convert heart rate JSON to structured DataFrame"""
        results = []
        
        for record in self.raw_data['heart_rate']:
            # Handle the nested structure: record['heart_rate_day'][0]
            heart_rate_day = record['heart_rate_day'][0]
            date_str = heart_rate_day["activities-heart"][0]["dateTime"]
            dataset = heart_rate_day["activities-heart-intraday"]["dataset"]
            
            date_obj = datetime.strptime(date_str, "%Y-%m-%d").date()
            
            for entry in dataset:
                time_str = entry["time"]
                heart_rate_value = int(entry["value"])  # Round to integer
                
                time_obj = datetime.strptime(time_str, "%H:%M:%S").time()
                date_time = datetime.combine(date_obj, time_obj)
                
                results.append({
                    'datetime': date_time,
                    'heart_rate': heart_rate_value
                })
        
        df = pd.DataFrame(results)
        df['datetime'] = pd.to_datetime(df['datetime'])
        return df
    
    def process_activity_data(self) -> pd.DataFrame:
        """Convert activity JSON to structured DataFrame"""
        results = []
        
        for record in self.raw_data['activity']:
            # The activity data seems to be daily totals, not intraday
            date_str = record["dateTime"]
            steps_value = record["value"]
            
            date_obj = datetime.strptime(date_str, "%Y-%m-%d")
            
            results.append({
                'datetime': date_obj,
                'steps': steps_value,
                'distance': 0.0,  # Not available in this format
                'calories': 0     # Not available in this format
            })
        
        df = pd.DataFrame(results)
        df['datetime'] = pd.to_datetime(df['datetime'])
        return df
    
    def process_spo2_data(self) -> pd.DataFrame:
        """Convert SpO2 JSON to structured DataFrame"""
        results = []
        
        for entry in self.raw_data['spo2']:
            for minute_entry in entry['minutes']:
                results.append({
                    'datetime': pd.to_datetime(minute_entry['minute']),
                    'spo2': minute_entry['value']
                })
        
        return pd.DataFrame(results)
    
    def process_hrv_data(self) -> pd.DataFrame:
        """Convert HRV JSON to structured DataFrame"""
        results = []
        
        for entry in self.raw_data['hrv']:
            for hrv_entry in entry['hrv']:
                for minute_entry in hrv_entry['minutes']:
                    results.append({
                        'datetime': pd.to_datetime(minute_entry['minute']),
                        'rmssd': minute_entry['value']['rmssd'],
                        'lf': minute_entry['value']['lf'],
                        'hf': minute_entry['value']['hf']
                    })
        
        return pd.DataFrame(results)
    
    def process_breathing_rate_data(self) -> pd.DataFrame:
        """Convert breathing rate JSON to structured DataFrame"""
        results = []
        
        for entry in self.raw_data['breath_rate']:
            for br_entry in entry['br']:
                results.append({
                    'date': pd.to_datetime(br_entry['dateTime']).date(),
                    'deep_sleep_br': br_entry['value']['deepSleepSummary']['breathingRate'],
                    'rem_sleep_br': br_entry['value']['remSleepSummary']['breathingRate'],
                    'light_sleep_br': br_entry['value']['lightSleepSummary']['breathingRate'],
                    'full_sleep_br': br_entry['value']['fullSleepSummary']['breathingRate']
                })
        
        return pd.DataFrame(results)
    
    def process_all_data(self) -> Dict[str, pd.DataFrame]:
        """Process all data types and return as DataFrames"""
        processed_data = {}
        
        print("Processing heart rate data...")
        processed_data['heart_rate'] = self.process_heart_rate_data()
        
        print("Processing activity data...")
        processed_data['activity'] = self.process_activity_data()
        
        print("Processing SpO2 data...")
        processed_data['spo2'] = self.process_spo2_data()
        
        print("Processing HRV data...")
        processed_data['hrv'] = self.process_hrv_data()
        
        print("Processing breathing rate data...")
        processed_data['breathing_rate'] = self.process_breathing_rate_data()
        
        return processed_data

# Usage example
if __name__ == "__main__":
    # Load previously extracted data
    with open("fitbit_raw_data.json", 'r') as f:
        raw_data = json.load(f)
    
    processor = FitbitDataProcessor(raw_data)
    processed_data = processor.process_all_data()
    
    # Display summary
    for data_type, df in processed_data.items():
        print(f"{data_type}: {len(df)} records")
        print(df.head())
        print("---")