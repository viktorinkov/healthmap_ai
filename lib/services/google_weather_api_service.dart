import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/weather_data.dart';
import 'api_service.dart';

class GoogleWeatherApiService {

  /// Get current weather conditions from backend (Google Weather API)
  static Future<WeatherData?> getCurrentWeather(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    try {
      final data = await ApiService.getBackendCurrentWeather(
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
      );

      debugPrint('Backend Weather API Current Conditions Response received');
      return _parseCurrentWeatherData(data);
    } catch (e) {
      debugPrint('Error fetching current weather from backend: $e');
      return null;
    }
  }

  /// Get weather forecast from backend (Google Weather API)
  static Future<WeatherForecast?> getWeatherForecast(
    double latitude,
    double longitude, {
    String? locationName,
    int days = 10,
  }) async {
    try {
      final data = await ApiService.getBackendWeatherForecast(
        latitude: latitude,
        longitude: longitude,
        days: days,
        locationName: locationName,
      );

      debugPrint('Backend Weather API Forecast Response received');
      return _parseForecastData(data);
    } catch (e) {
      debugPrint('Error fetching weather forecast from backend: $e');
      return null;
    }
  }

  /// Get hourly weather forecast from backend (Google Weather API)
  static Future<WeatherForecast?> getHourlyForecast(
    double latitude,
    double longitude, {
    String? locationName,
    int hours = 240, // Up to 10 days (240 hours)
  }) async {
    try {
      final data = await ApiService.getBackendHourlyWeatherForecast(
        latitude: latitude,
        longitude: longitude,
        hours: hours,
        locationName: locationName,
      );

      debugPrint('Backend Weather API Hourly Forecast Response received');
      return _parseHourlyForecastData(data);
    } catch (e) {
      debugPrint('Error fetching hourly forecast from backend: $e');
      return null;
    }
  }

  /// Parse current weather data from Google Weather API response
  static WeatherData _parseCurrentWeatherData(Map<String, dynamic> data) {
    final temperature = data['temperature']?['degrees']?.toDouble() ?? 0.0;
    final feelsLike = data['feelsLikeTemperature']?['degrees']?.toDouble() ?? temperature;
    final humidity = data['relativeHumidity']?.toDouble() ?? 0.0;
    final pressure = data['airPressure']?['meanSeaLevelMillibars']?.toDouble() ?? 0.0;
    final windSpeed = data['wind']?['speed']?['value']?.toDouble() ?? 0.0;
    final windDirection = data['wind']?['direction']?['degrees']?.toDouble() ?? 0.0;
    final uvIndex = data['uvIndex']?.toDouble() ?? 0.0;
    final visibility = data['visibility']?['distance']?.toDouble() ?? 10.0;
    final cloudCover = data['cloudCover']?.toDouble() ?? 0.0;
    final dewPoint = data['dewPoint']?['degrees']?.toDouble() ?? 0.0;
    
    // Parse weather condition
    final weatherCondition = data['weatherCondition'];
    final description = weatherCondition?['description']?['text'] ?? 'Unknown';
    final iconUri = weatherCondition?['iconBaseUri'] ?? '';
    final icon = _extractIconFromUri(iconUri);

    // Parse precipitation
    final precipitation = data['precipitation'];
    final precipitationProbability = precipitation?['probability']?['percent']?.toDouble() ?? 0.0;

    // Detect stagnation event based on low wind speed and high pressure
    final stagnationEvent = _detectStagnationEvent(windSpeed, pressure);

    // Detect extreme temperature alerts
    final heatWaveAlert = _checkHeatWave(temperature);
    final coldWaveAlert = _checkColdWave(temperature);

    return WeatherData(
      temperature: temperature,
      feelsLike: feelsLike,
      humidity: humidity,
      pressure: pressure,
      windSpeed: windSpeed,
      windDirection: windDirection,
      description: description,
      icon: icon,
      uvIndex: uvIndex,
      visibility: visibility * 1000, // Convert to meters
      cloudCover: cloudCover,
      dewPoint: dewPoint,
      precipitationProbability: precipitationProbability / 100.0, // Convert to 0-1 range
      timestamp: DateTime.now(),
      heatWaveAlert: heatWaveAlert,
      coldWaveAlert: coldWaveAlert,
      stagnationEvent: stagnationEvent,
    );
  }

