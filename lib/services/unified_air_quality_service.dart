import '../models/air_quality.dart';
import '../models/pinned_location.dart';
import '../models/user_health_profile.dart';
import 'database_service.dart';

class UnifiedAirQualityService {
  static Future<Map<String, AirQualityData>> loadAirQualityForLocations(
    List<PinnedLocation> locations, {
    UserHealthProfile? userProfile,
  }) async {
    final Map<String, AirQualityData> locationAirQuality = {};

    for (final location in locations) {
      // Try to find existing air quality data for this specific location
      final existingData = await DatabaseService().getAirQualityData();
      final locationSpecificData = existingData.where((data) =>
        data.locationName.toLowerCase().contains(location.name.toLowerCase()) ||
        (data.latitude - location.latitude).abs() < 0.01 &&
        (data.longitude - location.longitude).abs() < 0.01
      ).toList();

      if (locationSpecificData.isNotEmpty) {
        // Update existing data with health recommendations if user profile is available
        final airQualityData = locationSpecificData.first;
        locationAirQuality[location.id] = userProfile != null
          ? airQualityData.copyWith(
              healthRecommendations: generateHealthRecommendations(airQualityData, userProfile),
            )
          : airQualityData;
      } else {
        // Generate new air quality data with health recommendations
        final airQualityData = generateSampleAirQualityData(location);
        locationAirQuality[location.id] = userProfile != null
          ? airQualityData.copyWith(
              healthRecommendations: generateHealthRecommendations(airQualityData, userProfile),
            )
          : airQualityData;
        // Save to database for future use
        await DatabaseService().saveAirQualityData(locationAirQuality[location.id]!);
      }
    }

    return locationAirQuality;
  }

  static AirQualityData generateCurrentLocationAirQualityData({
    UserHealthProfile? userProfile,
  }) {
    // Generate realistic current location air quality data
    final random = DateTime.now().millisecond;
    final baseVariation = (random % 100) / 100.0;

    // Base values for current location (Houston-like values)
    final baseValues = {'pm25': 12.0, 'pm10': 25.0, 'o3': 42.0, 'no2': 24.0};

    final pm25 = (baseValues['pm25']! * (1 + (baseVariation - 0.5) * 0.4)).clamp(5.0, 35.0);
    final pm10 = (baseValues['pm10']! * (1 + (baseVariation - 0.5) * 0.4)).clamp(10.0, 60.0);
    final o3 = (baseValues['o3']! * (1 + (baseVariation - 0.5) * 0.3)).clamp(20.0, 80.0);
    final no2 = (baseValues['no2']! * (1 + (baseVariation - 0.5) * 0.4)).clamp(10.0, 50.0);

    // Optional pollutants
    final co = random % 3 == 0 ? (200 + (baseVariation * 300)).clamp(100.0, 800.0) : null;
    final so2 = random % 4 == 0 ? (5 + (baseVariation * 15)).clamp(2.0, 25.0) : null;

    final metrics = AirQualityMetrics(
      pm25: pm25,
      pm10: pm10,
      o3: o3,
      no2: no2,
      co: co,
      so2: so2,
      wildfireIndex: (baseVariation * 30).clamp(0.0, 40.0),
      radon: (1.5 + baseVariation * 2).clamp(1.0, 4.0),
      universalAqi: null,
    );

    final status = AirQualityStatusExtension.fromScore(metrics.overallScore);

    final airQualityData = AirQualityData(
      id: 'current_location_${DateTime.now().millisecondsSinceEpoch}',
      locationName: 'Current Location',
      latitude: 29.7604, // Houston coordinates as default
      longitude: -95.3698,
      timestamp: DateTime.now().subtract(Duration(minutes: random % 30)),
      metrics: metrics,
      status: status,
      statusReason: generateStatusReason(metrics, status),
    );

    return userProfile != null
      ? airQualityData.copyWith(
          healthRecommendations: generateHealthRecommendations(airQualityData, userProfile),
        )
      : airQualityData;
  }

