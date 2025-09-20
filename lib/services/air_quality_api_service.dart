import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/air_quality.dart';
import 'api_keys.dart';

class AirQualityApiService {
  static const String _baseUrl = 'https://airquality.googleapis.com/v1';

  /// Get air quality data for a specific location
  static Future<AirQualityData?> getAirQuality(
    double latitude,
    double longitude, {
    String? locationName,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/currentConditions:lookup');

      final requestBody = {
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'extraComputations': [
          'HEALTH_RECOMMENDATIONS',
          'DOMINANT_POLLUTANT_CONCENTRATION',
          'POLLUTANT_CONCENTRATION',
          'LOCAL_AQI',
          'POLLUTANT_ADDITIONAL_INFO'
        ],
        'languageCode': 'en'
      };

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
        return _parseAirQualityResponse(data, latitude, longitude, locationName);
      } else {
        print('Error fetching air quality data: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception fetching air quality data: $e');
      return null;
    }
  }

  /// Parse the API response into our AirQualityData model
  static AirQualityData? _parseAirQualityResponse(
    Map<String, dynamic> data,
    double latitude,
    double longitude,
    String? locationName,
  ) {
    try {
      final indexes = data['indexes'] as List<dynamic>?;
      final pollutants = data['pollutants'] as List<dynamic>?;

      if (indexes == null || indexes.isEmpty) {
        return null;
      }

      // Get the Universal AQI index
      final universalAqi = indexes.firstWhere(
        (index) => index['code'] == 'uaqi',
        orElse: () => indexes.first,
      );

      // Parse pollutant concentrations
      double pm25 = 0.0;
      double pm10 = 0.0;
      double o3 = 0.0;
      double no2 = 0.0;

      if (pollutants != null) {
        for (final pollutant in pollutants) {
          final code = pollutant['code'] as String?;
          final concentration = pollutant['concentration']?['value'] as double?;

          if (concentration != null) {
            switch (code) {
              case 'pm25':
                pm25 = concentration;
                break;
              case 'pm10':
                pm10 = concentration;
                break;
              case 'o3':
                o3 = concentration;
                break;
              case 'no2':
                no2 = concentration;
                break;
            }
          }
        }
      }

      final aqiValue = (universalAqi['aqi'] as num?)?.toDouble() ?? 0.0;

      final metrics = AirQualityMetrics(
        pm25: pm25,
        pm10: pm10,
        o3: o3,
        no2: no2,
        wildfireIndex: 0.0, // Not available in API
        radon: 0.0, // Not available in API
      );

      final status = _getStatusFromAqi(aqiValue);
      final statusReason = universalAqi['displayName'] ?? 'Air quality assessment based on current conditions';

      return AirQualityData(
        id: 'api_${latitude}_${longitude}_${DateTime.now().millisecondsSinceEpoch}',
        locationName: locationName ?? 'Location',
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        metrics: metrics,
        status: status,
        statusReason: statusReason,
      );
    } catch (e) {
      print('Error parsing air quality response: $e');
      return null;
    }
  }

  /// Convert AQI value to our AirQualityStatus
  static AirQualityStatus _getStatusFromAqi(double aqi) {
    if (aqi <= 50) {
      return AirQualityStatus.good;
    } else if (aqi <= 100) {
      return AirQualityStatus.caution;
    } else {
      return AirQualityStatus.avoid;
    }
  }

  /// Get the heatmap tile URL for air quality visualization
  static String getHeatmapTileUrl(int zoom, int x, int y) {
    return 'https://airquality.googleapis.com/v1/mapTypes/UAQI_RED_GREEN/heatmapTiles/$zoom/$x/$y?key=${ApiKeys.googleMapsApiKey}';
  }
}