  /// Parse forecast data from Google Weather API response
  static WeatherForecast _parseForecastData(Map<String, dynamic> data) {
    final dailyData = <WeatherData>[];
    final hourlyData = <WeatherData>[];

    final forecastDays = data['forecastDays'] as List? ?? [];

    for (final day in forecastDays) {
      // Parse daily data
      final maxTemp = day['maxTemperature']?['degrees']?.toDouble() ?? 0.0;
      final minTemp = day['minTemperature']?['degrees']?.toDouble() ?? 0.0;
      final avgTemp = (maxTemp + minTemp) / 2;

      final feelsLikeMax = day['feelsLikeMaxTemperature']?['degrees']?.toDouble() ?? maxTemp;
      final feelsLikeMin = day['feelsLikeMinTemperature']?['degrees']?.toDouble() ?? minTemp;
      final avgFeelsLike = (feelsLikeMax + feelsLikeMin) / 2;

      // Get daytime forecast for most weather data
      final daytimeForecast = day['daytimeForecast'];
      final nighttimeForecast = day['nighttimeForecast'];

      // Average humidity between day and night
      final dayHumidity = daytimeForecast?['relativeHumidity']?.toDouble() ?? 50.0;
      final nightHumidity = nighttimeForecast?['relativeHumidity']?.toDouble() ?? 50.0;
      final avgHumidity = (dayHumidity + nightHumidity) / 2;

      // Use daytime wind data
      final windSpeed = daytimeForecast?['wind']?['speed']?['value']?.toDouble() ?? 0.0;
      final windDirection = daytimeForecast?['wind']?['direction']?['degrees']?.toDouble() ?? 0.0;

      // Weather condition from daytime
      final weatherCondition = daytimeForecast?['weatherCondition'];
      final description = weatherCondition?['description']?['text'] ?? 'Unknown';
      final iconUri = weatherCondition?['iconBaseUri'] ?? '';
      final icon = _extractIconFromUri(iconUri);

      // Other metrics
      final uvIndex = daytimeForecast?['uvIndex']?.toDouble() ?? 0.0;
      final cloudCover = daytimeForecast?['cloudCover']?.toDouble() ?? 0.0;

      // Precipitation data
      final dayPrecip = daytimeForecast?['precipitation']?['probability']?['percent']?.toDouble() ?? 0.0;
      final nightPrecip = nighttimeForecast?['precipitation']?['probability']?['percent']?.toDouble() ?? 0.0;
      final avgPrecipProb = (dayPrecip > nightPrecip ? dayPrecip : nightPrecip) / 100.0; // Take the higher probability

      // Parse date
      final displayDate = day['displayDate'];
      final year = displayDate?['year'] ?? DateTime.now().year;
      final month = displayDate?['month'] ?? DateTime.now().month;
      final dayOfMonth = displayDate?['day'] ?? DateTime.now().day;
      final date = DateTime(year, month, dayOfMonth);

      // Detect stagnation event and extreme temperatures
      final stagnationEvent = _detectStagnationEvent(windSpeed, 1013.25); // Use standard pressure if not available
      final heatWaveAlert = _checkHeatWave(maxTemp);
      final coldWaveAlert = _checkColdWave(minTemp);

      dailyData.add(WeatherData(
        temperature: avgTemp,
        minTemp: minTemp,
        maxTemp: maxTemp,
        feelsLike: avgFeelsLike,
        humidity: avgHumidity,
        pressure: 1013.25, // Standard pressure if not provided in daily summary
        windSpeed: windSpeed,
        windDirection: windDirection,
        description: description,
        icon: icon,
        uvIndex: uvIndex,
        visibility: 10000.0, // Default visibility
        cloudCover: cloudCover,
        dewPoint: _calculateDewPoint(avgTemp, avgHumidity),
        precipitationProbability: avgPrecipProb,
        timestamp: date,
        heatWaveAlert: heatWaveAlert,
        coldWaveAlert: coldWaveAlert,
        stagnationEvent: stagnationEvent,
      ));
    }

    return WeatherForecast(
      hourly: hourlyData,
      daily: dailyData,
      lastUpdated: DateTime.now(),
    );
  }

