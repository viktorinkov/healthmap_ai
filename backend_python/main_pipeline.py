from fitbit_data_extractor import FitbitDataExtractor
from data_processor import FitbitDataProcessor
from database_manager import DatabaseManager, DB_CONFIG
import json
from datetime import datetime, timedelta
import sys
import os

# Add the current directory to the Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

def run_complete_pipeline(user_email: str, days_back: int = 7):
    """
    Complete pipeline: Extract → Process → Store
    Args:
        user_email: User's email for identification
        days_back: Number of days of data to extract
    """
    
    # Calculate date range
    end_date = datetime.now()
    start_date = end_date - timedelta(days=days_back)
    
    start_date_str = start_date.strftime('%Y-%m-%d')
    end_date_str = end_date.strftime('%Y-%m-%d')
    
    print(f"Running pipeline for {user_email}")
    print(f"Date range: {start_date_str} to {end_date_str}")
    
    try:
        # Step 1: Extract data using Wearipedia
        print("\n=== Step 1: Data Extraction ===")
        extractor = FitbitDataExtractor(use_synthetic=True)
        raw_data = extractor.extract_health_data(start_date_str, end_date_str)
        
        # Step 2: Process raw data into structured format
        print("\n=== Step 2: Data Processing ===")
        processor = FitbitDataProcessor(raw_data)
        processed_data = processor.process_all_data()
        
        # Step 3: Store in database (if database is available)
        print("\n=== Step 3: Data Storage ===")
        try:
            db_manager = DatabaseManager(DB_CONFIG)
            db_manager.connect()
            
            # Create or get user
            fitbit_user_id = user_email.split('@')[0]  # Simple ID from email
            user_id = db_manager.create_user(fitbit_user_id, user_email)
            
            # Store all processed data
            db_manager.store_all_data(processed_data, user_id)
            
            db_manager.disconnect()
            
            print("\n=== Pipeline Results ===")
            print("✓ Pipeline completed successfully!")
            return {
                'success': True,
                'user_id': user_id,
                'records_processed': {
                    data_type: len(df) for data_type, df in processed_data.items()
                }
            }
            
        except Exception as db_error:
            print(f"⚠️  Database connection failed: {db_error}")
            print("Continuing without database storage...")
            
            # Save processed data to files for inspection
            print("\n=== Saving to Files ===")
            for data_type, df in processed_data.items():
                filename = f"processed_{data_type}_data.csv"
                df.to_csv(filename, index=False)
                print(f"Saved {len(df)} {data_type} records to {filename}")
            
            return {
                'success': True,
                'user_id': 'no_database',
                'records_processed': {
                    data_type: len(df) for data_type, df in processed_data.items()
                },
                'note': 'Data saved to CSV files (database unavailable)'
            }
        
    except Exception as e:
        print(f"❌ Pipeline failed: {e}")
        return {'success': False, 'error': str(e)}

def test_wearipedia_connection():
    """Test basic wearipedia functionality"""
    print("=== Testing Wearipedia Connection ===")
    try:
        import wearipedia
        device = wearipedia.get_device("fitbit/fitbit_charge_6")
        print("✓ Wearipedia imported successfully")
        print("✓ Fitbit Charge 6 device created")
        print("✓ Device ready for data extraction")
        return True
    except Exception as e:
        print(f"❌ Wearipedia test failed: {e}")
        return False

if __name__ == "__main__":
    # Test wearipedia first
    if not test_wearipedia_connection():
        print("Exiting due to wearipedia connection issues")
        sys.exit(1)
    
    # Run pipeline for test user
    print("\n" + "="*50)
    result = run_complete_pipeline("test@example.com", days_back=7)
    
    print("\n=== Final Results ===")
    print(json.dumps(result, indent=2, default=str))