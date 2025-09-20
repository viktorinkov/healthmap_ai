#!/usr/bin/env python3
"""
Load CSV health data into PostgreSQL database
"""
import pandas as pd
import psycopg2
from psycopg2.extras import execute_values
import os
from datetime import datetime

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'database': 'health_monitoring',
    'user': 'postgres',
    'password': '',  # No password set for local development
    'port': 5432
}

def create_tables(conn):
    """Create database tables if they don't exist"""
    with conn.cursor() as cursor:
        # Create users table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                fitbit_user_id VARCHAR(50) UNIQUE NOT NULL,
                email VARCHAR(100),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        """)
        
        # Create heart_rate_data table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS heart_rate_data (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id),
                datetime TIMESTAMP NOT NULL,
                heart_rate INTEGER NOT NULL,
                UNIQUE(user_id, datetime)
            );
        """)
        
        # Create activity_data table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS activity_data (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id),
                datetime TIMESTAMP NOT NULL,
                steps INTEGER,
                distance FLOAT,
                calories INTEGER,
                UNIQUE(user_id, datetime)
            );
        """)
        
        # Create spo2_data table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS spo2_data (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id),
                datetime TIMESTAMP NOT NULL,
                spo2 FLOAT NOT NULL,
                UNIQUE(user_id, datetime)
            );
        """)
        
        # Create hrv_data table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS hrv_data (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id),
                datetime TIMESTAMP NOT NULL,
                rmssd FLOAT,
                lf FLOAT,
                hf FLOAT,
                UNIQUE(user_id, datetime)
            );
        """)
        
        # Create breathing_rate_data table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS breathing_rate_data (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id),
                date DATE NOT NULL,
                deep_sleep_br FLOAT,
                rem_sleep_br FLOAT,
                light_sleep_br FLOAT,
                full_sleep_br FLOAT,
                UNIQUE(user_id, date)
            );
        """)
        
        conn.commit()
        print("✓ Database tables created successfully")

def create_user(conn, fitbit_user_id='user_001', email='test@example.com'):
    """Create a user and return user_id"""
    with conn.cursor() as cursor:
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
        
        conn.commit()
        print(f"✓ User created/updated with ID: {user_id}")
        return user_id

def load_csv_data(conn, user_id):
    """Load all CSV files into database"""
    csv_files = {
        'heart_rate': 'processed_heart_rate_data.csv',
        'activity': 'processed_activity_data.csv',
        'spo2': 'processed_spo2_data.csv',
        'hrv': 'processed_hrv_data.csv',
        'breathing_rate': 'processed_breathing_rate_data.csv'
    }
    
    for data_type, filename in csv_files.items():
        if os.path.exists(filename):
            print(f"Loading {data_type} data from {filename}...")
            df = pd.read_csv(filename)
            
            # Add user_id to dataframe
            df['user_id'] = user_id
            
            # Load data based on type
            if data_type == 'heart_rate':
                load_heart_rate_data(conn, df)
            elif data_type == 'activity':
                load_activity_data(conn, df)
            elif data_type == 'spo2':
                load_spo2_data(conn, df)
            elif data_type == 'hrv':
                load_hrv_data(conn, df)
            elif data_type == 'breathing_rate':
                load_breathing_rate_data(conn, df)
                
        else:
            print(f"⚠️  {filename} not found, skipping {data_type} data")

def load_heart_rate_data(conn, df):
    """Load heart rate data"""
    # Limit to recent data to avoid memory issues
    df_sample = df.head(10000).copy()  # Load first 10k records
    
    # Update dates to be recent (within last 30 days)
    from datetime import datetime, timedelta
    import pandas as pd
    base_date = datetime.now() - timedelta(days=29)
    df_sample['datetime'] = pd.to_datetime(df_sample['datetime'])
    
    # Calculate time offset from original data to recent dates
    time_offset = base_date - df_sample['datetime'].min()
    df_sample['datetime'] = df_sample['datetime'] + time_offset
    
    # Convert to string format for database insertion
    df_sample['datetime'] = df_sample['datetime'].dt.strftime('%Y-%m-%d %H:%M:%S')
    
    records = df_sample[['user_id', 'datetime', 'heart_rate']].to_records(index=False)
    
    with conn.cursor() as cursor:
        execute_values(
            cursor,
            """INSERT INTO heart_rate_data (user_id, datetime, heart_rate) 
               VALUES %s ON CONFLICT (user_id, datetime) DO NOTHING""",
            records.tolist(),
            page_size=1000
        )
        conn.commit()
    print(f"✓ Loaded {len(df_sample)} heart rate records")

