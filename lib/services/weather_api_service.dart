import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';
import '../models/air_quality.dart';
import 'api_service.dart';

// Temporary models for backward compatibility until Google Weather API is implemented
class AirQualityForecast {
  final double overallScore;
  final String healthRecommendation;
  final String dominantPollutant;
  final List<AirQualityData> hourlyForecasts;

  AirQualityForecast({
    required this.overallScore,
    required this.healthRecommendation,
    required this.dominantPollutant,
    required this.hourlyForecasts,
  });
}

class PollenForecast {
  final List<PollenData> dailyForecasts;

  PollenForecast({required this.dailyForecasts});
}

class PollenData {
  final DateTime date;
  final String risk;
  final Map<String, double> levels;

  PollenData({
    required this.date,
    required this.risk,
    required this.levels,
  });

  factory PollenData.fromJson(Map<String, dynamic> json) {
    DateTime date;
    if (json['date'] is String) {
      date = DateTime.parse(json['date']);
    } else if (json['date'] is Map) {
      final dateObj = json['date'];
      date = DateTime(dateObj['year'], dateObj['month'], dateObj['day']);
    } else {
      date = DateTime.now();
    }

    return PollenData(
      date: date,
      risk: json['risk'] ?? 'Low',
      levels: (json['levels'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }
}

class WeatherApiService {
  // Get current weather data - using backend API only
  static Future<WeatherData?> getCurrentWeather(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    return _getCurrentWeatherFromBackend(latitude, longitude);
  }

  // Get current weather from backend API
  static Future<WeatherData?> _getCurrentWeatherFromBackend(
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/weather/current?lat=$latitude&lon=$longitude',
        ),
        headers: ApiService.getHeaders(includeAuth: false),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Backend Weather API Response received');

        // Backend returns data directly, not nested in 'weather'
        return WeatherData(
          temperature: (data['temperature'] ?? 0.0).toDouble(),
          feelsLike: (data['feelsLike'] ?? 0.0).toDouble(),
          humidity: (data['humidity'] ?? 0.0).toDouble(),
          pressure: (data['pressure'] ?? 0.0).toDouble(),
          windSpeed: (data['windSpeed'] ?? 0.0).toDouble(),
          windDirection: (data['windDirection'] ?? 0.0).toDouble(),
          uvIndex: (data['uvIndex'] ?? 0.0).toDouble(),
          visibility: (data['visibility'] ?? 10000.0).toDouble(),
          cloudCover: (data['clouds'] ?? 0.0).toDouble(),
          dewPoint: (data['dewPoint'] ?? 0.0).toDouble(),
          description: data['description'] ?? 'Unknown',
          icon: data['icon'] ?? '01d',
          timestamp: data['timestamp'] != null
            ? DateTime.parse(data['timestamp'])
            : DateTime.now(),
          heatWaveAlert: _checkHeatWave((data['temperature'] ?? 0.0).toDouble()),
          coldWaveAlert: _checkColdWave((data['temperature'] ?? 0.0).toDouble()),
          stagnationEvent: data['stagnationEvent']?['active'] ?? false,
          precipitationIntensity: data['precipitationIntensity']?.toDouble(),
          precipitationType: data['precipitationType'],
        );
      }

      debugPrint('Failed to fetch weather data from backend: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching weather data from backend: $e');
      return null;
    }
  }

  // Get weather forecast - using backend API only
  static Future<WeatherForecast?> getWeatherForecast(
    double latitude,
    double longitude, {
    String? locationName,
    int days = 10,
  }) async {
    return _getWeatherForecastFromBackend(latitude, longitude, days);
  }

  // Get weather forecast from backend API
  static Future<WeatherForecast?> _getWeatherForecastFromBackend(
    double latitude,
    double longitude,
    int days,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/weather/forecast?lat=$latitude&lon=$longitude&days=$days',
        ),
        headers: ApiService.getHeaders(includeAuth: false),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Weather Forecast API Response received');
        debugPrint('Forecast data keys: ${data.keys}');

        final hourlyData = <WeatherData>[];
        final dailyData = <WeatherData>[];

