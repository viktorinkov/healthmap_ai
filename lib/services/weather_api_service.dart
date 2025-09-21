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
          temperature: data['temperature'] != null ? (data['temperature']).toDouble() : 0.0,
          feelsLike: data['feelsLike'] != null ? (data['feelsLike']).toDouble() : 0.0,
          humidity: data['humidity'] != null ? (data['humidity']).toDouble() : 0.0,
          pressure: data['pressure'] != null ? (data['pressure']).toDouble() : 0.0,
          windSpeed: data['windSpeed'] != null ? (data['windSpeed']).toDouble() : 0.0,
          windDirection: data['windDirection'] != null ? (data['windDirection']).toDouble() : 0.0,
          uvIndex: data['uvIndex'] != null ? (data['uvIndex']).toDouble() : 0.0,
          visibility: data['visibility'] != null ? (data['visibility']).toDouble() : 10000.0,
          cloudCover: data['clouds'] != null ? (data['clouds']).toDouble() : 0.0,
          dewPoint: data['dewPoint'] != null ? (data['dewPoint']).toDouble() : 0.0,
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
              temperature: hour['temperature'] != null ? (hour['temperature']).toDouble() : 0.0,
              feelsLike: hour['feelsLike'] != null ? (hour['feelsLike']).toDouble() : 0.0,
              humidity: hour['humidity'] != null ? (hour['humidity']).toDouble() : 0.0,
              pressure: hour['pressure'] != null ? (hour['pressure']).toDouble() : 0.0,
              windSpeed: hour['windSpeed'] != null ? (hour['windSpeed']).toDouble() : 0.0,
              windDirection: hour['windDirection'] != null ? (hour['windDirection']).toDouble() : 0.0,
              uvIndex: hour['uvIndex'] != null ? (hour['uvIndex']).toDouble() : 0.0,
              visibility: hour['visibility'] != null ? (hour['visibility']).toDouble() : 10000.0,
              cloudCover: hour['cloudCover'] != null ? (hour['cloudCover']).toDouble() : 0.0,
              dewPoint: hour['dewPoint'] != null ? (hour['dewPoint']).toDouble() : 0.0,
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
            // Skip days without valid humidity data
            final humidity = day['humidity'] ?? day['avgHumidity'];
            if (humidity == null) {
              debugPrint('Skipping day with no humidity data: ${day['date'] ?? day['timestamp']}');
              continue;
            }

            dailyData.add(WeatherData(
              temperature: day['temperature'] != null ? (day['temperature']).toDouble() : (day['maxTemp'] != null && day['minTemp'] != null ? ((day['maxTemp'] + day['minTemp']) / 2).toDouble() : 0.0),
              minTemp: day['minTemp'] != null ? (day['minTemp']).toDouble() : 0.0,
              maxTemp: day['maxTemp'] != null ? (day['maxTemp']).toDouble() : 0.0,
              humidity: humidity.toDouble(),
              description: day['description'] ?? 'Unknown',
              icon: day['icon'] ?? '01d',
              timestamp: DateTime.parse(day['date'] ?? day['timestamp'] ?? DateTime.now().toIso8601String()),
              precipitationProbability: day['precipitationProbability'] != null ? (day['precipitationProbability']).toDouble() : (day['maxPop'] != null ? (day['maxPop']).toDouble() : 0.0),
              // Parse additional fields with fallbacks
              feelsLike: day['feelsLike'] != null ? (day['feelsLike']).toDouble() : (day['temperature'] != null ? (day['temperature']).toDouble() : 0.0),
              pressure: day['pressure'] != null ? (day['pressure']).toDouble() : 1013.25,
              windSpeed: day['windSpeed'] != null ? (day['windSpeed']).toDouble() : 0.0,
              windDirection: day['windDirection'] != null ? (day['windDirection']).toDouble() : 0.0,
              uvIndex: day['uvIndex'] != null ? (day['uvIndex']).toDouble() : 0.0,
              visibility: day['visibility'] != null ? (day['visibility']).toDouble() : 10000.0,
              cloudCover: day['cloudCover'] != null ? (day['cloudCover']).toDouble() : 0.0,
              dewPoint: day['dewPoint'] != null ? (day['dewPoint']).toDouble() : 0.0,
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
            // Skip items without valid data
            if (item['humidity'] == null) {
              debugPrint('Skipping historical item with no humidity data: ${item['timestamp']}');
              continue;
            }

            historicalData.add(WeatherData(
              temperature: item['temperature'] != null ? (item['temperature']).toDouble() : 0.0,
              feelsLike: item['feelsLike'] != null ? (item['feelsLike']).toDouble() : (item['temperature'] != null ? (item['temperature']).toDouble() : 0.0),
              humidity: (item['humidity']).toDouble(),
              pressure: item['pressure'] != null ? (item['pressure']).toDouble() : 1013.25,
              windSpeed: item['windSpeed'] != null ? (item['windSpeed']).toDouble() : 0.0,
              windDirection: item['windDirection'] != null ? (item['windDirection']).toDouble() : 0.0,
              uvIndex: item['uvIndex'] != null ? (item['uvIndex']).toDouble() : 0.0,
              visibility: item['visibility'] != null ? (item['visibility']).toDouble() : 10000.0,
              cloudCover: item['cloudCover'] != null ? (item['cloudCover']).toDouble() : 0.0,
              dewPoint: item['dewPoint'] != null ? (item['dewPoint']).toDouble() : 0.0,
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