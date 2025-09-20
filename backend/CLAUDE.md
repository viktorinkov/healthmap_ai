# HealthMap AI Backend API Documentation

## Overview
This is the REST API backend for the HealthMap AI application, providing centralized data management, user authentication, and environmental health data aggregation.

## Architecture

### Technology Stack
- **Runtime**: Node.js with Express.js
- **Database**: SQLite3 (local file-based)
- **Authentication**: JWT tokens with bcrypt password hashing
- **External APIs**:
  - Google Air Quality API
  - Google Pollen API
  - OpenWeather API

### Key Features
1. **User Management**: Registration, authentication, and medical profile storage
2. **Pin Management**: Location tracking with historical data
3. **Environmental Data**: Air quality, weather, and pollen data aggregation
4. **Historical Tracking**: Hourly snapshots of environmental data for all user pins
5. **Health Recommendations**: Personalized recommendations based on medical profiles
6. **Smart Caching**: Reduces external API calls with TTL-based caching

## API Endpoints

### Base URL
```
http://localhost:3000/api
```

### Authentication Endpoints

#### Register User
```
POST /auth/register
Body: {
  "email": "user@example.com",
  "password": "securepassword",
  "name": "John Doe" (optional)
}
Response: {
  "user": { "id", "email", "name" },
  "token": "jwt-token"
}
```

#### Login
```
POST /auth/login
Body: {
  "email": "user@example.com",
  "password": "password"
}
Response: {
  "user": { "id", "email", "name" },
  "token": "jwt-token"
}
```

### Environmental Data Endpoints

#### Get Current Air Quality
```
GET /air-quality/current?lat=37.7749&lon=-122.4194
Response: {
  "aqi": 42,
  "category": "Good",
  "color": "#00e400",
  "pm25": 10.5,
  "pm10": 15.2,
  "dominantPollutant": "pm25"
}
```

#### Get Current Weather
```
GET /weather/current?lat=37.7749&lon=-122.4194
Response: {
  "temperature": 22.5,
  "humidity": 65,
  "pressure": 1013,
  "windSpeed": 5.2,
  "description": "partly cloudy"
}
```

#### Get Pollen Data
```
GET /weather/pollen?lat=37.7749&lon=-122.4194
Response: {
  "treePollen": 3,
  "grassPollen": 2,
  "weedPollen": 1,
  "overallRisk": "Moderate"
}
```

#### Get Combined Environmental Data
```
GET /weather/environmental?lat=37.7749&lon=-122.4194
Response: {
  "location": { "latitude", "longitude" },
  "weather": { ... },
  "pollen": { ... },
  "airQuality": { ... }
}
```

### Pin Management Endpoints (Requires Authentication)

#### Get User Pins
```
GET /pins
Headers: { "Authorization": "Bearer <token>" }
Query: ?includeCurrentData=true (optional)
Response: Array of pin objects with optional current environmental data
```

#### Create Pin
```
POST /pins
Headers: { "Authorization": "Bearer <token>" }
Body: {
  "name": "Home",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "address": "123 Main St" (optional)
}
```

#### Update Pin
```
PUT /pins/:id
Headers: { "Authorization": "Bearer <token>" }
Body: {
  "name": "New Name",
  "address": "New Address"
}
```

#### Delete Pin
```
DELETE /pins/:id
Headers: { "Authorization": "Bearer <token>" }
```

### Health Endpoints (Requires Authentication)

#### Get Personalized Recommendations
```
GET /health/recommendations?lat=37.7749&lon=-122.4194
Headers: { "Authorization": "Bearer <token>" }
Response: {
  "recommendations": {
    "general": [...],
    "outdoor": [...],
    "indoor": [...],
    "precautions": [...],
    "riskLevel": "Low/Moderate/High"
  },
  "environmentalData": { ... },
  "medicalProfile": { ... }
}
```

#### Get Health Alerts for All Pins
```
GET /health/alerts
Headers: { "Authorization": "Bearer <token>" }
Response: Array of alert objects for each pin
```

### User Profile Endpoints (Requires Authentication)

#### Get User Profile
```
GET /users/profile
Headers: { "Authorization": "Bearer <token>" }
Response: {
  "user": { ... },
  "medicalProfile": { ... }
}
```

#### Update Medical Profile
```
POST /users/medical-profile
Headers: { "Authorization": "Bearer <token>" }
Body: {
  "age": 35,
  "has_respiratory_condition": true,
  "has_heart_condition": false,
  "has_allergies": true,
  "is_elderly": false,
  "is_child": false,
  "is_pregnant": false,
  "exercises_outdoors": true,
  "medications": "Albuterol inhaler",
  "notes": "Mild asthma"
}
```

## Database Schema