        // Parse hourly forecast (backend returns directly, not nested)
        if (data['hourly'] != null) {
          for (final hour in data['hourly']) {
            hourlyData.add(WeatherData(
              temperature: (hour['temperature'] ?? 0.0).toDouble(),
              feelsLike: (hour['feelsLike'] ?? 0.0).toDouble(),
              humidity: (hour['humidity'] ?? 0.0).toDouble(),
              pressure: (hour['pressure'] ?? 0.0).toDouble(),
              windSpeed: (hour['windSpeed'] ?? 0.0).toDouble(),
              windDirection: (hour['windDirection'] ?? 0.0).toDouble(),
              uvIndex: 0.0, // UV index not available in hourly forecast
              visibility: (hour['visibility'] ?? 10000.0).toDouble(),
              cloudCover: (hour['clouds'] ?? 0.0).toDouble(),
              dewPoint: 0.0, // Dew point not available in hourly forecast
              description: hour['description'] ?? 'Unknown',
              icon: hour['icon'] ?? '01d',
              timestamp: DateTime.parse(hour['datetime']),
              heatWaveAlert: _checkHeatWave((hour['temperature'] ?? 0.0).toDouble()),
              coldWaveAlert: _checkColdWave((hour['temperature'] ?? 0.0).toDouble()),
              stagnationEvent: _checkStagnation((hour['windSpeed'] ?? 0.0).toDouble()),
              precipitationIntensity: (hour['pop'] ?? 0.0) * 10, // Convert probability to intensity estimate
              precipitationType: hour['pop'] != null && hour['pop'] > 0 ? 'rain' : null,
            ));

              if (hourlyData.length >= 48) break; // Limit to 48 hours
            }
          }

        // Parse daily forecast
        if (data['daily'] != null) {
          for (final day in data['daily']) {
            dailyData.add(WeatherData(
              temperature: (day['maxTemp'] ?? 0.0).toDouble(),
              minTemp: (day['minTemp'] ?? 0.0).toDouble(),
              maxTemp: (day['maxTemp'] ?? 0.0).toDouble(),
              humidity: (day['avgHumidity'] ?? 0.0).toDouble(),
              description: day['description'] ?? 'Unknown',
              icon: day['icon'] ?? '01d',
              timestamp: DateTime.parse(day['date']),
              precipitationProbability: (day['maxPop'] ?? 0.0).toDouble(),
              // These fields are not in daily summary, so use defaults
              feelsLike: 0.0,
              pressure: 0.0,
              windSpeed: 0.0,
              windDirection: 0.0,
              uvIndex: 0.0,
              visibility: 10000.0,
              cloudCover: 0.0,
              dewPoint: 0.0,
            ));
          }
        }

