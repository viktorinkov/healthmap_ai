import 'dart:convert';
import '../models/user_health_profile.dart';
import '../models/air_quality.dart';
import '../models/environmental_measurements.dart';
import 'api_service.dart';
import 'health_insights_service.dart';

class UnifiedHealthService {
  // Get comprehensive health insights combining environmental and Fitbit data
  static Future<UnifiedHealthInsight> getUnifiedHealthInsight({
    required String userId,
    required double latitude,
    required double longitude,
    required UserHealthProfile userProfile,
  }) async {
    try {
      // Fetch data from both backends in parallel
      final results = await Future.wait([
        // Get air quality from Node.js backend
        ApiService.getCurrentAirQuality(latitude, longitude),
        
        // Get environmental measurements from Node.js backend
        ApiService.getEnvironmentalMeasurements(latitude, longitude),
        
        // Get health summary from Python backend
        HealthInsightsService.getHealthSummary(userId: userId, days: 7),
        
        // Get health patterns from Python backend
        HealthInsightsService.getHealthPatterns(userId: userId),
      ]);

      final airQuality = results[0] as AirQualityData;
      final environmentalMeasurements = results[1] as EnvironmentalMeasurements?;
      final healthSummary = results[2] as Map<String, dynamic>;
      final healthPatterns = results[3] as Map<String, dynamic>;

      // Get AI-powered insights combining both data sources
      final dailySummary = await HealthInsightsService.getDailyHealthSummary(
        userId: userId,
        airQualityData: _airQualityToJson(airQuality),
        userProfile: userProfile,
      );

      return UnifiedHealthInsight(
        airQuality: airQuality,
        environmentalMeasurements: environmentalMeasurements,
        healthSummary: healthSummary,
        healthPatterns: healthPatterns,
        dailyInsight: dailySummary['insight'] ?? 'No insights available',
        warnings: List<String>.from(dailySummary['warnings'] ?? []),
        confidenceScore: dailySummary['confidence_score'] ?? 0.0,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('Error getting unified health insight: $e');
      return UnifiedHealthInsight.error(e.toString());
    }
  }

  // Get activity-specific recommendations
  static Future<ActivityRecommendation> getActivityRecommendation({
    required String userId,
    required String activityType,
    required double latitude,
    required double longitude,
    required UserHealthProfile userProfile,
  }) async {
    try {
      // Get current air quality
      final airQuality = await ApiService.getCurrentAirQuality(latitude, longitude);
      
      // Get recommendation from Python backend
      final recommendation = await HealthInsightsService.getActivityRecommendation(
        userId: userId,
        activityType: activityType,
        airQualityData: _airQualityToJson(airQuality),
        userProfile: userProfile,
      );

      return ActivityRecommendation(
        activityType: activityType,
        recommendation: recommendation['insight'] ?? 'No recommendation available',
        isSafe: _determineActivitySafety(airQuality, userProfile),
        alternativeSuggestions: _getAlternatives(activityType, airQuality),
        airQualityStatus: airQuality.status,
        warnings: List<String>.from(recommendation['warnings'] ?? []),
      );
    } catch (e) {
      print('Error getting activity recommendation: $e');
      return ActivityRecommendation.error(activityType, e.toString());
    }
  }

  // Helper method to convert air quality to JSON
  static Map<String, dynamic> _airQualityToJson(AirQualityData airQuality) {
    return {
      'aqi': airQuality.aqi,
      'status': airQuality.status.name,
      'primary_pollutant': airQuality.primaryPollutant,
      'pm25': airQuality.metrics.pm25,
      'pm10': airQuality.metrics.pm10,
      'o3': airQuality.metrics.o3,
      'no2': airQuality.metrics.no2,
      'wildfire_index': airQuality.metrics.wildfireIndex,
    };
  }

  // Determine if activity is safe based on conditions
  static bool _determineActivitySafety(
    AirQualityData airQuality,
    UserHealthProfile profile,
  ) {
    // High sensitivity users should avoid outdoor activities in moderate conditions
    if (profile.sensitivityLevel >= 4 && airQuality.aqi > 50) {
      return false;
    }

    // Pregnant users should be extra cautious
    if (profile.isPregnant && airQuality.aqi > 75) {
      return false;
    }

    // General safety threshold
    return airQuality.aqi <= 100;
  }

  // Get alternative activity suggestions
  static List<String> _getAlternatives(
    String activityType,
    AirQualityData airQuality,
  ) {
    if (airQuality.aqi <= 50) {
      return []; // Air quality is good, no alternatives needed
    }

    final alternatives = <String>[];

    if (activityType.toLowerCase().contains('run') || 
        activityType.toLowerCase().contains('jog')) {
      alternatives.addAll([
        'Indoor treadmill running',
        'Indoor track at gym',
        'Home cardio workout',
        'Swimming at indoor pool',
      ]);
    } else if (activityType.toLowerCase().contains('walk')) {
      alternatives.addAll([
        'Mall walking',
        'Indoor track walking',
        'Treadmill walking',
        'Yoga or stretching',
      ]);
    } else if (activityType.toLowerCase().contains('bike') || 
               activityType.toLowerCase().contains('cycling')) {
      alternatives.addAll([
        'Indoor cycling/spin class',
        'Stationary bike',
        'Indoor rowing',
        'Elliptical machine',
      ]);
    }

    return alternatives;
  }
}

// Data models for unified insights
class UnifiedHealthInsight {
  final AirQualityData? airQuality;
  final EnvironmentalMeasurements? environmentalMeasurements;
  final Map<String, dynamic> healthSummary;
  final Map<String, dynamic> healthPatterns;
  final String dailyInsight;
  final List<String> warnings;
  final double confidenceScore;
  final DateTime timestamp;
  final bool hasError;
  final String? errorMessage;

  UnifiedHealthInsight({
    required this.airQuality,
    this.environmentalMeasurements,
    required this.healthSummary,
    required this.healthPatterns,
    required this.dailyInsight,
    required this.warnings,
    required this.confidenceScore,
    required this.timestamp,
    this.hasError = false,
    this.errorMessage,
  });

  factory UnifiedHealthInsight.error(String message) {
    return UnifiedHealthInsight(
      airQuality: null,
      healthSummary: {},
      healthPatterns: {},
      dailyInsight: 'Unable to generate insights',
      warnings: [],
      confidenceScore: 0.0,
      timestamp: DateTime.now(),
      hasError: true,
      errorMessage: message,
    );
  }
}

class ActivityRecommendation {
  final String activityType;
  final String recommendation;
  final bool isSafe;
  final List<String> alternativeSuggestions;
  final AirQualityStatus? airQualityStatus;
  final List<String> warnings;
  final bool hasError;
  final String? errorMessage;

  ActivityRecommendation({
    required this.activityType,
    required this.recommendation,
    required this.isSafe,
    required this.alternativeSuggestions,
    this.airQualityStatus,
    required this.warnings,
    this.hasError = false,
    this.errorMessage,
  });

  factory ActivityRecommendation.error(String activityType, String message) {
    return ActivityRecommendation(
      activityType: activityType,
      recommendation: 'Unable to generate recommendation',
      isSafe: false,
      alternativeSuggestions: [],
      warnings: [],
      hasError: true,
      errorMessage: message,
    );
  }
}