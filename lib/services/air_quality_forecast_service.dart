import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/air_quality_forecast.dart';
import 'api_keys.dart';

class AirQualityForecastService {
  static const String _baseUrl = 'https://airquality.googleapis.com/v1';

  // Cache for forecast data with 1-hour validity
  static final Map<String, AirQualityForecast> _forecastCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidity = Duration(hours: 1);

  /// Get air quality forecast for a specific location (up to 96 hours)
  /// We'll limit to 12 hours for the UI as requested
  /// Uses hourly caching and single API call optimization
  static Future<AirQualityForecast?> getForecast(
    double latitude,
    double longitude, {
    String? locationName,
    int hoursAhead = 12,
  }) async {
    final cacheKey = 'forecast_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}_$hoursAhead';

    // Check cache first (1-hour validity)
    if (_isCacheValid(cacheKey)) {
      debugPrint('Returning cached forecast data for $cacheKey');
      return _forecastCache[cacheKey];
    }

    try {
      // Use single API call to fetch all hours at once
      final forecast = await _getMultiHourForecast(
        latitude,
        longitude,
        hoursAhead,
        locationName,
      );

      if (forecast != null) {
        // Cache the result
        _updateCache(cacheKey, forecast);
        debugPrint('Cached new forecast data for $cacheKey with ${forecast.hourlyForecasts.length} hours');
      }

      return forecast;
    } catch (e) {
      debugPrint('Exception fetching air quality forecast: $e');
      return null;
    }
  }

  /// Get forecast for multiple hours in a single API call
  static Future<AirQualityForecast?> _getMultiHourForecast(
    double latitude,
    double longitude,
    int hoursAhead,
    String? locationName,
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/forecast:lookup');
      final now = DateTime.now().toUtc();

      // Calculate start and end times for the forecast period
      final startTime = DateTime.utc(now.year, now.month, now.day, now.hour + 1); // Next hour
      final endTime = startTime.add(Duration(hours: hoursAhead - 1));

      final requestBody = {
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'period': {
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
        },
        'pageSize': hoursAhead, // Request all hours in one call
        'extraComputations': [
          'POLLUTANT_CONCENTRATION',
          'DOMINANT_POLLUTANT_CONCENTRATION',
          'LOCAL_AQI',
        ],
        'languageCode': 'en'
      };

      debugPrint('Multi-hour Forecast API Request: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': ApiKeys.googleMapsApiKey,
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Multi-hour Forecast API Response received with ${data['hourlyForecasts']?.length ?? 0} hours');
        return _parseMultiHourResponse(data, latitude, longitude, locationName);
      } else {
        debugPrint('Error fetching multi-hour air quality forecast: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception fetching multi-hour air quality forecast: $e');
      return null;
    }
  }


  /// Parse multi-hour response from the API
  static AirQualityForecast? _parseMultiHourResponse(
    Map<String, dynamic> data,
    double latitude,
    double longitude,
    String? locationName,
  ) {
    try {
      final hourlyForecasts = data['hourlyForecasts'] as List<dynamic>?;
      if (hourlyForecasts == null || hourlyForecasts.isEmpty) {
        debugPrint('No hourly forecasts in multi-hour response');
        return null;
      }

      final List<AirQualityForecastHour> allHours = [];
      for (final hourData in hourlyForecasts) {
        final parsedHour = _parseHourData(hourData as Map<String, dynamic>);
        if (parsedHour != null) {
          allHours.add(parsedHour);
        }
      }

      if (allHours.isEmpty) {
        debugPrint('No valid hours parsed from multi-hour response');
        return null;
      }

      return AirQualityForecast(
        id: 'forecast_${latitude}_${longitude}_${DateTime.now().millisecondsSinceEpoch}',
        locationName: locationName ?? 'Location',
        latitude: latitude,
        longitude: longitude,
        requestTimestamp: DateTime.now(),
        hourlyForecasts: allHours,
      );
    } catch (e) {
      debugPrint('Error parsing multi-hour response: $e');
      return null;
    }
  }


