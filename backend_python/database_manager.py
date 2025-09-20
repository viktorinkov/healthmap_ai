import psycopg2
from psycopg2.extras import execute_values, RealDictCursor
import pandas as pd
from typing import Dict, Optional
import os
from datetime import datetime

class DatabaseManager:
    def __init__(self, db_config: Dict[str, str]):
        self.db_config = db_config
        self.connection = None
    
    def connect(self):
        """Establish database connection"""
        self.connection = psycopg2.connect(**self.db_config)
    
    def disconnect(self):
        """Close database connection"""
        if self.connection:
            self.connection.close()
    
    def create_user(self, fitbit_user_id: str, email: Optional[str] = None) -> str:
        """Create or get user and return user_id"""
        with self.connection.cursor() as cursor:
            cursor.execute("""
                INSERT INTO users (fitbit_user_id, email) 
                VALUES (%s, %s) 
                ON CONFLICT (fitbit_user_id) DO UPDATE SET email = EXCLUDED.email
                RETURNING id
            """, (fitbit_user_id, email))
            
            result = cursor.fetchone()
            if result:
                user_id = result[0]
            else:
                cursor.execute(
                    "SELECT id FROM users WHERE fitbit_user_id = %s", 
                    (fitbit_user_id,)
                )
                user_id = cursor.fetchone()[0]
            
            self.connection.commit()
            return str(user_id)
    
    def insert_heart_rate_data(self, df: pd.DataFrame, user_id: str):
        """Bulk insert heart rate data"""
        df['user_id'] = user_id
        records = df[['user_id', 'datetime', 'heart_rate']].to_records(index=False)
        
        with self.connection.cursor() as cursor:
            execute_values(
                cursor,
                """INSERT INTO heart_rate_data (user_id, datetime, heart_rate) 
                   VALUES %s ON CONFLICT DO NOTHING""",
                records.tolist()
            )
            self.connection.commit()
    
    def insert_activity_data(self, df: pd.DataFrame, user_id: str):
        """Bulk insert activity data"""
        df['user_id'] = user_id
        records = df[['user_id', 'datetime', 'steps', 'distance', 'calories']].to_records(index=False)
        
        with self.connection.cursor() as cursor:
            execute_values(
                cursor,
                """INSERT INTO activity_data (user_id, datetime, steps, distance, calories) 
                   VALUES %s ON CONFLICT DO NOTHING""",
                records.tolist()
            )
            self.connection.commit()
    
    def insert_spo2_data(self, df: pd.DataFrame, user_id: str):
        """Bulk insert SpO2 data"""
        df['user_id'] = user_id
        records = df[['user_id', 'datetime', 'spo2']].to_records(index=False)
        
        with self.connection.cursor() as cursor:
            execute_values(
                cursor,
                """INSERT INTO spo2_data (user_id, datetime, spo2) 
                   VALUES %s ON CONFLICT DO NOTHING""",
                records.tolist()
            )
            self.connection.commit()
    
    def insert_hrv_data(self, df: pd.DataFrame, user_id: str):
        """Bulk insert HRV data"""
        df['user_id'] = user_id
        records = df[['user_id', 'datetime', 'rmssd', 'lf', 'hf']].to_records(index=False)
        
        with self.connection.cursor() as cursor:
            execute_values(
                cursor,
                """INSERT INTO hrv_data (user_id, datetime, rmssd, lf, hf) 
                   VALUES %s ON CONFLICT DO NOTHING""",
                records.tolist()
            )
            self.connection.commit()
    
    def insert_breathing_rate_data(self, df: pd.DataFrame, user_id: str):
        """Bulk insert breathing rate data"""
        df['user_id'] = user_id
        records = df[['user_id', 'date', 'deep_sleep_br', 'rem_sleep_br', 
                     'light_sleep_br', 'full_sleep_br']].to_records(index=False)
        
        with self.connection.cursor() as cursor:
            execute_values(
                cursor,
                """INSERT INTO breathing_rate_data 
                   (user_id, date, deep_sleep_br, rem_sleep_br, light_sleep_br, full_sleep_br) 
                   VALUES %s ON CONFLICT (user_id, date) DO UPDATE SET
                   deep_sleep_br = EXCLUDED.deep_sleep_br,
                   rem_sleep_br = EXCLUDED.rem_sleep_br,
                   light_sleep_br = EXCLUDED.light_sleep_br,
                   full_sleep_br = EXCLUDED.full_sleep_br""",
                records.tolist()
            )
            self.connection.commit()
    
    def store_all_data(self, processed_data: Dict[str, pd.DataFrame], user_id: str):
        """Store all processed data types"""
        print(f"Storing data for user {user_id}...")
        
        if 'heart_rate' in processed_data:
            self.insert_heart_rate_data(processed_data['heart_rate'], user_id)
            print(f"Stored {len(processed_data['heart_rate'])} heart rate records")
        
        if 'activity' in processed_data:
            self.insert_activity_data(processed_data['activity'], user_id)
            print(f"Stored {len(processed_data['activity'])} activity records")
        
        if 'spo2' in processed_data:
            self.insert_spo2_data(processed_data['spo2'], user_id)
            print(f"Stored {len(processed_data['spo2'])} SpO2 records")
        
        if 'hrv' in processed_data:
            self.insert_hrv_data(processed_data['hrv'], user_id)
            print(f"Stored {len(processed_data['hrv'])} HRV records")
        
        if 'breathing_rate' in processed_data:
            self.insert_breathing_rate_data(processed_data['breathing_rate'], user_id)
            print(f"Stored {len(processed_data['breathing_rate'])} breathing rate records")

# Configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'health_monitoring'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'password'),
    'port': int(os.getenv('DB_PORT', 5432))
}