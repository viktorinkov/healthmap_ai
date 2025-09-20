import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_health_profile.dart';
import '../models/air_quality.dart';
import '../models/environmental_measurements.dart';
import 'api_keys.dart';

class GeminiService {
  static GenerativeModel? _model;

  static GenerativeModel? get model {
    if (_model == null) {
      try {
        final apiKey = ApiKeys.geminiApiKey;
        if (apiKey.isNotEmpty) {
          _model = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: apiKey,
          );
        }
      } catch (e) {
        print('Failed to initialize Gemini model: $e');
      }
    }
    return _model;
  }

  static Future<List<String>> generateHealthRecommendations({
    required UserHealthProfile userProfile,
    required List<AirQualityData> recentAirQuality,
    String location = 'Houston',
    EnvironmentalMeasurements? environmentalMeasurements,
  }) async {
    try {
      final prompt = _buildRecommendationPrompt(
        userProfile: userProfile,
        recentAirQuality: recentAirQuality,
        location: location,
        environmentalMeasurements: environmentalMeasurements,
      );

      if (model == null) {
        return ['Unable to generate AI recommendations. Please check your Gemini API key.'];
      }
      final response = await model!.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        return _parseRecommendations(response.text!);
      } else {
        return ['Unable to generate personalized recommendations at this time.'];
      }
    } catch (e) {
      print('Error generating Gemini recommendations: $e');
      return ['Unable to generate personalized recommendations at this time.'];
    }
  }

  static String _buildRecommendationPrompt({
    required UserHealthProfile userProfile,
    required List<AirQualityData> recentAirQuality,
    required String location,
    EnvironmentalMeasurements? environmentalMeasurements,
  }) {
    final currentAQ = recentAirQuality.isNotEmpty ? recentAirQuality.first : null;

    final prompt = '''
You are a health AI assistant specializing in air quality and public health. Generate personalized daily recommendations for a person with the following profile:

HEALTH PROFILE:
- Age Group: ${userProfile.ageGroup.displayName}
- Pregnancy Status: ${userProfile.isPregnant ? 'Pregnant' : 'Not pregnant'}
- Sensitivity Level: ${userProfile.sensitivityLevel}/5
- Health Conditions: ${userProfile.conditions.map((c) => c.displayName).join(', ')}
- Lifestyle Factors: ${userProfile.lifestyleRisks.map((r) => r.name).join(', ')}
- Home Environment: ${userProfile.domesticRisks.map((r) => r.name).join(', ')}

CURRENT ENVIRONMENTAL CONDITIONS in $location:
${currentAQ != null ? '''
- Air Quality Status: ${currentAQ.status.displayName}
- PM2.5: ${currentAQ.metrics.pm25.toStringAsFixed(1)} μg/m³
- PM10: ${currentAQ.metrics.pm10.toStringAsFixed(1)} μg/m³
- Ozone: ${currentAQ.metrics.o3.toStringAsFixed(1)} ppb
- NO2: ${currentAQ.metrics.no2.toStringAsFixed(1)} ppb
- Wildfire Index: ${currentAQ.metrics.wildfireIndex.toStringAsFixed(1)}/100
- Radon: ${currentAQ.metrics.radon.toStringAsFixed(1)} pCi/L
''' : 'No current air quality data available'}

${environmentalMeasurements != null ? '''
ENVIRONMENTAL MEASUREMENTS:
${environmentalMeasurements.airQuality != null ? '''
AIR QUALITY MEASUREMENTS (${environmentalMeasurements.airQuality!.measurementSource}):
- PM2.5: ${environmentalMeasurements.airQuality!.pm25?.toStringAsFixed(1) ?? 'N/A'} μg/m³ (EPA standard: 35 μg/m³)
- PM10: ${environmentalMeasurements.airQuality!.pm10?.toStringAsFixed(1) ?? 'N/A'} μg/m³ (EPA standard: 150 μg/m³)
- Ozone: ${environmentalMeasurements.airQuality!.ozone?.toStringAsFixed(1) ?? 'N/A'} ppb (EPA standard: 70 ppb)
- NO₂: ${environmentalMeasurements.airQuality!.nitrogenDioxide?.toStringAsFixed(1) ?? 'N/A'} ppb (EPA standard: 100 ppb)
- CO: ${environmentalMeasurements.airQuality!.carbonMonoxide?.toStringAsFixed(1) ?? 'N/A'} ppb
- SO₂: ${environmentalMeasurements.airQuality!.sulfurDioxide?.toStringAsFixed(1) ?? 'N/A'} ppb
''' : ''}${environmentalMeasurements.meteorology != null ? '''
WEATHER CONDITIONS (${environmentalMeasurements.meteorology!.measurementSource}):
- Temperature: ${environmentalMeasurements.meteorology!.temperatureCelsius?.toStringAsFixed(1) ?? 'N/A'}°C (${environmentalMeasurements.meteorology!.temperatureFahrenheit?.toStringAsFixed(1) ?? 'N/A'}°F)
- Humidity: ${environmentalMeasurements.meteorology!.relativeHumidityPercent?.toStringAsFixed(0) ?? 'N/A'}%
- Wind Speed: ${environmentalMeasurements.meteorology!.windSpeedMs?.toStringAsFixed(1) ?? 'N/A'} m/s (${environmentalMeasurements.meteorology!.windSpeedMph?.toStringAsFixed(1) ?? 'N/A'} mph)
- UV Index: ${environmentalMeasurements.meteorology!.uvIndex?.toString() ?? 'N/A'}
- Air Stagnation: ${environmentalMeasurements.meteorology!.stagnationEvent ? 'Yes' : 'No'}
- Pressure: ${environmentalMeasurements.meteorology!.atmosphericPressureHpa?.toStringAsFixed(1) ?? 'N/A'} hPa
''' : ''}${environmentalMeasurements.aeroallergens != null ? '''
POLLEN & ALLERGENS (${environmentalMeasurements.aeroallergens!.measurementSource}):
- Tree Pollen: ${environmentalMeasurements.aeroallergens!.treePollenGrainsPerM3?.toString() ?? 'N/A'} grains/m³
- Grass Pollen: ${environmentalMeasurements.aeroallergens!.grassPollenGrainsPerM3?.toString() ?? 'N/A'} grains/m³
- Weed Pollen: ${environmentalMeasurements.aeroallergens!.weedPollenGrainsPerM3?.toString() ?? 'N/A'} grains/m³
- Mold Spores: ${environmentalMeasurements.aeroallergens!.moldSporesPerM3?.toString() ?? 'N/A'} spores/m³
- Dominant Types: ${environmentalMeasurements.aeroallergens!.dominantPollenTypes.isNotEmpty ? environmentalMeasurements.aeroallergens!.dominantPollenTypes.join(', ') : 'N/A'}
''' : ''}${environmentalMeasurements.wildfire != null ? '''
WILDFIRE ACTIVITY (${environmentalMeasurements.wildfire!.measurementSource}):
- Active Fires: ${environmentalMeasurements.wildfire!.activeFireCount}
- Nearest Fire: ${environmentalMeasurements.wildfire!.nearestFireDistanceKm?.toStringAsFixed(1) ?? 'N/A'} km
- Smoke PM2.5: ${environmentalMeasurements.wildfire!.smokeParticulates?.toStringAsFixed(1) ?? 'N/A'} μg/m³
- Visibility: ${environmentalMeasurements.wildfire!.visibilityKm?.toStringAsFixed(1) ?? 'N/A'} km
''' : ''}${environmentalMeasurements.indoorEnvironment != null ? '''
INDOOR ENVIRONMENT (${environmentalMeasurements.indoorEnvironment!.measurementSource}):
- Radon: ${environmentalMeasurements.indoorEnvironment!.radonLevelPciL?.toStringAsFixed(1) ?? 'N/A'} pCi/L (EPA action level: 4.0 pCi/L)
- VOCs: ${environmentalMeasurements.indoorEnvironment!.volatileOrganicCompoundsPpb?.toStringAsFixed(1) ?? 'N/A'} ppb
- CO (Indoor): ${environmentalMeasurements.indoorEnvironment!.carbonMonoxidePpm?.toStringAsFixed(1) ?? 'N/A'} ppm
- Mold Spores: ${environmentalMeasurements.indoorEnvironment!.moldSporesPerM3?.toStringAsFixed(0) ?? 'N/A'} spores/m³
- Formaldehyde: ${environmentalMeasurements.indoorEnvironment!.formaldehydePpb?.toStringAsFixed(1) ?? 'N/A'} ppb
''' : ''}
''' : 'Environmental measurements not available'}

INSTRUCTIONS:
1. Provide 5-8 specific, actionable health recommendations
2. Each recommendation should start with an emoji
3. Consider the person's specific health conditions and sensitivities
4. Use the comprehensive environmental assessment to provide targeted advice
5. Address all environmental factors: air quality, weather, wildfire, pollen, and indoor conditions
6. Include both outdoor activity guidance and indoor air quality tips
7. Be encouraging but prioritize safety based on environmental conditions
8. Format each recommendation as a separate line

Generate personalized recommendations:
''';

    return prompt;
  }

  static List<String> _parseRecommendations(String response) {
    // Split response into individual recommendations
    final lines = response.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .where((line) => line.contains('•') || line.contains('✓') || line.contains('🔸') ||
                         line.startsWith('1.') || line.startsWith('2.') ||
                         line.startsWith('3.') || line.startsWith('4.') ||
                         line.startsWith('5.') || line.startsWith('6.') ||
                         line.startsWith('7.') || line.startsWith('8.') ||
                         RegExp(r'^[🌟💡🏃‍♀️🏠💨😷🌱⚠️❤️🤱👶👵🏋️‍♂️👷‍♂️🚗🌅🌪️☀️🔥✅💧🌡️]').hasMatch(line))
        .map((line) => line.trim())
        .take(8)
        .toList();

    if (lines.isEmpty) {
      // Fallback parsing - split by periods or numbered lists
      final fallbackLines = response.split(RegExp(r'[.!]\s+'))
          .where((line) => line.trim().length > 20)
          .take(6)
          .map((line) => line.trim())
          .toList();

      return fallbackLines.isNotEmpty ? fallbackLines :
          ['Unable to parse recommendations. Please try again.'];
    }

    return lines;
  }

  static Future<String> generateLocationInsight({
    required String locationName,
    required AirQualityData airQuality,
  }) async {
    try {
      final prompt = '''
Generate a brief, informative insight about the air quality for $locationName.

Current Air Quality Data:
- Status: ${airQuality.status.displayName}
- PM2.5: ${airQuality.metrics.pm25.toStringAsFixed(1)} μg/m³
- PM10: ${airQuality.metrics.pm10.toStringAsFixed(1)} μg/m³
- Ozone: ${airQuality.metrics.o3.toStringAsFixed(1)} ppb

Provide a 1-2 sentence explanation of what this means for residents in simple terms.
''';

      if (model == null) {
        return 'Air quality data available for $locationName.';
      }
      final response = await model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Air quality data available for $locationName.';
    } catch (e) {
      return 'Air quality data available for $locationName.';
    }
  }

  static Future<List<dynamic>> generateDailyTasks({
    required UserHealthProfile userProfile,
    required DateTime date,
  }) async {
    try {
      final prompt = _buildDailyTasksPrompt(userProfile: userProfile, date: date);

      if (model == null) {
        return [];
      }
      final response = await model!.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        return _parseDailyTasks(response.text!, date);
      } else {
        return [];
      }
    } catch (e) {
      print('Error generating Gemini daily tasks: $e');
      return [];
    }
  }

  static String _buildDailyTasksPrompt({
    required UserHealthProfile userProfile,
    required DateTime date,
  }) {
    final dayOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][date.weekday - 1];

    final prompt = '''
You are a health AI assistant. Generate 3-5 personalized daily tasks for a person based on their health profile for $dayOfWeek.

HEALTH PROFILE:
- Age Group: ${userProfile.ageGroup.displayName}
- Pregnancy Status: ${userProfile.isPregnant ? 'Pregnant' : 'Not pregnant'}
- Sensitivity Level: ${userProfile.sensitivityLevel}/5
- Health Conditions: ${userProfile.conditions.map((c) => c.displayName).join(', ')}
- Lifestyle Factors: ${userProfile.lifestyleRisks.map((r) => r.name).join(', ')}
- Home Environment: ${userProfile.domesticRisks.map((r) => r.name).join(', ')}

CATEGORIES: health, fitness, wellness, safety, planning

INSTRUCTIONS:
1. Generate 3-5 specific, actionable daily tasks
2. Consider their health conditions and risk factors
3. Include air quality-related tasks when relevant
4. Format as: TITLE|DESCRIPTION|CATEGORY
5. Make tasks realistic and achievable in one day
6. Focus on health and wellness actions

Generate personalized daily tasks:
''';

    return prompt;
  }

  static List<dynamic> _parseDailyTasks(String response, DateTime date) {
    final tasks = <Map<String, dynamic>>[];
    final lines = response.split('\n')
        .where((line) => line.trim().isNotEmpty && line.contains('|'))
        .take(5)
        .toList();

    for (int i = 0; i < lines.length; i++) {
      final parts = lines[i].split('|');
      if (parts.length >= 3) {
        final title = parts[0].trim().replaceAll(RegExp(r'^[\d\.\-\*\•]+\s*'), '');
        final description = parts[1].trim();
        final categoryStr = parts[2].trim().toLowerCase();

        // Map category string to enum
        String category = 'wellness';
        if (categoryStr.contains('health')) category = 'health';
        else if (categoryStr.contains('fitness')) category = 'fitness';
        else if (categoryStr.contains('safety')) category = 'safety';
        else if (categoryStr.contains('planning')) category = 'planning';

        tasks.add({
          'id': 'ai_task_${date.millisecondsSinceEpoch}_$i',
          'title': title,
          'description': description,
          'category': category,
          'isCompleted': false,
          'createdAt': date.toIso8601String(),
        });
      }
    }

    return tasks;
  }

  static bool get isConfigured => ApiKeys.hasGeminiKey;
}