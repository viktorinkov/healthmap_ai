import 'dart:math';
import '../models/air_quality.dart';
import '../models/neighborhood.dart';

class FakeDataService {
  static final Random _random = Random();

  // Rice University area neighborhoods with detailed coordinates
  static const List<Map<String, dynamic>> _houstonNeighborhoods = [
    // Core Rice University area
    {'name': 'Rice Village', 'lat': 29.7174, 'lng': -95.4018, 'zips': ['77005']},
    {'name': 'West University', 'lat': 29.7180, 'lng': -95.4351, 'zips': ['77005']},
    {'name': 'Southampton', 'lat': 29.7089, 'lng': -95.4102, 'zips': ['77025']},
    {'name': 'Museum District', 'lat': 29.7215, 'lng': -95.3899, 'zips': ['77004']},
    {'name': 'Medical Center', 'lat': 29.7072, 'lng': -95.3978, 'zips': ['77030', '77054']},

    // Nearby affluent areas
    {'name': 'River Oaks', 'lat': 29.7516, 'lng': -95.4224, 'zips': ['77027', '77019']},
    {'name': 'Montrose', 'lat': 29.7422, 'lng': -95.3876, 'zips': ['77006', '77098']},
    {'name': 'Upper Kirby', 'lat': 29.7380, 'lng': -95.4105, 'zips': ['77098']},
    {'name': 'Greenway Plaza', 'lat': 29.7360, 'lng': -95.4480, 'zips': ['77046']},
    {'name': 'Bellaire', 'lat': 29.7058, 'lng': -95.4585, 'zips': ['77401']},

    // Surrounding areas
    {'name': 'Meyerland', 'lat': 29.6890, 'lng': -95.4640, 'zips': ['77096']},
    {'name': 'Braeswood', 'lat': 29.6950, 'lng': -95.4350, 'zips': ['77025']},
    {'name': 'Gulfton', 'lat': 29.7180, 'lng': -95.4520, 'zips': ['77036']},
    {'name': 'Sharpstown', 'lat': 29.7040, 'lng': -95.4890, 'zips': ['77036']},
    {'name': 'Westchase', 'lat': 29.7320, 'lng': -95.5150, 'zips': ['77042']},
  ];

  static List<Neighborhood> generateHoustonNeighborhoods() {
    List<Neighborhood> neighborhoods = [];

    for (int i = 0; i < _houstonNeighborhoods.length; i++) {
      final data = _houstonNeighborhoods[i];
      final airQuality = _generateAirQualityData(
        data['name'],
        data['lat'],
        data['lng'],
      );

      final healthScore = 100 - airQuality.metrics.overallScore;

      neighborhoods.add(Neighborhood(
        id: 'houston_${i + 1}',
        name: data['name'],
        latitude: data['lat'],
        longitude: data['lng'],
        zipCodes: List<String>.from(data['zips']),
        currentAirQuality: airQuality,
        healthScore: healthScore,
        ranking: i + 1, // Will be sorted later
      ));
    }

    // Sort by health score (higher is better)
    neighborhoods.sort((a, b) => b.healthScore.compareTo(a.healthScore));

    // Update rankings
    for (int i = 0; i < neighborhoods.length; i++) {
      neighborhoods[i] = Neighborhood(
        id: neighborhoods[i].id,
        name: neighborhoods[i].name,
        latitude: neighborhoods[i].latitude,
        longitude: neighborhoods[i].longitude,
        zipCodes: neighborhoods[i].zipCodes,
        currentAirQuality: neighborhoods[i].currentAirQuality,
        healthScore: neighborhoods[i].healthScore,
        ranking: i + 1,
      );
    }

    return neighborhoods;
  }

  static AirQualityData _generateAirQualityData(String locationName, double lat, double lng) {
    // Generate realistic air quality data with some variation
    final baseData = _getBaseAirQualityForLocation(locationName);

    final metrics = AirQualityMetrics(
      pm25: _addVariation(baseData['pm25']!, 0.2),
      pm10: _addVariation(baseData['pm10']!, 0.2),
      o3: _addVariation(baseData['o3']!, 0.3),
      no2: _addVariation(baseData['no2']!, 0.25),
      wildfireIndex: _addVariation(baseData['wildfire']!, 0.4),
      radon: _addVariation(baseData['radon']!, 0.3),
    );

    final status = AirQualityStatusExtension.fromScore(metrics.overallScore);
    final statusReason = _generateStatusReason(metrics, status);

    return AirQualityData(
      id: '${locationName.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      locationName: locationName,
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now().subtract(Duration(minutes: _random.nextInt(60))),
      metrics: metrics,
      status: status,
      statusReason: statusReason,
    );
  }

