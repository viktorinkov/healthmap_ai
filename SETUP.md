# HealthMap AI Setup Instructions

## Prerequisites

### System Requirements
- **macOS/Linux**: Recommended for development
- **Flutter SDK**: Latest stable version
- **Node.js**: v16+ with npm
- **Python**: 3.8+ with pip
- **PostgreSQL**: v13+ (required for health data)

## Quick Setup

### 1. Install PostgreSQL
```bash
# macOS
brew install postgresql@15
brew services start postgresql@15

# Create database and user
createdb health_monitoring
createuser postgres
psql -d health_monitoring -c "ALTER USER postgres WITH SUPERUSER;"
```

### 2. Backend Setup

#### Node.js Backend (Environmental Data)
```bash
cd backend_node
npm install
npm start  # Runs on port 3000
```

#### Python Backend (Health Insights)
```bash
cd backend_python
pip install -r requirements.txt

# Load health data into PostgreSQL
python load_csv_to_db.py

# Start the backend
python app.py  # Runs on port 5001
```

### 3. Frontend Setup
```bash
# In project root
flutter pub get
flutter run
```

## Environment Configuration

### Backend Node (.env)
```env
PORT=3000
GOOGLE_MAPS_API_KEY=your_key_here
OPENWEATHER_API_KEY=your_key_here
```

### Backend Python (.env)
```env
GEMINI_API_KEY=your_gemini_key_here
DB_HOST=localhost
DB_NAME=health_monitoring
DB_USER=postgres
DB_PASSWORD=
DB_PORT=5432
```

### Flutter (.env)
```env
API_BASE_URL=http://10.0.2.2:3000/api
GOOGLE_MAPS_API_KEY=your_key_here
```

## Key Features

- ✅ **Dual Backend Architecture**: Node.js + Python
- ✅ **Real Health Data**: Fitbit simulation via Wearipedia
- ✅ **AI Health Insights**: Google Gemini 2.5 Pro
- ✅ **Environmental Data**: Air quality + weather integration
- ✅ **PostgreSQL Integration**: 2.6M+ health records
- ✅ **Flutter Frontend**: Material Design 3 UI

## Testing

### Start All Services
```bash
# Use the convenience script
./start_backends.sh

# Then run Flutter app
flutter run
```

### Verify Functionality
1. **Health Tab**: Should show real heart rate/activity data
2. **AI Insights**: Should display Gemini-generated recommendations
3. **Recommendations**: Should show unified health + environmental insights

## Troubleshooting

### Common Issues
1. **PostgreSQL Connection**: Ensure `brew services start postgresql@15`
2. **Android Emulator**: Use `10.0.2.2` instead of `localhost`
3. **Missing Data**: Run `python load_csv_to_db.py` to populate database
4. **API Keys**: Ensure all environment variables are set correctly

### Health Check Endpoints
- Node.js: `http://localhost:3000/api/health-check`
- Python: `http://localhost:5001/api/health-check`

## Development Notes

- Use `flutter hot reload` for UI changes
- PostgreSQL runs on default port 5432
- Health data is auto-generated from Fitbit simulation
- All AI insights come from actual Gemini API calls