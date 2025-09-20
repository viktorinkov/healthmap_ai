import 'dart:math';
import '../models/air_quality.dart';
import '../models/neighborhood.dart';

class FakeDataService {
  static final Random _random = Random();

  // Houston neighborhoods with approximate coordinates
  static const List<Map<String, dynamic>> _houstonNeighborhoods = [
    {'name': 'Downtown', 'lat': 29.7604, 'lng': -95.3698, 'zips': ['77002', '77003', '77004']},
    {'name': 'River Oaks', 'lat': 29.7516, 'lng': -95.4224, 'zips': ['77027', '77019']},
    {'name': 'Memorial', 'lat': 29.7841, 'lng': -95.4618, 'zips': ['77024', '77079']},
    {'name': 'The Heights', 'lat': 29.8027, 'lng': -95.3987, 'zips': ['77008', '77009']},
    {'name': 'Montrose', 'lat': 29.7422, 'lng': -95.3876, 'zips': ['77006', '77098']},
    {'name': 'Galleria', 'lat': 29.7390, 'lng': -95.4637, 'zips': ['77056', '77057']},
    {'name': 'Medical Center', 'lat': 29.7072, 'lng': -95.3978, 'zips': ['77030', '77054']},
    {'name': 'Bellaire', 'lat': 29.7058, 'lng': -95.4612, 'zips': ['77401', '77025']},
    {'name': 'Sugar Land', 'lat': 29.6196, 'lng': -95.6349, 'zips': ['77478', '77479']},
    {'name': 'Katy', 'lat': 29.7858, 'lng': -95.8244, 'zips': ['77449', '77494']},
    {'name': 'The Woodlands', 'lat': 30.1588, 'lng': -95.4613, 'zips': ['77380', '77381']},
    {'name': 'Clear Lake', 'lat': 29.5722, 'lng': -95.1379, 'zips': ['77058', '77062']},
    {'name': 'Pasadena', 'lat': 29.6911, 'lng': -95.2091, 'zips': ['77502', '77504']},
    {'name': 'Humble', 'lat': 29.9988, 'lng': -95.2621, 'zips': ['77338', '77339']},
    {'name': 'Spring', 'lat': 30.0799, 'lng': -95.4172, 'zips': ['77373', '77379']},
    {'name': 'Cypress', 'lat': 29.9691, 'lng': -95.6972, 'zips': ['77429', '77433']},
    {'name': 'Pearland', 'lat': 29.5638, 'lng': -95.2861, 'zips': ['77581', '77584']},
    {'name': 'League City', 'lat': 29.5074, 'lng': -95.0949, 'zips': ['77573', '77574']},
    {'name': 'Friendswood', 'lat': 29.5294, 'lng': -95.2010, 'zips': ['77546']},
    {'name': 'Missouri City', 'lat': 29.6185, 'lng': -95.5377, 'zips': ['77459', '77489']},
    {'name': 'Stafford', 'lat': 29.6160, 'lng': -95.5521, 'zips': ['77477']},
    {'name': 'Conroe', 'lat': 30.3118, 'lng': -95.4561, 'zips': ['77301', '77304']},
    {'name': 'Tomball', 'lat': 30.0971, 'lng': -95.6160, 'zips': ['77375', '77377']},
    {'name': 'Kingwood', 'lat': 30.0533, 'lng': -95.1888, 'zips': ['77339', '77345']},
    {'name': 'Channelview', 'lat': 29.7769, 'lng': -95.1121, 'zips': ['77530']},
    {'name': 'Deer Park', 'lat': 29.7052, 'lng': -95.1238, 'zips': ['77536']},
    {'name': 'La Porte', 'lat': 29.6658, 'lng': -95.0194, 'zips': ['77571']},
    {'name': 'Baytown', 'lat': 29.7355, 'lng': -94.9774, 'zips': ['77520', '77521']},
    {'name': 'Atascocita', 'lat': 29.9991, 'lng': -95.1777, 'zips': ['77346']},
    {'name': 'West University Place', 'lat': 29.7180, 'lng': -95.4399, 'zips': ['77005']},
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

      case 'river oaks':
      case 'memorial':
      case 'bellaire':
      case 'west university place':
        // Affluent residential areas - moderate pollution
        return {
          'pm25': 12.0,
          'pm10': 25.0,
          'o3': 45.0,
          'no2': 25.0,
          'wildfire': 10.0,
          'radon': 2.0,
        };

      case 'the woodlands':
      case 'sugar land':
      case 'kingwood':
      case 'friendswood':
        // Suburban areas - lower pollution
        return {
          'pm25': 8.0,
          'pm10': 18.0,
          'o3': 35.0,
          'no2': 18.0,
          'wildfire': 8.0,
          'radon': 1.5,
        };

      case 'pasadena':
      case 'baytown':
      case 'deer park':
      case 'channelview':
        // Industrial areas - higher pollution
        return {
          'pm25': 22.0,
          'pm10': 42.0,
          'o3': 65.0,
          'no2': 45.0,
          'wildfire': 20.0,
          'radon': 3.0,
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