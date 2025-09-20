import 'dart:convert';
import 'package:flutter/foundation.dart';
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
        debugPrint('Error fetching air quality data: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception fetching air quality data: $e');
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
          final concentration = (pollutant['concentration']?['value'] as num?)?.toDouble();

          if (concentration != null) {
            switch (code) {
              case 'p25':  // Correct API code for PM2.5
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

      // Parse additional pollutants if available
      double? co, so2, nox, no, nh3, c6h6, ox, nmhc, trs;

      if (pollutants != null) {
        for (final pollutant in pollutants) {
          final code = pollutant['code'] as String?;
          final concentration = (pollutant['concentration']?['value'] as num?)?.toDouble();

          if (concentration != null) {
            switch (code) {
              case 'co':
                co = concentration;
                break;
              case 'so2':
                so2 = concentration;
                break;
              case 'nox':
                nox = concentration;
                break;
              case 'no':
                no = concentration;
                break;
              case 'nh3':
                nh3 = concentration;
                break;
              case 'c6h6':
                c6h6 = concentration;
                break;
              case 'ox':
                ox = concentration;
                break;
              case 'nmhc':
                nmhc = concentration;
                break;
              case 'trs':
                trs = concentration;
                break;
            }
          }
        }
      }

      final metrics = AirQualityMetrics(
        pm25: pm25,
        pm10: pm10,
        o3: o3,
        no2: no2,
        co: co,
        so2: so2,
        nox: nox,
        no: no,
        nh3: nh3,
        c6h6: c6h6,
        ox: ox,
        nmhc: nmhc,
        trs: trs,
        wildfireIndex: 0.0, // Not available in API
        radon: 0.0, // Not available in API
        universalAqi: aqiValue.toInt(),
      );

      final status = _getStatusFromAqi(aqiValue);
      final statusReason = universalAqi['displayName'] ?? '';

      // Parse health recommendations if available
      List<HealthRecommendationTag>? healthRecommendations;
      final healthData = data['healthRecommendations'];
      if (healthData != null) {
        healthRecommendations = _parseHealthRecommendations(healthData);
      }

      return AirQualityData(
        id: 'api_${latitude}_${longitude}_${DateTime.now().millisecondsSinceEpoch}',
        locationName: locationName ?? 'Location',
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        metrics: metrics,
        status: status,
        statusReason: statusReason,
        healthRecommendations: healthRecommendations,
      );
    } catch (e) {
      debugPrint('Error parsing air quality response: $e');
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

  /// Parse health recommendations from Google API response
  static List<HealthRecommendationTag> _parseHealthRecommendations(Map<String, dynamic> healthData) {
    final recommendations = <HealthRecommendationTag>[];

    try {
      // Parse general population recommendations
      final generalPopulation = healthData['generalPopulation'];
      if (generalPopulation != null && generalPopulation is Map<String, dynamic>) {
        try {
          recommendations.add(HealthRecommendationTag(
            population: HealthPopulation.general,
            recommendation: generalPopulation['recommendation']?.toString() ?? 'No specific recommendations at this time.',
            level: _parseHealthAdviceLevel(generalPopulation['level']),
          ));
        } catch (e) {
          debugPrint('Error parsing general population recommendation: $e');
        }
      }

      // Parse elderly recommendations
      final elderly = healthData['elderly'];
      if (elderly != null && elderly is Map<String, dynamic>) {
        try {
          recommendations.add(HealthRecommendationTag(
            population: HealthPopulation.elderly,
            recommendation: elderly['recommendation']?.toString() ?? 'No specific recommendations at this time.',
            level: _parseHealthAdviceLevel(elderly['level']),
          ));
        } catch (e) {
          debugPrint('Error parsing elderly recommendation: $e');
        }
      }

      // Parse lung disease at-risk group
      final lungDiseaseAtRisk = healthData['lungDiseaseAtRisk'];
      if (lungDiseaseAtRisk != null && lungDiseaseAtRisk is Map<String, dynamic>) {
        try {
          recommendations.add(HealthRecommendationTag(
            population: HealthPopulation.lungDisease,
            recommendation: lungDiseaseAtRisk['recommendation']?.toString() ?? 'No specific recommendations at this time.',
            level: _parseHealthAdviceLevel(lungDiseaseAtRisk['level']),
          ));
        } catch (e) {
          print('Error parsing lung disease recommendation: $e');
        }
      }

      // Parse heart disease at-risk group
      final heartDiseaseAtRisk = healthData['heartDiseaseAtRisk'];
      if (heartDiseaseAtRisk != null && heartDiseaseAtRisk is Map<String, dynamic>) {
        try {
          recommendations.add(HealthRecommendationTag(
            population: HealthPopulation.heartDisease,
            recommendation: heartDiseaseAtRisk['recommendation']?.toString() ?? 'No specific recommendations at this time.',
            level: _parseHealthAdviceLevel(heartDiseaseAtRisk['level']),
          ));
        } catch (e) {
          print('Error parsing heart disease recommendation: $e');
        }
      }

      // Parse athletes recommendations
      final athletes = healthData['athletes'];
      if (athletes != null && athletes is Map<String, dynamic>) {
        try {
          recommendations.add(HealthRecommendationTag(
            population: HealthPopulation.athletes,
            recommendation: athletes['recommendation']?.toString() ?? 'No specific recommendations at this time.',
            level: _parseHealthAdviceLevel(athletes['level']),
          ));
        } catch (e) {
          print('Error parsing athletes recommendation: $e');
        }
      }

      // Parse pregnant women recommendations
      final pregnantWomen = healthData['pregnantWomen'];
      if (pregnantWomen != null && pregnantWomen is Map<String, dynamic>) {
        try {
          recommendations.add(HealthRecommendationTag(
            population: HealthPopulation.pregnantWomen,
            recommendation: pregnantWomen['recommendation']?.toString() ?? 'No specific recommendations at this time.',
            level: _parseHealthAdviceLevel(pregnantWomen['level']),
          ));
        } catch (e) {
          print('Error parsing pregnant women recommendation: $e');
        }
      }

      // Parse children recommendations
      final children = healthData['children'];
      if (children != null && children is Map<String, dynamic>) {
        try {
          recommendations.add(HealthRecommendationTag(
            population: HealthPopulation.children,
            recommendation: children['recommendation']?.toString() ?? 'No specific recommendations at this time.',
            level: _parseHealthAdviceLevel(children['level']),
          ));
        } catch (e) {
          print('Error parsing children recommendation: $e');
        }
      }

    } catch (e) {
      debugPrint('Error parsing health recommendations: $e');
    }

    return recommendations;
  }

  /// Parse health advice level from API response
  static HealthAdviceLevel _parseHealthAdviceLevel(dynamic level) {
    if (level == null) return HealthAdviceLevel.safe;

    String levelStr;
    if (level is String) {
      levelStr = level;
    } else if (level is int) {
      // Handle case where level might be an integer
      switch (level) {
        case 0:
          levelStr = 'safe';
          break;
        case 1:
          levelStr = 'caution';
          break;
        case 2:
          levelStr = 'avoid';
          break;
        default:
          levelStr = 'safe';
          break;
      }
    } else {
      levelStr = level.toString();
    }

    switch (levelStr.toLowerCase()) {
      case 'safe':
        return HealthAdviceLevel.safe;
      case 'caution':
        return HealthAdviceLevel.caution;
      case 'avoid':
        return HealthAdviceLevel.avoid;
      default:
        return HealthAdviceLevel.safe;
    }
  }

  /// Get historical air quality data for a specific location for the last 7 days
  static Future<List<AirQualityData>?> getHistoricalAirQuality(
    double latitude,
    double longitude, {
    String? locationName,
    int hours = 168, // 7 days = 168 hours
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/history:lookup');

      // Calculate start and end times using period approach
      final endTime = DateTime.now().subtract(const Duration(hours: 1)); // One hour ago to ensure data availability
      final startTime = endTime.subtract(Duration(hours: hours));

      final requestBody = {
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'period': {
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
        },
        'extraComputations': [
          'HEALTH_RECOMMENDATIONS',
          'DOMINANT_POLLUTANT_CONCENTRATION',
          'POLLUTANT_CONCENTRATION',
          'LOCAL_AQI',
          'POLLUTANT_ADDITIONAL_INFO'
        ],
        'pageSize': 168, // Maximum page size for 7 days
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
        return _parseHistoricalAirQualityResponse(data, latitude, longitude, locationName);
      } else {
        debugPrint('Error fetching historical air quality data: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception fetching historical air quality data: $e');
      return null;
    }
  }

  /// Parse the historical API response into a list of AirQualityData models
  static List<AirQualityData>? _parseHistoricalAirQualityResponse(
    Map<String, dynamic> data,
    double latitude,
    double longitude,
    String? locationName,
  ) {
    try {
      final hoursInfo = data['hoursInfo'] as List<dynamic>?;

      if (hoursInfo == null || hoursInfo.isEmpty) {
        return null;
      }

      final List<AirQualityData> historicalData = [];

      for (final hourData in hoursInfo) {
        final hourlyData = _parseHistoricalHourData(hourData, latitude, longitude, locationName);
        if (hourlyData != null) {
          historicalData.add(hourlyData);
        }
      }

      return historicalData.isNotEmpty ? historicalData : null;
    } catch (e) {
      print('Error parsing historical air quality response: $e');
      return null;
    }
  }

  /// Parse individual hour data from historical response
  static AirQualityData? _parseHistoricalHourData(
    Map<String, dynamic> hourData,
    double latitude,
    double longitude,
    String? locationName,
  ) {
    try {
      final dateTime = DateTime.parse(hourData['dateTime'] as String);
      final indexes = hourData['indexes'] as List<dynamic>?;
      final pollutants = hourData['pollutants'] as List<dynamic>?;

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
      double? co, so2, nox, no, nh3, c6h6, ox, nmhc, trs;

      if (pollutants != null) {
        for (final pollutant in pollutants) {
          final code = pollutant['code'] as String?;
          final concentration = (pollutant['concentration']?['value'] as num?)?.toDouble();

          if (concentration != null) {
            switch (code) {
              case 'p25':  // Correct API code for PM2.5
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
              case 'co':
                co = concentration;
                break;
              case 'so2':
                so2 = concentration;
                break;
              case 'nox':
                nox = concentration;
                break;
              case 'no':
                no = concentration;
                break;
              case 'nh3':
                nh3 = concentration;
                break;
              case 'c6h6':
                c6h6 = concentration;
                break;
              case 'ox':
                ox = concentration;
                break;
              case 'nmhc':
                nmhc = concentration;
                break;
              case 'trs':
                trs = concentration;
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
        co: co,
        so2: so2,
        nox: nox,
        no: no,
        nh3: nh3,
        c6h6: c6h6,
        ox: ox,
        nmhc: nmhc,
        trs: trs,
        wildfireIndex: 0.0, // Not available in API
        radon: 0.0, // Not available in API
        universalAqi: aqiValue.toInt(),
      );

      final status = _getStatusFromAqi(aqiValue);
      final statusReason = universalAqi['displayName'] ?? 'Air quality assessment based on historical conditions';

      // Parse health recommendations if available
      List<HealthRecommendationTag>? healthRecommendations;
      final healthData = hourData['healthRecommendations'];
      if (healthData != null) {
        healthRecommendations = _parseHealthRecommendations(healthData);
      }

      return AirQualityData(
        id: 'historical_${latitude}_${longitude}_${dateTime.millisecondsSinceEpoch}',
        locationName: locationName ?? 'Location',
        latitude: latitude,
        longitude: longitude,
        timestamp: dateTime,
        metrics: metrics,
        status: status,
        statusReason: statusReason,
        healthRecommendations: healthRecommendations,
      );
    } catch (e) {
      print('Error parsing historical hour data: $e');
      return null;
    }
  }

  /// Get the heatmap tile URL for air quality visualization
  static String getHeatmapTileUrl(int zoom, int x, int y) {
    return 'https://airquality.googleapis.com/v1/mapTypes/UAQI_RED_GREEN/heatmapTiles/$zoom/$x/$y?key=${ApiKeys.googleMapsApiKey}';
  }
}