  /// Parse hourly forecast data from Google Weather API response
  static WeatherForecast _parseHourlyForecastData(Map<String, dynamic> data) {
    final hourlyData = <WeatherData>[];
    final dailyData = <WeatherData>[];

    final forecastHours = data['forecasts'] as List? ?? [];

    for (final hour in forecastHours) {
      final temperature = hour['temperature']?['degrees']?.toDouble() ?? 0.0;
      final feelsLike = hour['feelsLikeTemperature']?['degrees']?.toDouble() ?? temperature;
      final humidity = hour['relativeHumidity']?.toDouble() ?? 0.0;
      final pressure = hour['airPressure']?['meanSeaLevelMillibars']?.toDouble() ?? 0.0;
      final windSpeed = hour['wind']?['speed']?['value']?.toDouble() ?? 0.0;
      final windDirection = hour['wind']?['direction']?['degrees']?.toDouble() ?? 0.0;
      final uvIndex = hour['uvIndex']?.toDouble() ?? 0.0;
      final visibility = hour['visibility']?['distance']?.toDouble() ?? 10.0;
      final cloudCover = hour['cloudCover']?.toDouble() ?? 0.0;
      final dewPoint = hour['dewPoint']?['degrees']?.toDouble() ?? 0.0;

      // Parse weather condition
      final weatherCondition = hour['weatherCondition'];
      final description = weatherCondition?['description']?['text'] ?? 'Unknown';
      final iconUri = weatherCondition?['iconBaseUri'] ?? '';
      final icon = _extractIconFromUri(iconUri);

      // Parse precipitation
      final precipitation = hour['precipitation'];
      final precipitationProbability = precipitation?['probability']?['percent']?.toDouble() ?? 0.0;

      // Parse time
      final timeStr = hour['time'];
      final timestamp = timeStr != null ? DateTime.parse(timeStr) : DateTime.now();

      // Detect stagnation event and extreme temperatures
      final stagnationEvent = _detectStagnationEvent(windSpeed, pressure);
      final heatWaveAlert = _checkHeatWave(temperature);
      final coldWaveAlert = _checkColdWave(temperature);

      hourlyData.add(WeatherData(
        temperature: temperature,
        feelsLike: feelsLike,
        humidity: humidity,
        pressure: pressure,
        windSpeed: windSpeed,
        windDirection: windDirection,
        description: description,
        icon: icon,
        uvIndex: uvIndex,
        visibility: visibility * 1000, // Convert to meters
        cloudCover: cloudCover,
        dewPoint: dewPoint,
        precipitationProbability: precipitationProbability / 100.0,
        timestamp: timestamp,
        heatWaveAlert: heatWaveAlert,
        coldWaveAlert: coldWaveAlert,
        stagnationEvent: stagnationEvent,
      ));
    }

    // Generate daily summaries from hourly data
    final Map<String, List<WeatherData>> dailyGroups = {};
    for (final hourData in hourlyData) {
      final dateKey = '${hourData.timestamp.year}-${hourData.timestamp.month.toString().padLeft(2, '0')}-${hourData.timestamp.day.toString().padLeft(2, '0')}';
      dailyGroups[dateKey] ??= [];
      dailyGroups[dateKey]!.add(hourData);
    }

    for (final entry in dailyGroups.entries) {
      final dayData = entry.value;
      if (dayData.isEmpty) continue;

      final temps = dayData.map((d) => d.temperature).toList();
      final minTemp = temps.reduce((a, b) => a < b ? a : b);
      final maxTemp = temps.reduce((a, b) => a > b ? a : b);
      final avgTemp = temps.reduce((a, b) => a + b) / temps.length;

      final avgHumidity = dayData.map((d) => d.humidity).reduce((a, b) => a + b) / dayData.length;
      final avgWindSpeed = dayData.map((d) => d.windSpeed).reduce((a, b) => a + b) / dayData.length;
      final avgPressure = dayData.map((d) => d.pressure).reduce((a, b) => a + b) / dayData.length;

      // Use data from midday (around 12 PM) for representative daily values
      final middayData = dayData.where((d) => d.timestamp.hour >= 10 && d.timestamp.hour <= 14).toList();
      final representativeData = middayData.isNotEmpty ? middayData.first : dayData.first;

      final stagnationEvent = _detectStagnationEvent(avgWindSpeed, avgPressure);
      final heatWaveAlert = _checkHeatWave(maxTemp);
      final coldWaveAlert = _checkColdWave(minTemp);

      dailyData.add(WeatherData(
        temperature: avgTemp,
        minTemp: minTemp,
        maxTemp: maxTemp,
        feelsLike: representativeData.feelsLike,
        humidity: avgHumidity,
        pressure: avgPressure,
        windSpeed: avgWindSpeed,
        windDirection: representativeData.windDirection,
        description: representativeData.description,
        icon: representativeData.icon,
        uvIndex: representativeData.uvIndex,
        visibility: representativeData.visibility,
        cloudCover: representativeData.cloudCover,
        dewPoint: representativeData.dewPoint,
        precipitationProbability: representativeData.precipitationProbability,
        timestamp: DateTime.parse(entry.key),
        heatWaveAlert: heatWaveAlert,
        coldWaveAlert: coldWaveAlert,
        stagnationEvent: stagnationEvent,
      ));
    }

    return WeatherForecast(
      hourly: hourlyData,
      daily: dailyData,
      lastUpdated: DateTime.now(),
    );
  }

