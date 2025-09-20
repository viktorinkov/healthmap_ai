# Google Air Quality API - Comprehensive Data Reference

This document provides a detailed overview of all data that the Google Air Quality API can provide for the HealthMap AI application.

## 📋 Table of Contents
- [API Overview](#api-overview)
- [Available Endpoints](#available-endpoints)
- [Data Types](#data-types)
- [Pollutants](#pollutants)
- [Air Quality Indexes](#air-quality-indexes)
- [Health Recommendations](#health-recommendations)
- [Temporal Coverage](#temporal-coverage)
- [Geographic Coverage](#geographic-coverage)
- [Heatmap Visualizations](#heatmap-visualizations)
- [Implementation Status](#implementation-status)
- [Usage Examples](#usage-examples)

---

## 🌍 API Overview

The Google Air Quality API provides comprehensive, real-time air quality data with global coverage. It offers:

- **High Resolution**: Up to 500 x 500 meter resolution
- **Real-time Data**: Continuous hourly calculations
- **Global Coverage**: Available in over 100 countries
- **Research-backed**: Health recommendations based on scientific research
- **Multiple Data Types**: Current conditions, forecasts, and historical data

**Base URL**: `https://airquality.googleapis.com`

---

## 🔗 Available Endpoints

### 1. Current Conditions
```
POST /v1/currentConditions:lookup
```
- **Purpose**: Provides hourly current air quality information
- **Resolution**: Up to 500 x 500 meters
- **Update Frequency**: Real-time hourly updates
- **Geographic Coverage**: Over 100 countries

### 2. Forecast
```
POST /v1/forecast:lookup
```
- **Purpose**: Returns air quality forecast for specific locations
- **Forecast Range**: Up to 96 hours (4 days) into the future
- **Resolution**: Hourly forecasts
- **Data**: Same as current conditions but for future timestamps

### 3. History
```
POST /v1/history:lookup
```
- **Purpose**: Returns historical air quality data
- **Time Range**: Up to 720 hours (30 days) of past data
- **Resolution**: Hourly historical records
- **Maximum Records**: 168 per request (can paginate)

### 4. Heatmap Tiles
```
GET /v1/mapTypes/{mapType}/heatmapTiles/{zoom}/{x}/{y}
```
- **Purpose**: PNG tile images for visual representation
- **Map Types**: Various air quality and pollutant visualizations
- **Integration**: Compatible with Google Maps and other mapping services

---

## 📊 Data Types

### Core Response Structure
All endpoints return structured data including:

1. **DateTime Information**
   - Timestamp in RFC3339 UTC format
   - Time zone information
   - Data validity period

2. **Location Data**
   - Latitude and longitude coordinates
   - Region code (ISO 3166-1 alpha-2)
   - Administrative area information

3. **Environmental Data**
   - Air quality indexes
   - Pollutant concentrations
   - Dominant pollutant identification

4. **Health Information**
   - Population-specific recommendations
   - Risk level assessments
   - Activity guidance

---

## 🏭 Pollutants

The API provides detailed information about various air pollutants:

### Primary Pollutants
| Pollutant | Code | Unit | Description |
|-----------|------|------|-------------|
| **PM2.5** | `pm25` | μg/m³ | Fine particulate matter (≤2.5 micrometers) |
| **PM10** | `pm10` | μg/m³ | Coarse particulate matter (≤10 micrometers) |
| **Ozone** | `o3` | ppb | Ground-level ozone |
| **Nitrogen Dioxide** | `no2` | ppb | Traffic and industrial emissions |
| **Carbon Monoxide** | `co` | ppb | Combustion-related pollutant |
| **Sulfur Dioxide** | `so2` | ppb | Industrial and volcanic emissions |

### Secondary Pollutants
| Pollutant | Code | Unit | Description |
|-----------|------|------|-------------|
| **Nitrogen Oxides** | `nox` | ppb | Combined NO and NO2 |
| **Nitrogen Monoxide** | `no` | ppb | Traffic emissions |
| **Ammonia** | `nh3` | ppb | Agricultural and industrial sources |
| **Benzene** | `c6h6` | μg/m³ | Aromatic hydrocarbon |
| **Photochemical Oxidants** | `ox` | ppb | Secondary pollutants from photochemical reactions |
| **Non-methane Hydrocarbons** | `nmhc` | ppb | Volatile organic compounds |
| **Total Reduced Sulfur** | `trs` | μg/m³ | Industrial emissions |

### Pollutant Data Structure
For each pollutant, the API provides:
- **Concentration**: Measured value with units
- **Display Name**: Human-readable pollutant name
- **Full Name**: Complete chemical name
- **Additional Info**: Sources, effects, and context

---

## 📈 Air Quality Indexes

The API supports over 70 different air quality indexes:

### Universal Air Quality Index (UAQI)
- **Purpose**: Standardized global index
- **Scale**: 0-500+ (higher values indicate worse air quality)
- **Color Coding**: Standardized color palette for visualization
- **Categories**: Good, Moderate, Unhealthy for Sensitive Groups, Unhealthy, Very Unhealthy, Hazardous

### Local Air Quality Indexes
- **Coverage**: Country and region-specific indexes
- **Examples**:
  - US EPA AQI
  - European CAQI
  - UK DAQI
  - Canadian AQHI
  - And many more regional standards

### Index Data Structure
- **AQI Value**: Numerical index value
- **Category**: Qualitative category (Good, Moderate, etc.)
- **Display Name**: Localized category name
- **Color**: Standardized color representation
- **Dominant Pollutant**: Primary contributor to current AQI

---

## 🏥 Health Recommendations

The API provides research-backed health recommendations for different population groups:

### Population Groups
1. **General Population**
   - Recommendations for the general public
   - General activity guidance
   - Basic health precautions

2. **Children**
   - Age-specific recommendations
   - School activity guidance
   - Respiratory health protection

3. **Elderly**
   - Age-related health considerations
   - Reduced physical activity recommendations
   - Cardiovascular health protection

4. **Pregnant Women**
   - Pregnancy-specific health advice
   - Fetal development protection
   - Activity modifications

5. **Athletes**
   - Exercise and training modifications
   - Performance considerations
   - Enhanced exposure risks

6. **People with Asthma**
   - Respiratory condition management
   - Medication reminders
   - Activity restrictions

7. **People with Heart Disease**
   - Cardiovascular protection
   - Reduced exertion recommendations
   - Medical consultation advice

### Recommendation Structure
- **Population**: Target group identifier
- **Recommendation**: Specific actionable advice
- **Level**: Risk level (Safe, Caution, Avoid)
- **Activities**: Specific activity recommendations

---

## ⏰ Temporal Coverage

### Current Conditions
- **Update Frequency**: Hourly
- **Data Freshness**: Real-time (typically within 1 hour)
- **Availability**: 24/7 continuous coverage

### Historical Data
- **Time Range**: Up to 30 days (720 hours) in the past
- **Resolution**: Hourly data points
- **Pagination**: Maximum 168 records per request
- **Completeness**: May have gaps due to sensor availability

### Forecast Data
- **Time Range**: Up to 4 days (96 hours) into the future
- **Resolution**: Hourly forecasts
- **Accuracy**: Decreases with longer forecast periods
- **Updates**: Regularly updated with new meteorological data

---

## 🌐 Geographic Coverage

### Supported Regions
- **Countries**: Over 100 countries worldwide
- **Resolution**: Up to 500 x 500 meters in urban areas
- **Coverage Quality**: Varies by region based on monitoring infrastructure

### Regional Variations
- **High Coverage**: North America, Europe, East Asia
- **Moderate Coverage**: South America, Australia, parts of Africa
- **Limited Coverage**: Remote areas, some developing regions

### Data Sources
- **Government Monitoring**: Official air quality monitoring stations
- **Satellite Data**: Earth observation satellites
- **Modeling**: Atmospheric dispersion models
- **Crowdsourced**: Community-contributed data (where available)

---

## 🗺️ Heatmap Visualizations

### Available Map Types
1. **Universal AQI Heatmaps**
   - Color-coded air quality visualization
   - Multiple color palettes available
   - Zoom levels from country to street level

2. **Pollutant-Specific Heatmaps**
   - Individual pollutant concentration maps
   - Specialized visualizations for different pollutants
   - Scientific color scales

### Heatmap Features
- **Format**: PNG tiles compatible with mapping libraries
- **Zoom Levels**: Multiple zoom levels supported
- **Color Palettes**: Customizable color schemes
- **Transparency**: Overlay-compatible for map integration
- **Real-time Updates**: Updated hourly with latest data

---

## ✅ Implementation Status in HealthMap AI

### Currently Implemented ✅
- **Current Conditions**: ✅ Real-time air quality data
- **All Pollutants**: ✅ PM2.5, PM10, O3, NO2, CO, SO2, NH3, Benzene, etc.
- **Universal AQI**: ✅ Standardized air quality index
- **Health Recommendations**: ✅ Population-specific advice
- **Geographic Coverage**: ✅ Global location support
- **Visual Display**: ✅ Pollutant cards with color coding

### Planned/Possible Enhancements 🔄
- **Historical Data**: Collect and store for trend analysis
- **Forecast Integration**: 4-day air quality forecasts
- **Heatmap Tiles**: Map overlay visualizations
- **Local AQI**: Region-specific air quality indexes
- **Advanced Analytics**: Trend analysis and predictions

### Not Available/Limitations ⚠️
- **Real Historical Trends**: Google API doesn't store long-term historical data
- **Weather Integration**: Separate weather data needed
- **Indoor Air Quality**: Only outdoor environmental data
- **Sensor Data**: No direct access to individual sensor readings

---

## 💻 Usage Examples

### Basic Current Conditions Request
```json
{
  "location": {
    "latitude": 37.7749,
    "longitude": -122.4194
  },
  "extraComputations": [
    "HEALTH_RECOMMENDATIONS",
    "DOMINANT_POLLUTANT_CONCENTRATION",
    "POLLUTANT_CONCENTRATION",
    "LOCAL_AQI",
    "POLLUTANT_ADDITIONAL_INFO"
  ],
  "languageCode": "en"
}
```

### Forecast Request
```json
{
  "location": {
    "latitude": 37.7749,
    "longitude": -122.4194
  },
  "period": {
    "startTime": "2023-01-01T00:00:00Z",
    "endTime": "2023-01-05T00:00:00Z"
  },
  "extraComputations": [
    "HEALTH_RECOMMENDATIONS",
    "POLLUTANT_CONCENTRATION"
  ]
}
```

### Historical Data Request
```json
{
  "location": {
    "latitude": 37.7749,
    "longitude": -122.4194
  },
  "hours": 168,
  "pageSize": 72,
  "extraComputations": [
    "POLLUTANT_CONCENTRATION"
  ]
}
```

---

## 🔑 API Authentication

### Requirements
- **Google Cloud Project**: Active project with billing enabled
- **API Key**: Air Quality API must be enabled
- **OAuth 2.0**: Required scope: `https://www.googleapis.com/auth/cloud-platform`

### Rate Limits
- **Requests per Day**: Varies by billing plan
- **Requests per Second**: Subject to quotas
- **Data Volume**: Limited by plan and usage

---

## 📚 Additional Resources

### Documentation
- [Google Air Quality API Overview](https://developers.google.com/maps/documentation/air-quality/overview)
- [API Reference](https://developers.google.com/maps/documentation/air-quality/reference/rest)
- [Client Libraries](https://developers.google.com/maps/documentation/air-quality/client-library)

### Related APIs
- **Google Maps Platform**: For location and mapping services
- **Weather APIs**: For meteorological data
- **Places API**: For location search and details

---

## ⚡ Quick Integration Guide

### Flutter Implementation
```dart
// Current implementation in HealthMap AI
final airQuality = await AirQualityApiService.getAirQuality(
  latitude,
  longitude,
  locationName: locationName,
);

// Response includes:
// - Universal AQI
// - All available pollutants
// - Health recommendations
// - Timestamp and location data
```

### Key Features in App
1. **Real-time Data**: Current conditions from Google API
2. **Comprehensive Pollutants**: All available pollutants displayed
3. **Health Advice**: Research-backed recommendations
4. **Visual Indicators**: Color-coded pollution levels
5. **Location-based**: GPS and pinned location support

---

*Last Updated: 2024-01-20*
*API Version: v1*
*Documentation Status: Complete*