  static AirQualityData generateSampleAirQualityData(PinnedLocation location) {
    // Generate realistic but varied air quality data based on location type and coordinates
    final random = DateTime.now().millisecond + location.hashCode;
    final baseVariation = (random % 100) / 100.0; // 0.0 to 1.0

    // Different base values based on location type
    Map<String, double> baseValues;
    switch (location.type) {
      case LocationType.home:
        baseValues = {'pm25': 8.0, 'pm10': 18.0, 'o3': 35.0, 'no2': 18.0};
        break;
      case LocationType.work:
        baseValues = {'pm25': 15.0, 'pm10': 30.0, 'o3': 50.0, 'no2': 30.0};
        break;
      case LocationType.gym:
        baseValues = {'pm25': 12.0, 'pm10': 25.0, 'o3': 45.0, 'no2': 25.0};
        break;
      case LocationType.school:
        baseValues = {'pm25': 10.0, 'pm10': 22.0, 'o3': 40.0, 'no2': 22.0};
        break;
      case LocationType.other:
      default:
        baseValues = {'pm25': 13.0, 'pm10': 27.0, 'o3': 47.0, 'no2': 27.0};
        break;
    }

    // Add variation based on location coordinates (simulate geographic differences)
    final latVariation = (location.latitude % 1) * 0.3; // 0.0 to 0.3
    final lngVariation = (location.longitude.abs() % 1) * 0.2; // 0.0 to 0.2

    final pm25 = (baseValues['pm25']! * (1 + (baseVariation - 0.5) * 0.4 + latVariation)).clamp(5.0, 35.0);
    final pm10 = (baseValues['pm10']! * (1 + (baseVariation - 0.5) * 0.4 + lngVariation)).clamp(10.0, 60.0);
    final o3 = (baseValues['o3']! * (1 + (baseVariation - 0.5) * 0.3 + latVariation)).clamp(20.0, 80.0);
    final no2 = (baseValues['no2']! * (1 + (baseVariation - 0.5) * 0.4 + lngVariation)).clamp(10.0, 50.0);

    // Optional pollutants with some variation
    final co = random % 3 == 0 ? (200 + (baseVariation * 300)).clamp(100.0, 800.0) : null;
    final so2 = random % 4 == 0 ? (5 + (baseVariation * 15)).clamp(2.0, 25.0) : null;

    final metrics = AirQualityMetrics(
      pm25: pm25,
      pm10: pm10,
      o3: o3,
      no2: no2,
      co: co,
      so2: so2,
      wildfireIndex: (baseVariation * 30).clamp(0.0, 40.0),
      radon: (1.5 + baseVariation * 2).clamp(1.0, 4.0),
      universalAqi: null, // Will be calculated
    );

    final status = AirQualityStatusExtension.fromScore(metrics.overallScore);

    return AirQualityData(
      id: '${location.id}_${DateTime.now().millisecondsSinceEpoch}',
      locationName: location.name,
      latitude: location.latitude,
      longitude: location.longitude,
      timestamp: DateTime.now().subtract(Duration(minutes: random % 120)),
      metrics: metrics,
      status: status,
      statusReason: generateStatusReason(metrics, status),
    );
  }

  static String generateStatusReason(AirQualityMetrics metrics, AirQualityStatus status) {
    final concerns = <String>[];

    if (metrics.pm25 > 15) concerns.add('elevated PM2.5');
    if (metrics.pm10 > 30) concerns.add('elevated PM10');
    if (metrics.o3 > 50) concerns.add('high ozone');
    if (metrics.no2 > 30) concerns.add('elevated NO₂');
    if (metrics.co != null && metrics.co! > 500) concerns.add('carbon monoxide');
    if (metrics.so2 != null && metrics.so2! > 15) concerns.add('sulfur dioxide');

    switch (status) {
      case AirQualityStatus.good:
        return concerns.isEmpty
          ? 'All air quality metrics are within healthy ranges'
          : 'Generally good air quality with minor ${concerns.first} levels';
      case AirQualityStatus.caution:
        return concerns.isEmpty
          ? 'Moderate air quality - sensitive individuals should be cautious'
          : 'Moderate air quality due to ${concerns.take(2).join(' and ')}';
      case AirQualityStatus.avoid:
        return concerns.isEmpty
          ? 'Poor air quality - limit outdoor exposure'
          : 'Poor air quality due to ${concerns.take(2).join(' and ')} - avoid prolonged outdoor activities';
    }
  }