  /// Extract icon name from Google Weather API icon URI
  static String _extractIconFromUri(String iconUri) {
    if (iconUri.isEmpty) return '01d';
    
    // Extract the last part of the URI path
    final segments = iconUri.split('/');
    final iconName = segments.isNotEmpty ? segments.last : '';
    
    // Map Google Weather icons to standard weather icon names
    switch (iconName) {
      case 'sunny':
        return '01d';
      case 'partly_cloudy':
        return '02d';
      case 'cloudy':
        return '03d';
      case 'overcast':
        return '04d';
      case 'drizzle':
      case 'light_rain':
        return '09d';
      case 'rain':
      case 'showers':
        return '10d';
      case 'thunderstorm':
        return '11d';
      case 'snow':
        return '13d';
      case 'fog':
      case 'mist':
        return '50d';
      default:
        return '01d';
    }
  }

  /// Detect atmospheric stagnation events
  static bool _detectStagnationEvent(double windSpeed, double pressure) {
    // Stagnation conditions:
    // 1. Low wind speeds (< 2 m/s or < 7.2 km/h)
    // 2. High pressure systems (> 1020 hPa) often contribute to stagnation
    const lowWindThreshold = 2.0; // m/s
    const highPressureThreshold = 1020.0; // hPa
    
    // Convert wind speed if it's in km/h (assume km/h if > 10)
    final windSpeedMs = windSpeed > 10 ? windSpeed / 3.6 : windSpeed;
    
    return windSpeedMs < lowWindThreshold && pressure > highPressureThreshold;
  }

  /// Check for heat wave conditions
  static bool _checkHeatWave(double temperature) {
    // Heat wave: Temperature > 35°C (95°F)
    return temperature > 35.0;
  }

  /// Check for cold wave conditions
  static bool _checkColdWave(double temperature) {
    // Cold wave: Temperature < -10°C (14°F)
    return temperature < -10.0;
  }

  /// Calculate dew point from temperature and humidity
  static double _calculateDewPoint(double temperature, double humidity) {
    if (humidity <= 0) return temperature - 10;
    
    // Magnus formula for dew point calculation
    const a = 17.27;
    const b = 237.7;
    
    final alpha = ((a * temperature) / (b + temperature)) + math.log(humidity / 100.0);
    return (b * alpha) / (a - alpha);
  }
}