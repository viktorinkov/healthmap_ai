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

      // Parse additional pollutants if available
      double? co, so2, nox, no, nh3, c6h6, ox, nmhc, trs;

      if (pollutants != null) {
        for (final pollutant in pollutants) {
          final code = pollutant['code'] as String?;
          final concentration = pollutant['concentration']?['value'] as double?;

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
      final statusReason = universalAqi['displayName'] ?? 'Air quality assessment based on current conditions';

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

  /// Parse health recommendations from Google API response
  static List<HealthRecommendationTag> _parseHealthRecommendations(Map<String, dynamic> healthData) {
    final recommendations = <HealthRecommendationTag>[];

    try {
      // Parse general population recommendations
      final generalPopulation = healthData['generalPopulation'];
      if (generalPopulation != null) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.general,
          recommendation: generalPopulation['recommendation'] ?? 'No specific recommendations at this time.',
          level: _parseHealthAdviceLevel(generalPopulation['level']),
        ));
      }

      // Parse elderly recommendations
      final elderly = healthData['elderly'];
      if (elderly != null) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.elderly,
          recommendation: elderly['recommendation'] ?? 'No specific recommendations at this time.',
          level: _parseHealthAdviceLevel(elderly['level']),
        ));
      }

      // Parse lung disease at-risk group
      final lungDiseaseAtRisk = healthData['lungDiseaseAtRisk'];
      if (lungDiseaseAtRisk != null) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.lungDisease,
          recommendation: lungDiseaseAtRisk['recommendation'] ?? 'No specific recommendations at this time.',
          level: _parseHealthAdviceLevel(lungDiseaseAtRisk['level']),
        ));
      }

      // Parse heart disease at-risk group
      final heartDiseaseAtRisk = healthData['heartDiseaseAtRisk'];
      if (heartDiseaseAtRisk != null) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.heartDisease,
          recommendation: heartDiseaseAtRisk['recommendation'] ?? 'No specific recommendations at this time.',
          level: _parseHealthAdviceLevel(heartDiseaseAtRisk['level']),
        ));
      }

      // Parse athletes recommendations
      final athletes = healthData['athletes'];
      if (athletes != null) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.athletes,
          recommendation: athletes['recommendation'] ?? 'No specific recommendations at this time.',
          level: _parseHealthAdviceLevel(athletes['level']),
        ));
      }

      // Parse pregnant women recommendations
      final pregnantWomen = healthData['pregnantWomen'];
      if (pregnantWomen != null) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.pregnantWomen,
          recommendation: pregnantWomen['recommendation'] ?? 'No specific recommendations at this time.',
          level: _parseHealthAdviceLevel(pregnantWomen['level']),
        ));
      }

      // Parse children recommendations
      final children = healthData['children'];
      if (children != null) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.children,
          recommendation: children['recommendation'] ?? 'No specific recommendations at this time.',
          level: _parseHealthAdviceLevel(children['level']),
        ));
      }

    } catch (e) {
      print('Error parsing health recommendations: $e');
    }

    return recommendations;
  }

  /// Parse health advice level from API response
  static HealthAdviceLevel _parseHealthAdviceLevel(String? level) {
    switch (level?.toLowerCase()) {
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

  /// Get the heatmap tile URL for air quality visualization
  static String getHeatmapTileUrl(int zoom, int x, int y) {
    return 'https://airquality.googleapis.com/v1/mapTypes/UAQI_RED_GREEN/heatmapTiles/$zoom/$x/$y?key=${ApiKeys.googleMapsApiKey}';
  }
}