  static Map<String, double> _getBaseAirQualityForLocation(String locationName) {
    // Different areas have different typical air quality patterns
    switch (locationName.toLowerCase()) {
      case 'downtown':
      case 'galleria':
      case 'medical center':
        // Urban areas - higher pollution
        return {
          'pm25': 18.0,
          'pm10': 35.0,
          'o3': 55.0,
          'no2': 35.0,
          'wildfire': 15.0,
          'radon': 2.5,
        };

      case 'rice village':
      case 'west university':
      case 'southampton':
        // University area - excellent air quality
        return {
          'pm25': 8.0,
          'pm10': 18.0,
          'o3': 35.0,
          'no2': 18.0,
          'wildfire': 8.0,
          'radon': 1.5,
        };

      case 'river oaks':
      case 'montrose':
      case 'bellaire':
      case 'upper kirby':
        // Affluent residential areas - good air quality
        return {
          'pm25': 12.0,
          'pm10': 25.0,
          'o3': 45.0,
          'no2': 25.0,
          'wildfire': 10.0,
          'radon': 2.0,
        };

      case 'museum district':
      case 'greenway plaza':
        // Cultural/commercial areas - moderate traffic
        return {
          'pm25': 15.0,
          'pm10': 30.0,
          'o3': 50.0,
          'no2': 30.0,
          'wildfire': 12.0,
          'radon': 2.2,
        };

      case 'meyerland':
      case 'braeswood':
        // Residential areas - good air quality
        return {
          'pm25': 10.0,
          'pm10': 22.0,
          'o3': 40.0,
          'no2': 22.0,
          'wildfire': 9.0,
          'radon': 1.8,
        };

      case 'gulfton':
      case 'sharpstown':
      case 'westchase':
        // Mixed residential/commercial - moderate pollution
        return {
          'pm25': 16.0,
          'pm10': 32.0,
          'o3': 52.0,
          'no2': 32.0,
          'wildfire': 14.0,
          'radon': 2.4,
        };


      default:
        // Average suburban area
        return {
          'pm25': 10.0,
          'pm10': 22.0,
          'o3': 40.0,
          'no2': 20.0,
          'wildfire': 12.0,
          'radon': 2.0,
        };
    }
  }

  static double _addVariation(double baseValue, double variationPercent) {
    final variation = baseValue * variationPercent * (_random.nextDouble() * 2 - 1);
    return (baseValue + variation).clamp(0.0, baseValue * 3);
  }

  static String _generateStatusReason(AirQualityMetrics metrics, AirQualityStatus status) {
    List<String> concerns = [];

    if (metrics.pm25 > 15) concerns.add('elevated PM2.5 particles');
    if (metrics.pm10 > 30) concerns.add('elevated PM10 particles');
    if (metrics.o3 > 50) concerns.add('elevated ozone levels');
    if (metrics.no2 > 30) concerns.add('elevated nitrogen dioxide');
    if (metrics.wildfireIndex > 25) concerns.add('wildfire smoke detected');
    if (metrics.radon > 2.5) concerns.add('elevated radon levels');

    switch (status) {
      case AirQualityStatus.good:
        if (concerns.isEmpty) {
          return 'All air quality metrics are within healthy ranges';
        } else {
          return 'Generally healthy air quality with minor concerns about ${concerns.first}';
        }

      case AirQualityStatus.caution:
        if (concerns.length == 1) {
          return 'Moderate air quality due to ${concerns.first}, sensitive individuals should limit outdoor activities';
        } else {
          return 'Moderate air quality due to ${concerns.take(2).join(' and ')}, exercise caution outdoors';
        }

      case AirQualityStatus.avoid:
        if (concerns.length == 1) {
          return 'Poor air quality due to ${concerns.first}, avoid prolonged outdoor exposure';
        } else {
          return 'Poor air quality due to multiple pollutants including ${concerns.take(2).join(' and ')}, stay indoors';
        }
    }
  }

  static List<AirQualityData> generateRecentAirQualityHistory(String locationName, double lat, double lng, int days) {
    List<AirQualityData> history = [];

    for (int i = 0; i < days; i++) {
      final timestamp = DateTime.now().subtract(Duration(days: i));
      final data = _generateAirQualityData(locationName, lat, lng);

      history.add(AirQualityData(
        id: '${locationName.toLowerCase().replaceAll(' ', '_')}_${timestamp.millisecondsSinceEpoch}',
        locationName: locationName,
        latitude: lat,
        longitude: lng,
        timestamp: timestamp,
        metrics: data.metrics,
        status: data.status,
        statusReason: data.statusReason,
      ));
    }

    return history;
  }
}