### Users Table
- `id`: Primary key
- `email`: Unique user email
- `password`: Hashed password
- `name`: User's display name
- `created_at`: Account creation timestamp
- `updated_at`: Last update timestamp

### Medical Profiles Table
- `id`: Primary key
- `user_id`: Foreign key to users
- `age`: User's age
- `has_respiratory_condition`: Boolean flag
- `has_heart_condition`: Boolean flag
- `has_allergies`: Boolean flag
- `is_elderly`: Boolean flag
- `is_child`: Boolean flag
- `is_pregnant`: Boolean flag
- `exercises_outdoors`: Boolean flag
- `medications`: Text field for medications
- `notes`: Additional medical notes

### Pins Table
- `id`: Primary key
- `user_id`: Foreign key to users
- `name`: Pin name/label
- `latitude`: GPS latitude
- `longitude`: GPS longitude
- `address`: Street address (optional)
- `is_active`: Soft delete flag
- `created_at`: Creation timestamp

### Historical Data Tables
- `air_quality_history`: Stores AQI and pollutant data
- `weather_history`: Stores temperature, humidity, etc.
- `pollen_history`: Stores pollen levels
- All linked to pins via `pin_id` foreign key

### Cache Table
- `api_cache`: Stores temporary API responses with TTL

## Data Collection Schedule

The backend automatically collects environmental data for all active pins:
- **Frequency**: Every hour at the top of the hour
- **Data Collected**: Air quality, weather, and pollen data
- **Retention**: 30 days of historical data
- **Cache Cleanup**: Every 6 hours

## Environment Variables

Create a `.env` file in the backend directory:

```env
PORT=3000
NODE_ENV=development
JWT_SECRET=your-secure-jwt-secret
DATABASE_PATH=./database.db

# Google Services
GOOGLE_MAPS_API_KEY=your-google-maps-api-key
GEMINI_API_KEY=your-gemini-api-key

# Weather Services
OPENWEATHER_API_KEY=your-openweather-api-key

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# Cache TTL (seconds)
AIR_QUALITY_CACHE_TTL=1800
WEATHER_CACHE_TTL=3600
POLLEN_CACHE_TTL=7200
```

## Security Features

1. **Password Hashing**: Uses bcryptjs with salt rounds
2. **JWT Authentication**: Tokens expire after 30 days
3. **Rate Limiting**: 100 requests per 15-minute window
4. **CORS Configuration**: Configured for local development
5. **Helmet.js**: Security headers enabled
6. **Input Validation**: Using express-validator

## Error Handling

All endpoints return consistent error responses:
```json
{
  "error": "Error message",
  "details": [] // Optional validation errors
}
```

HTTP Status Codes:
- `200`: Success
- `201`: Created
- `400`: Bad Request
- `401`: Unauthorized
- `404`: Not Found
- `409`: Conflict (e.g., duplicate resource)
- `500`: Internal Server Error

## Development Commands

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Start production server
npm start

# Run database migrations (if needed)
npm run migrate
```

## Testing the API

### Health Check
```bash
curl http://localhost:3000/api/health-check
```

### Register a User
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'
```

### Get Air Quality (No Auth Required)
```bash
curl "http://localhost:3000/api/air-quality/current?lat=37.7749&lon=-122.4194"
```

### Get Recommendations (Auth Required)
```bash
curl "http://localhost:3000/api/health/recommendations?lat=37.7749&lon=-122.4194" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## Deployment Considerations

1. **Database**: Consider migrating to PostgreSQL or MySQL for production
2. **Environment**: Use proper environment variable management
3. **HTTPS**: Enable SSL/TLS in production
4. **Logging**: Implement proper logging (e.g., Winston)
5. **Monitoring**: Add health checks and monitoring
6. **Scaling**: Consider using PM2 or containerization with Docker

## Future Enhancements

1. **WebSocket Support**: Real-time updates for environmental changes
2. **Push Notifications**: Alert users of health risks
3. **Data Analytics**: Aggregate health trends over time
4. **Machine Learning**: Predictive health recommendations
5. **Third-party Integrations**: Fitbit, Apple Health, etc.
6. **Multi-language Support**: Internationalization

## Troubleshooting

### Common Issues

1. **Database Lock Error**
   - Solution: Ensure only one instance is running
   - Check for stale lock files

2. **API Key Errors**
   - Verify all API keys in .env are valid
   - Check API quotas and rate limits

3. **CORS Issues**
   - Update CORS configuration for your domain
   - Check request headers

4. **Authentication Failures**
   - Verify JWT_SECRET is set
   - Check token expiration

## Support

For issues or questions:
1. Check the logs in the console
2. Verify environment variables
3. Ensure database file has proper permissions
4. Test endpoints with curl or Postman

---

**Note**: This backend is designed for the HealthMap AI mobile application. Always ensure API keys are kept secure and never committed to version control.