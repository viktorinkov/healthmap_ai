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

        if not self.raw_data.get('heart_rate') or self.raw_data['heart_rate'] is None:
            print("No heart rate data available")
            return pd.DataFrame(columns=['datetime', 'heart_rate'])

        for record in self.raw_data['heart_rate']:
            if not record or record is None:
                continue

            try:
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
            except (KeyError, TypeError, IndexError) as e:
                print(f"Error processing heart rate record: {e}")
                continue

        df = pd.DataFrame(results)
        if not df.empty:
            df['datetime'] = pd.to_datetime(df['datetime'])
        return df
    
    def process_activity_data(self) -> pd.DataFrame:
        """Convert activity JSON to structured DataFrame"""
        results = []

        if not self.raw_data.get('activity') or self.raw_data['activity'] is None:
            print("No activity data available")
            return pd.DataFrame(columns=['datetime', 'steps', 'distance', 'calories'])

        for record in self.raw_data['activity']:
            if not record or record is None:
                continue

            try:
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
            except (KeyError, TypeError, ValueError) as e:
                print(f"Error processing activity record: {e}")
                continue

        df = pd.DataFrame(results)
        if not df.empty:
            df['datetime'] = pd.to_datetime(df['datetime'])
        return df
    
    def process_spo2_data(self) -> pd.DataFrame:
        """Convert SpO2 JSON to structured DataFrame"""
        results = []

        if not self.raw_data.get('spo2') or self.raw_data['spo2'] is None:
            print("No SpO2 data available")
            return pd.DataFrame(columns=['datetime', 'spo2'])

        for entry in self.raw_data['spo2']:
            if not entry or entry is None:
                continue

            try:
                for minute_entry in entry['minutes']:
                    results.append({
                        'datetime': pd.to_datetime(minute_entry['minute']),
                        'spo2': minute_entry['value']
                    })
            except (KeyError, TypeError) as e:
                print(f"Error processing SpO2 record: {e}")
                continue

        return pd.DataFrame(results)
    
    def process_hrv_data(self) -> pd.DataFrame:
        """Convert HRV JSON to structured DataFrame"""
        results = []

        if not self.raw_data.get('hrv') or self.raw_data['hrv'] is None:
            print("No HRV data available")
            return pd.DataFrame(columns=['datetime', 'rmssd', 'lf', 'hf'])

        for entry in self.raw_data['hrv']:
            if not entry or entry is None:
                continue

            try:
                for hrv_entry in entry['hrv']:
                    for minute_entry in hrv_entry['minutes']:
                        results.append({
                            'datetime': pd.to_datetime(minute_entry['minute']),
                            'rmssd': minute_entry['value']['rmssd'],
                            'lf': minute_entry['value']['lf'],
                            'hf': minute_entry['value']['hf']
                        })
            except (KeyError, TypeError) as e:
                print(f"Error processing HRV record: {e}")
                continue

        return pd.DataFrame(results)
    
    def process_breathing_rate_data(self) -> pd.DataFrame:
        """Convert breathing rate JSON to structured DataFrame"""
        results = []

        if not self.raw_data.get('breath_rate') or self.raw_data['breath_rate'] is None:
            print("No breathing rate data available")
            return pd.DataFrame(columns=['date', 'deep_sleep_br', 'rem_sleep_br', 'light_sleep_br', 'full_sleep_br'])

        for entry in self.raw_data['breath_rate']:
            if not entry or entry is None:
                continue

            try:
                for br_entry in entry['br']:
                    results.append({
                        'date': pd.to_datetime(br_entry['dateTime']).date(),
                        'deep_sleep_br': br_entry['value']['deepSleepSummary']['breathingRate'],
                        'rem_sleep_br': br_entry['value']['remSleepSummary']['breathingRate'],
                        'light_sleep_br': br_entry['value']['lightSleepSummary']['breathingRate'],
                        'full_sleep_br': br_entry['value']['fullSleepSummary']['breathingRate']
                    })
            except (KeyError, TypeError) as e:
                print(f"Error processing breathing rate record: {e}")
                continue

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