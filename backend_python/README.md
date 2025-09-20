# Healthcare Air Quality & Running Optimization - Backend

This backend implementation extracts Fitbit Charge 6 synthetic health data using Wearipedia and provides a REST API for the Flutter mobile application.

## 🚀 Quick Start

### Prerequisites
- Python 3.12+
- PostgreSQL (optional - system works without database)

### Installation

1. **Set up virtual environment:**
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

2. **Install dependencies:**
```bash
cd wearipedia
pip install -e .
cd ..
pip install flask pandas psycopg2-binary python-dotenv flask-cors
```

### Running the System

#### Extract and Process Data
```bash
# Set Python path and run the complete pipeline
PYTHONPATH="./wearipedia:./backend:$PYTHONPATH" ./venv/bin/python backend/main_pipeline.py
```

#### Start API Server
```bash
PYTHONPATH="./wearipedia:./backend:$PYTHONPATH" ./venv/bin/python backend/app.py
```

The API will be available at `http://localhost:5000`

## 📊 Data Extracted

The system extracts the following health metrics from Fitbit Charge 6:

### Tier 1 - Essential Metrics
- **Heart Rate**: Per-second heart rate data
- **Activity**: Daily step counts
- **SpO2**: Blood oxygen saturation during sleep

### Tier 2 - Enhanced Metrics  
- **HRV**: Heart rate variability data
- **Breathing Rate**: Sleep breathing patterns
- **Active Zone Minutes**: Activity intensity tracking

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Wearipedia    │───▶│  Data Processor │───▶│   PostgreSQL    │
│  (Synthetic)    │    │   (Pandas DF)   │    │   (Optional)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                  │
                                  ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Flask API     │───▶│  Flutter App    │
                       │  (REST Server)  │    │    (Mobile)     │
                       └─────────────────┘    └─────────────────┘
```

## 📁 File Structure

```
backend/
├── fitbit_data_extractor.py   # Wearipedia data extraction
├── data_processor.py          # JSON to DataFrame conversion
├── database_manager.py        # PostgreSQL integration
├── app.py                     # Flask REST API
├── main_pipeline.py           # Complete pipeline orchestration
├── schema.sql                 # Database schema
└── debug_data_structure.py    # Debug utility
```

## 🔧 Configuration

### Environment Variables
```bash
export DB_HOST=localhost
export DB_NAME=health_monitoring
export DB_USER=postgres
export DB_PASSWORD=your_password
export DB_PORT=5432
```

### Database Setup (Optional)
```bash
# Create database
createdb health_monitoring

# Run schema
psql health_monitoring < backend/schema.sql
```

## 📡 API Endpoints

### Health Check
```
GET /api/health-check
```

### Heart Rate Data
```
GET /api/users/{user_id}/heart-rate?start_date=2024-12-01&end_date=2024-12-07&limit=1000
```

### Activity Data
```
GET /api/users/{user_id}/activity?days=7
```

### Health Summary
```
GET /api/users/{user_id}/health-summary?days=7
```

## 📈 Sample Data Output

### Successful Pipeline Run
```json
{
  "success": true,
  "user_id": "test",
  "records_processed": {
    "heart_rate": 2592000,
    "activity": 30,
    "spo2": 13248,
    "hrv": 13248,
    "breathing_rate": 30
  }
}
```

### CSV Files Generated (without database)
- `processed_heart_rate_data.csv` - Per-second heart rate
- `processed_activity_data.csv` - Daily activity summaries
- `processed_spo2_data.csv` - Sleep oxygen saturation
- `processed_hrv_data.csv` - Heart rate variability
- `processed_breathing_rate_data.csv` - Sleep breathing rates

## 🧪 Testing

### Debug Data Structure
```bash
PYTHONPATH="./wearipedia:./backend:$PYTHONPATH" ./venv/bin/python backend/debug_data_structure.py
```

### Test API Endpoints
```bash
# Health check
curl http://localhost:5000/api/health-check

# Heart rate data (replace 'test' with actual user ID)
curl "http://localhost:5000/api/users/test/heart-rate?limit=10"
```

## 🔮 Next Steps

1. **Database Integration**: Set up PostgreSQL for persistent storage
2. **Air Quality APIs**: Integrate with EPA AirNow, WAQI APIs
3. **Recommendation Engine**: Combine health data with air quality
4. **Flutter Integration**: Connect mobile app to these endpoints
5. **Real Fitbit Data**: Implement OAuth for production use

## 🐛 Troubleshooting

### Common Issues

**Wearipedia Import Error**:
```bash
# Ensure correct Python path
PYTHONPATH="./wearipedia:$PYTHONPATH" python your_script.py
```

**Database Connection Failed**:
- System gracefully falls back to CSV file output
- Check PostgreSQL is running: `pg_ctl status`

**Module Not Found**:
```bash
# Reinstall wearipedia
cd wearipedia && pip install -e .
```

## 📚 Key Features

✅ **Synthetic Data Generation**: 7 days of realistic health data  
✅ **Multiple Health Metrics**: Heart rate, activity, SpO2, HRV, breathing  
✅ **Database Ready**: PostgreSQL schema and integration  
✅ **RESTful API**: Flask endpoints for mobile app  
✅ **Error Handling**: Graceful fallbacks and informative messages  
✅ **CSV Export**: Works without database setup  

This backend provides a solid foundation for the healthcare air quality application, focusing on reliable data extraction and processing from Fitbit devices.