  /// Parse individual hour data into AirQualityForecastHour
  static AirQualityForecastHour? _parseHourData(Map<String, dynamic> hourData) {
    try {
      // Parse timestamp
      final timestampStr = hourData['dateTime'] as String?;
      if (timestampStr == null) {
        debugPrint('No valid dateTime found in hour data');
        return null;
      }

      DateTime timestamp;
      try {
        timestamp = DateTime.parse(timestampStr);
      } catch (e) {
        debugPrint('Error parsing timestamp: $timestampStr, error: $e');
        return null;
      }

      // Parse indexes (AQI data)
      final indexes = hourData['indexes'] as List<dynamic>?;
      int? universalAqi;
      String? status;
      String? color;

      if (indexes != null && indexes.isNotEmpty) {
        final universalAqiIndex = indexes.firstWhere(
          (index) => index['code'] == 'uaqi',
          orElse: () => indexes.first,
        );

        universalAqi = (universalAqiIndex['aqi'] as num?)?.toInt();
        status = universalAqiIndex['category'] as String?;

        // Color comes as an object with RGB values, not a string
        final colorObj = universalAqiIndex['color'] as Map<String, dynamic>?;
        if (colorObj != null) {
          final red = (colorObj['red'] as num? ?? 0) * 255;
          final green = (colorObj['green'] as num? ?? 0) * 255;
          final blue = (colorObj['blue'] as num? ?? 0) * 255;
          color = '#${red.toInt().toRadixString(16).padLeft(2, '0')}${green.toInt().toRadixString(16).padLeft(2, '0')}${blue.toInt().toRadixString(16).padLeft(2, '0')}';
        }
      }

      // Parse pollutants - the response structure is different
      final pollutants = hourData['pollutants'] as List<dynamic>?;
      String? dominantPollutant;

      final List<PollutantConcentration> parsedPollutants = [];

      // Get dominant pollutant from indexes if available
      if (indexes != null && indexes.isNotEmpty) {
        final universalAqiIndex = indexes.firstWhere(
          (index) => index['code'] == 'uaqi',
          orElse: () => indexes.first,
        );
        dominantPollutant = universalAqiIndex['dominantPollutant'] as String?;
      }

      // Parse individual pollutant concentrations if available
      if (pollutants != null) {
        for (final pollutant in pollutants) {
          final code = pollutant['code'] as String?;
          final concentration = pollutant['concentration']?['value'] as num?;
          final unit = pollutant['concentration']?['units'] as String?;

          if (code != null && concentration != null) {
            final pollutantInfo = PollutantInfo.getPollutantInfo(code);
            final displayName = pollutantInfo?.displayName ?? code.toUpperCase();

            parsedPollutants.add(PollutantConcentration(
              code: code,
              displayName: displayName,
              concentration: concentration.toDouble(),
              unit: unit ?? (pollutantInfo?.unit ?? ''),
            ));
          }
        }
      } else {
        debugPrint('No pollutants data in response - only AQI available');
      }

      return AirQualityForecastHour(
        timestamp: timestamp,
        universalAqi: universalAqi,
        status: status,
        dominantPollutant: dominantPollutant,
        pollutants: parsedPollutants,
        color: color,
      );
    } catch (e) {
      debugPrint('Error parsing hour data: $e');
      return null;
    }
  }


  /// Get forecast for multiple pollutants as a convenient method
  static Future<Map<String, List<PollutantForecastPoint>>?> getPollutantForecasts(
    double latitude,
    double longitude, {
    List<String>? pollutantCodes,
  }) async {
    final forecast = await getForecast(latitude, longitude);
    if (forecast == null) return null;

    final codes = pollutantCodes ?? ['pm25', 'pm10', 'o3', 'no2', 'so2', 'co'];
    final Map<String, List<PollutantForecastPoint>> result = {};

    for (final code in codes) {
      final forecastPoints = forecast.getPollutantForecast(code);
      if (forecastPoints.isNotEmpty) {
        result[code] = forecastPoints;
      }
    }

    return result;
  }

  /// Get available pollutants for a location forecast
  static Future<List<String>?> getAvailablePollutants(
    double latitude,
    double longitude,
  ) async {
    final forecast = await getForecast(latitude, longitude, hoursAhead: 1);
    if (forecast == null || forecast.hourlyForecasts.isEmpty) return null;

    return forecast.hourlyForecasts.first.availablePollutants;
  }

  // Cache management methods
  static bool _isCacheValid(String key) {
    if (!_forecastCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now();

    return now.difference(timestamp) < _cacheValidity;
  }

  static void _updateCache(String key, AirQualityForecast forecast) {
    _forecastCache[key] = forecast;
    _cacheTimestamps[key] = DateTime.now();

    // Clean up old cache entries to prevent memory leaks
    _cleanupOldCacheEntries();
  }

  static void _cleanupOldCacheEntries() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheValidity) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _forecastCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      debugPrint('Cleaned up ${keysToRemove.length} old forecast cache entries');
    }
  }

  /// Clear all cached forecast data
  static void clearCache() {
    _forecastCache.clear();
    _cacheTimestamps.clear();
    debugPrint('Cleared all forecast cache data');
  }
}