import 'package:flutter/foundation.dart';
import '../models/pinned_location.dart';
import '../models/air_quality.dart';
import '../models/user_health_profile.dart';
import 'database_service.dart';
import 'air_quality_api_service.dart';

class UnifiedAirQualityService {
  static Map<String, AirQualityData> locationAirQuality = {};

  static Future<Map<String, AirQualityData>> getAirQualityForAllLocations(
    List<PinnedLocation> locations, {
    UserHealthProfile? userProfile,
  }) async {
    final Map<String, AirQualityData> results = {};

    for (final location in locations) {
      try {
        // Fetch fresh air quality data from Google API
        final airQualityData = await AirQualityApiService.getAirQuality(
          location.latitude,
          location.longitude,
          locationName: location.name,
        );

        if (airQualityData != null) {
          // Add personalized health recommendations if user profile exists
          final enhancedData = userProfile != null
              ? airQualityData.copyWith(
                  healthRecommendations: mergeHealthRecommendations(
                    airQualityData.healthRecommendations,
                    generateHealthRecommendations(airQualityData, userProfile),
                  ),
                )
              : airQualityData;

          results[location.id] = enhancedData;
          locationAirQuality[location.id] = enhancedData;
        }
        // If airQualityData is null, don't add to results - let UI show "No data available"
      } catch (e) {
        debugPrint('Error fetching air quality for ${location.name}: $e');
        // Continue to next location without adding fake data
      }
    }

    return results;
  }