        return WeatherForecast(
          hourly: hourlyData, 
          daily: dailyData,
          lastUpdated: DateTime.now(),
        );
      }

      debugPrint('Failed to fetch weather forecast: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching weather forecast: $e');
      return null;
    }
  }

  // Get historical weather data
  static Future<List<WeatherData>?> getHistoricalWeather(
    double latitude,
    double longitude, {
    String? locationName,
    int days = 7,
  }) async {
    try {
      // Get historical weather data from backend - this should return actual historical data from Google Weather API
      final response = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/weather/historical?lat=$latitude&lon=$longitude&days=$days',
        ),
        headers: ApiService.getHeaders(includeAuth: false),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Weather Historical API Response received');

        // Check if response indicates no data available
        if (data == null || (data is Map && data['error'] != null)) {
          debugPrint('Historical weather data not available: ${data?['error'] ?? 'Unknown error'}');
          return null;
        }

        final List<WeatherData> historicalData = [];

        // Handle both array directly or wrapped in 'data' key
        final historyList = data is List ? data : (data['data'] ?? data);

        if (historyList != null && historyList is List) {
          for (final item in historyList) {
            historicalData.add(WeatherData(
              temperature: (item['temperature'] ?? 0.0).toDouble(),
              feelsLike: (item['feelsLike'] ?? item['feels_like'] ?? item['temperature'] ?? 0.0).toDouble(),
              humidity: (item['humidity'] ?? 0.0).toDouble(),
              pressure: (item['pressure'] ?? 0.0).toDouble(),
              windSpeed: (item['windSpeed'] ?? item['wind_speed'] ?? 0.0).toDouble(),
              windDirection: (item['windDirection'] ?? item['wind_direction'] ?? 0.0).toDouble(),
              uvIndex: (item['uvIndex'] ?? item['uv_index'] ?? 0.0).toDouble(),
              visibility: (item['visibility'] ?? 10000.0).toDouble(),
              cloudCover: (item['cloudCover'] ?? item['cloud_cover'] ?? 0.0).toDouble(),
              dewPoint: (item['dewPoint'] ?? item['dew_point'] ?? 0.0).toDouble(),
              description: item['description'] ?? 'Unknown',
              icon: item['icon'] ?? '01d',
              timestamp: DateTime.parse(item['timestamp'] ?? DateTime.now().toIso8601String()),
              heatWaveAlert: item['heatWaveAlert'] ?? item['heat_wave_alert'] ?? _checkHeatWave((item['temperature'] ?? 0.0).toDouble()),
              coldWaveAlert: item['coldWaveAlert'] ?? item['cold_wave_alert'] ?? _checkColdWave((item['temperature'] ?? 0.0).toDouble()),
              stagnationEvent: item['stagnationEvent'] ?? item['stagnation_event'] ?? _checkStagnation((item['windSpeed'] ?? item['wind_speed'] ?? 0.0).toDouble()),
              precipitationIntensity: (item['precipitationIntensity'] ?? item['precipitation_intensity'])?.toDouble(),
              precipitationType: item['precipitationType'] ?? item['precipitation_type'],
            ));
          }
        }

        return historicalData.isEmpty ? null : historicalData;
      }

      debugPrint('Failed to fetch historical weather: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching historical weather: $e');
      return null;
    }
  }

  // Get air quality forecast
  static Future<AirQualityForecast?> getAirQualityForecast(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/air_quality/forecast?lat=$latitude&lon=$longitude',
        ),
        headers: ApiService.getHeaders(includeAuth: false),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Air Quality Forecast API Response received');

        final hourlyForecasts = <AirQualityData>[];
        if (data['hourly'] != null) {
          for (final item in data['hourly']) {
            hourlyForecasts.add(AirQualityData.fromJson(item));
          }
        }

        return AirQualityForecast(
          overallScore: (data['overallScore'] ?? 0.0).toDouble(),
          healthRecommendation: data['healthRecommendation'] ?? 'No recommendation available.',
          dominantPollutant: data['dominantPollutant'] ?? 'N/A',
          hourlyForecasts: hourlyForecasts,
        );
      }
      debugPrint('Failed to fetch air quality forecast: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching air quality forecast: $e');
      return null;
    }
  }

  // Get pollen forecast
  static Future<PollenForecast?> getPollenForecast(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiService.baseUrl}/weather/pollen/forecast?lat=$latitude&lon=$longitude',
        ),
        headers: ApiService.getHeaders(includeAuth: false),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Pollen Forecast API Response received');

        final dailyForecasts = <PollenData>[];
        if (data['daily'] != null) {
          for (final item in data['daily']) {
            dailyForecasts.add(PollenData.fromJson(item));
          }
        }

        return PollenForecast(
          dailyForecasts: dailyForecasts,
        );
      }
      debugPrint('Failed to fetch pollen forecast: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error fetching pollen forecast: $e');
      return null;
    }
  }

  // Helper methods for detecting extreme conditions
  static bool _checkHeatWave(double? temp) {
    if (temp == null) return false;
    return temp > 35; // Temperature above 35°C
  }

  static bool _checkColdWave(double? temp) {
    if (temp == null) return false;
    return temp < -5; // Example threshold for cold wave
  }

  static bool _checkStagnation(double? windSpeed) {
    if (windSpeed == null) return false;
    return windSpeed < 2; // Wind speed below 2 m/s indicates stagnation
  }

}