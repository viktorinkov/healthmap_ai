# HealthMap AI - Backend Integration Guide

## Overview

This branch integrates wearable data extraction (Fitbit) with AI-powered health insights using Google Gemini 2.5 Pro. The system now features:

- **Dual-Backend Architecture**:
  - Node.js backend (Port 3000): Environmental data (air quality, weather, pollen)
  - Python backend (Port 5001): Fitbit health data processing and AI insights
- **Unified Health Insights**: Combines environmental and health data for personalized recommendations
- **New Health Tab**: Displays Fitbit metrics and AI-generated health insights in the Flutter app

## Prerequisites

1. **Python 3.8+** with pip
2. **Node.js 14+** with npm
3. **PostgreSQL** (for Python backend)
4. **Flutter SDK** (for mobile app)
5. **Google Gemini API Key** (already configured in `.env`)

## Quick Start

### 1. Install Dependencies

```bash
# Install Python dependencies
cd backend_python
pip install -r requirements.txt
pip install wearipedia

# Install Node.js dependencies  
cd ../backend
npm install

# Return to root directory
cd ..
```

### 2. Set Up Python Backend Database

```bash
cd backend_python

# Create PostgreSQL database (if not exists)
createdb health_monitoring

# Create .env file with your PostgreSQL credentials
cat > .env << EOF
GEMINI_API_KEY=KEYVALUE
DB_NAME=health_monitoring
DB_USER=postgres
DB_PASSWORD=your_password_here
DB_HOST=localhost
DB_PORT=5432
EOF

# Initialize database schema
psql -U postgres -d health_monitoring < schema.sql

cd ..
```

### 3. Start Both Backends

```bash
# From project root directory
./start_backends.sh
```

This will start:
- Node.js backend on http://localhost:3000
- Python backend on http://localhost:5001

### 4. Run Flutter App

```bash
# In a new terminal
flutter run
```

## New Features Demo

### 1. Health Insights Tab
- Navigate to the new "Health" tab (heart icon) in the bottom navigation
- View:
  - Overall health score (0-100)
  - AI-generated daily health insights
  - Heart rate metrics (current, average, resting)
  - Activity data (steps, calories, active minutes)
  - Unified health & environment recommendations

### 2. Enhanced Recommendations
- The "Recommendations" tab now includes:
  - Health score integration
  - Unified insights combining air quality and health data
  - Personalized recommendations based on both environmental and health metrics

### 3. Backend Endpoints

#### Python Backend (Port 5001)
- `GET /api/users/:id/heart-rate` - Fitbit heart rate data
- `GET /api/users/:id/activity` - Activity metrics
- `GET /api/users/:id/health-summary` - Overall health score and trends
- `POST /api/insights/daily-summary` - AI-generated daily health insights
- `GET /api/insights/unified/:id` - Combined environmental and health recommendations

#### Node.js Backend (Port 3000)
- All existing environmental endpoints remain unchanged
- `GET /api/air-quality/current`
- `GET /api/weather/current`
- `GET /api/pollen/forecast`

## Testing the Integration

1. **Verify Both Backends Are Running**:
   ```bash
   # Check Node.js backend
   curl http://localhost:3000/api/air-quality/current
   
   # Check Python backend
   curl http://localhost:5001/api/users/user_001/health-summary
   ```

2. **Test in Flutter App**:
   - Open the app and navigate to the Health tab
   - Pull to refresh to load latest data
   - Check the Recommendations tab for unified insights

## Data Sources

- **Environmental Data**: Real-time APIs (OpenWeather, AirNow, etc.)
- **Health Data**: Synthetic Fitbit data from Wearipedia (2.6M+ records)
- **AI Insights**: Google Gemini 2.5 Pro with health-specific prompts

## Troubleshooting

### Backend Issues
- **Port conflicts**: Kill existing processes with `lsof -ti:3000 | xargs kill -9` and `lsof -ti:5001 | xargs kill -9`
- **Database connection**: Ensure PostgreSQL is running and credentials in `.env` are correct
- **Missing dependencies**: Re-run pip/npm install commands

### Frontend Issues
- **No data showing**: Ensure both backends are running before launching the Flutter app
- **API errors**: Check backend console logs for detailed error messages

### Integration Issues
- **Empty health insights**: Verify Gemini API key is valid and has necessary permissions
- **Unified insights not working**: Both backends must be running for unified recommendations

## Architecture Overview

```
Flutter App
├── Environmental Data ──────→ Node.js Backend (Port 3000)
├── Health Insights ─────────→ Python Backend (Port 5001)  
└── Unified View ────────────→ UnifiedHealthService
                                  │
                                  ├── Fetches from both backends
                                  ├── Combines data intelligently
                                  └── Provides unified recommendations
```

## Key Files Added/Modified

### Backend
- `backend_python/` - New Python backend for health insights
- `backend/` - Node.js backend for environmental data
- `start_backends.sh` - Startup script for both backends

### Frontend
- `lib/screens/main/health_insights_tab.dart` - New health insights screen
- `lib/services/health_insights_service.dart` - Service for Python backend
- `lib/services/unified_health_service.dart` - Combines both data sources
- `lib/screens/main/home_screen.dart` - Added Health tab to navigation
- `lib/screens/main/recommendations_tab.dart` - Enhanced with health data

## Demo User

For testing, use user ID: `user_001`

This user has pre-loaded Fitbit data and will show realistic health metrics and AI insights.

## Next Steps

1. Implement real Fitbit OAuth integration
2. Add health metric visualizations (charts/graphs)
3. Create health alerts based on thresholds
4. Add export functionality for health reports
5. Implement caching for better performance

---

**Note**: This is a development setup. For production, ensure proper security measures, API rate limiting, and data privacy compliance.