def load_activity_data(conn, df):
    """Load activity data"""
    # Update dates to be recent (within last 30 days)
    from datetime import datetime, timedelta
    import pandas as pd
    df = df.copy()
    base_date = datetime.now() - timedelta(days=29)
    df['datetime'] = pd.to_datetime(df['datetime'])
    
    # Calculate time offset from original data to recent dates
    time_offset = base_date - df['datetime'].min()
    df['datetime'] = df['datetime'] + time_offset
    
    # Convert to string format for database insertion
    df['datetime'] = df['datetime'].dt.strftime('%Y-%m-%d %H:%M:%S')
    
    records = df[['user_id', 'datetime', 'steps', 'distance', 'calories']].to_records(index=False)
    
    with conn.cursor() as cursor:
        execute_values(
            cursor,
            """INSERT INTO activity_data (user_id, datetime, steps, distance, calories) 
               VALUES %s ON CONFLICT (user_id, datetime) DO NOTHING""",
            records.tolist()
        )
        conn.commit()
    print(f"✓ Loaded {len(df)} activity records")

def load_spo2_data(conn, df):
    """Load SpO2 data"""
    # Limit to recent data
    df_sample = df.head(5000)  # Load first 5k records
    records = df_sample[['user_id', 'datetime', 'spo2']].to_records(index=False)
    
    with conn.cursor() as cursor:
        execute_values(
            cursor,
            """INSERT INTO spo2_data (user_id, datetime, spo2) 
               VALUES %s ON CONFLICT (user_id, datetime) DO NOTHING""",
            records.tolist(),
            page_size=1000
        )
        conn.commit()
    print(f"✓ Loaded {len(df_sample)} SpO2 records")

def load_hrv_data(conn, df):
    """Load HRV data"""
    # Limit to recent data
    df_sample = df.head(5000)  # Load first 5k records
    records = df_sample[['user_id', 'datetime', 'rmssd', 'lf', 'hf']].to_records(index=False)
    
    with conn.cursor() as cursor:
        execute_values(
            cursor,
            """INSERT INTO hrv_data (user_id, datetime, rmssd, lf, hf) 
               VALUES %s ON CONFLICT (user_id, datetime) DO NOTHING""",
            records.tolist(),
            page_size=1000
        )
        conn.commit()
    print(f"✓ Loaded {len(df_sample)} HRV records")

def load_breathing_rate_data(conn, df):
    """Load breathing rate data"""
    records = df[['user_id', 'date', 'deep_sleep_br', 'rem_sleep_br', 
                 'light_sleep_br', 'full_sleep_br']].to_records(index=False)
    
    with conn.cursor() as cursor:
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
        conn.commit()
    print(f"✓ Loaded {len(df)} breathing rate records")

def main():
    """Main function to load data"""
    try:
        # Connect to database
        print("Connecting to PostgreSQL database...")
        conn = psycopg2.connect(**DB_CONFIG)
        print("✓ Database connection successful")
        
        # Create tables
        create_tables(conn)
        
        # Create user
        user_id = create_user(conn)
        
        # Load CSV data
        load_csv_data(conn, user_id)
        
        # Verify data
        with conn.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM heart_rate_data")
            hr_count = cursor.fetchone()[0]
            cursor.execute("SELECT COUNT(*) FROM activity_data")
            activity_count = cursor.fetchone()[0]
            print(f"\n✓ Data verification:")
            print(f"  - Heart rate records: {hr_count}")
            print(f"  - Activity records: {activity_count}")
        
        conn.close()
        print("\n🎉 Database setup completed successfully!")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False
    
    return True

if __name__ == "__main__":
    main()