  static List<HealthRecommendationTag> mergeHealthRecommendations(
    List<HealthRecommendationTag>? googleRecommendations,
    List<HealthRecommendationTag> personalizedRecommendations,
  ) {
    final merged = <HealthRecommendationTag>[];

    // Add Google API recommendations first (these are research-backed)
    if (googleRecommendations != null) {
      merged.addAll(googleRecommendations);
    }

    // Add personalized recommendations that don't conflict
    for (final personalizedRec in personalizedRecommendations) {
      // Check if we already have a recommendation for this population
      final hasExisting = merged.any((existing) =>
        existing.population == personalizedRec.population);

      if (!hasExisting) {
        merged.add(personalizedRec);
      }
    }

    return merged;
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
    AirQualityData data,
    UserHealthProfile profile,
  ) {
    final recommendations = <HealthRecommendationTag>[];

    // Helper function to determine advice level from air quality status
    HealthAdviceLevel getAdviceLevel(AirQualityStatus status) {
      switch (status) {
        case AirQualityStatus.good:
          return HealthAdviceLevel.safe;
        case AirQualityStatus.caution:
          return HealthAdviceLevel.caution;
        case AirQualityStatus.avoid:
          return HealthAdviceLevel.avoid;
      }
    }

    final adviceLevel = getAdviceLevel(data.status);

    // Base recommendations for all users
    if (data.status == AirQualityStatus.avoid) {
      recommendations.add(HealthRecommendationTag(
        population: HealthPopulation.general,
        recommendation: 'Consider staying indoors when possible',
        level: adviceLevel,
      ));
      recommendations.add(HealthRecommendationTag(
        population: HealthPopulation.general,
        recommendation: 'Keep windows closed and use air purifiers if available',
        level: adviceLevel,
      ));
    } else if (data.status == AirQualityStatus.caution) {
      recommendations.add(HealthRecommendationTag(
        population: HealthPopulation.general,
        recommendation: 'Consider limiting outdoor activities if sensitive to air pollution',
        level: adviceLevel,
      ));
      recommendations.add(HealthRecommendationTag(
        population: HealthPopulation.general,
        recommendation: 'Monitor air quality before going outside',
        level: adviceLevel,
      ));
    }

    // Health condition-specific recommendations
    final hasRespiratoryCondition = profile.conditions.contains(HealthCondition.asthma) ||
        profile.conditions.contains(HealthCondition.copd) ||
        profile.conditions.contains(HealthCondition.lungDisease);

    if (hasRespiratoryCondition) {
      if (data.status == AirQualityStatus.avoid) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.lungDisease,
          recommendation: 'Keep rescue medications nearby',
          level: adviceLevel,
        ));
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.lungDisease,
          recommendation: 'Consider wearing a mask if you must go outside',
          level: adviceLevel,
        ));
      } else if (data.status == AirQualityStatus.caution) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.lungDisease,
          recommendation: 'Have your inhaler or medications ready',
          level: adviceLevel,
        ));
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.lungDisease,
          recommendation: 'Consider indoor exercise alternatives',
          level: adviceLevel,
        ));
      }
    }

    final hasHeartCondition = profile.conditions.contains(HealthCondition.heartDisease);
    if (hasHeartCondition) {
      if (data.status == AirQualityStatus.avoid) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.heartDisease,
          recommendation: 'Avoid strenuous outdoor activities',
          level: adviceLevel,
        ));
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.heartDisease,
          recommendation: 'Monitor for chest pain or shortness of breath',
          level: adviceLevel,
        ));
      } else if (data.status == AirQualityStatus.caution) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.heartDisease,
          recommendation: 'Choose lower intensity outdoor activities',
          level: adviceLevel,
        ));
      }
    }

    // Age-based recommendations
    if (profile.ageGroup == AgeGroup.child) {
      if (data.status == AirQualityStatus.avoid) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.children,
          recommendation: 'Stay indoors and avoid outdoor exposure',
          level: adviceLevel,
        ));
      } else if (data.status == AirQualityStatus.caution) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.children,
          recommendation: 'Limit time outdoors and choose less polluted times of day',
          level: adviceLevel,
        ));
      }
    }

    if (profile.ageGroup == AgeGroup.olderAdult) {
      if (data.status == AirQualityStatus.avoid) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.elderly,
          recommendation: 'Stay indoors and avoid outdoor exposure',
          level: adviceLevel,
        ));
      } else if (data.status == AirQualityStatus.caution) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.elderly,
          recommendation: 'Limit time outdoors and choose less polluted times of day',
          level: adviceLevel,
        ));
      }
    }

    if (profile.isPregnant) {
      if (data.status == AirQualityStatus.avoid) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.pregnantWomen,
          recommendation: 'Stay indoors and avoid outdoor exposure',
          level: adviceLevel,
        ));
      } else if (data.status == AirQualityStatus.caution) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.pregnantWomen,
          recommendation: 'Limit time outdoors and choose less polluted times of day',
          level: adviceLevel,
        ));
      }
    }

    // Lifestyle-based recommendations
    final exercisesOutdoors = profile.lifestyleRisks.contains(LifestyleRisk.athlete) ||
        profile.lifestyleRisks.contains(LifestyleRisk.outdoorWorker);

    if (exercisesOutdoors) {
      if (data.status == AirQualityStatus.avoid) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.athletes,
          recommendation: 'Switch to indoor exercise today',
          level: adviceLevel,
        ));
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.athletes,
          recommendation: 'Consider gym or home workout alternatives',
          level: adviceLevel,
        ));
      } else if (data.status == AirQualityStatus.caution) {
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.athletes,
          recommendation: 'Consider exercising during early morning or evening hours',
          level: adviceLevel,
        ));
        recommendations.add(HealthRecommendationTag(
          population: HealthPopulation.athletes,
          recommendation: 'Choose less intense outdoor activities',
          level: adviceLevel,
        ));
      }
    }

    // Default recommendations if none added
    if (recommendations.isEmpty && data.status == AirQualityStatus.good) {
      recommendations.add(HealthRecommendationTag(
        population: HealthPopulation.general,
        recommendation: 'Good air quality - enjoy outdoor activities',
        level: adviceLevel,
      ));
      recommendations.add(HealthRecommendationTag(
        population: HealthPopulation.general,
        recommendation: 'Great time for exercise and outdoor recreation',
        level: adviceLevel,
      ));
    }

    return recommendations;
  }

  static Future<void> clearLocationData() async {
    locationAirQuality.clear();
  }

  static AirQualityData? getLocationData(String locationId) {
    return locationAirQuality[locationId];
  }

  static void updateLocationData(String locationId, AirQualityData data) {
    locationAirQuality[locationId] = data;
  }

  static Future<void> syncWithDatabase() async {
    // Save current air quality data to database for offline access
    for (final data in locationAirQuality.values) {
      await DatabaseService().saveAirQualityData(data);
    }
  }

  static Map<String, AirQualityData> getAllLocationData() {
    return Map.from(locationAirQuality);
  }
}