  static List<HealthRecommendationTag> generateHealthRecommendations(
    AirQualityData airQuality,
    UserHealthProfile userProfile,
  ) {
    final tags = <HealthRecommendationTag>[];

    // Generate tags based on user profile
    if (userProfile.conditions.contains(HealthCondition.asthma)) {
      tags.add(HealthRecommendationTag(
        population: HealthPopulation.lungDisease,
        recommendation: airQuality.status == AirQualityStatus.good
          ? 'Safe for outdoor activities'
          : 'Consider staying indoors',
        level: airQuality.status == AirQualityStatus.good
          ? HealthAdviceLevel.safe
          : HealthAdviceLevel.caution,
      ));
    }

    if (userProfile.ageGroup == AgeGroup.child) {
      tags.add(HealthRecommendationTag(
        population: HealthPopulation.children,
        recommendation: airQuality.status == AirQualityStatus.good
          ? 'Good for outdoor play'
          : 'Limit outdoor activities',
        level: airQuality.status == AirQualityStatus.good
          ? HealthAdviceLevel.safe
          : HealthAdviceLevel.caution,
      ));
    }

    if (userProfile.lifestyleRisks.contains(LifestyleRisk.athlete)) {
      tags.add(HealthRecommendationTag(
        population: HealthPopulation.athletes,
        recommendation: airQuality.status == AirQualityStatus.good
          ? 'Safe for training'
          : 'Consider indoor workouts',
        level: airQuality.status == AirQualityStatus.good
          ? HealthAdviceLevel.safe
          : HealthAdviceLevel.caution,
      ));
    }

    if (userProfile.conditions.contains(HealthCondition.heartDisease)) {
      tags.add(HealthRecommendationTag(
        population: HealthPopulation.heartDisease,
        recommendation: airQuality.status == AirQualityStatus.avoid
          ? 'Avoid strenuous activities'
          : 'Monitor activity levels',
        level: airQuality.status == AirQualityStatus.avoid
          ? HealthAdviceLevel.avoid
          : HealthAdviceLevel.caution,
      ));
    }

    if (userProfile.isPregnant) {
      tags.add(HealthRecommendationTag(
        population: HealthPopulation.pregnantWomen,
        recommendation: airQuality.status != AirQualityStatus.good
          ? 'Take extra precautions'
          : 'Safe for outdoor activities',
        level: airQuality.status != AirQualityStatus.good
          ? HealthAdviceLevel.caution
          : HealthAdviceLevel.safe,
      ));
    }

    if (userProfile.ageGroup == AgeGroup.olderAdult) {
      tags.add(HealthRecommendationTag(
        population: HealthPopulation.elderly,
        recommendation: airQuality.status != AirQualityStatus.good
          ? 'Be extra cautious'
          : 'Safe for outdoor activities',
        level: airQuality.status != AirQualityStatus.good
          ? HealthAdviceLevel.caution
          : HealthAdviceLevel.safe,
      ));
    }

    // Always add general population recommendation
    tags.add(HealthRecommendationTag(
      population: HealthPopulation.general,
      recommendation: airQuality.status == AirQualityStatus.good
        ? 'Good air quality for everyone'
        : 'Sensitive individuals should limit outdoor exposure',
      level: airQuality.status == AirQualityStatus.good
        ? HealthAdviceLevel.safe
        : HealthAdviceLevel.caution,
    ));

    return tags;
  }
}