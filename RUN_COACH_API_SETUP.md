# Run Coach API Keys Setup Guide

To use the Run Coach feature, you'll need to obtain API keys for the following services:

## 1. Google Maps API Key

**Required for:** Route generation, elevation data, places search

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable the following APIs:
   - Maps JavaScript API
   - Directions API
   - Places API
   - Roads API
   - Elevation API (optional but recommended)
   - Geocoding API

4. Go to "Credentials" → "Create Credentials" → "API Key"
5. Restrict the API key:
   - Application restrictions: HTTP referrers or None for development
   - API restrictions: Select the APIs you enabled

**Cost:** Free tier includes $200/month credit, which covers ~40,000 direction requests

## 2. OpenWeatherMap API Key

**Required for:** Air pollution data and weather forecasts

1. Sign up at [OpenWeatherMap](https://openweathermap.org/api)
2. Go to "API keys" tab in your account
3. Generate a new API key
4. Wait ~10 minutes for activation

**Cost:** Free tier includes:
- 1,000 calls/day for Air Pollution API
- 1,000 calls/day for Weather API

## 3. EPA AirNow API Key

**Required for:** Official US EPA air quality data

1. Go to [AirNow API](https://docs.airnowapi.org/)
2. Click "Request an API Key"
3. Fill out the form (usually approved within 1-2 business days)
4. You'll receive the key via email

**Cost:** Free for non-commercial use

## 4. PurpleAir API Key (Optional)

**Required for:** Crowdsourced hyperlocal air quality data

1. Email contact@purpleair.com requesting API access
2. Describe your use case (health app for runners)
3. Wait for approval (usually 3-5 business days)

**Cost:** Free for non-commercial use, paid tiers available

## 5. Update .env File

Once you have the keys, update your `/backend_python/.env` file:

```env
# Existing keys...

# Run Coach API Keys
GOOGLE_MAPS_API_KEY=your_actual_google_maps_key_here
OPENWEATHER_API_KEY=your_actual_openweather_key_here
AIRNOW_API_KEY=your_actual_airnow_key_here
PURPLEAIR_API_KEY=your_actual_purpleair_key_here  # Optional
```

## 6. Flutter Configuration

For the Flutter app, you'll also need to:

### Android
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="your_google_maps_api_key_here"/>
```

### iOS
Add to `ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("your_google_maps_api_key_here")
```

## Testing Without API Keys

For development/testing without API keys:

1. The Run Coach service includes mock data fallbacks
2. Set these test keys in .env to avoid errors:
   ```env
   GOOGLE_MAPS_API_KEY=test_key_development
   OPENWEATHER_API_KEY=test_key_development
   AIRNOW_API_KEY=test_key_development
   ```

3. The app will use mock data when API calls fail

## API Usage Estimates

For a typical user running 3-4 times per week:
- Google Maps: ~500 requests/month (well within free tier)
- OpenWeatherMap: ~200 requests/month (well within free tier)
- AirNow: ~150 requests/month (unlimited for free tier)

## Security Notes

- Never commit API keys to version control
- Add `.env` to `.gitignore` (already done)
- For production, use environment variables or secret management service
- Consider implementing API key proxy for mobile apps