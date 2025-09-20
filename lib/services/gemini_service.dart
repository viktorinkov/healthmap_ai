import 'package:flutter/foundation.dart';
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
        debugPrint('Initializing Gemini model...');
        debugPrint('API Key present: ${apiKey.isNotEmpty}');
        if (apiKey.isNotEmpty) {
          _model = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: apiKey,
          );
          debugPrint('Gemini model initialized successfully');
        } else {
          debugPrint('Gemini API key is empty');
        }
      } catch (e) {
        debugPrint('Failed to initialize Gemini model: $e');
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
      debugPrint('Error generating Gemini recommendations: $e');
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
      debugPrint('Error generating Gemini daily tasks: $e');
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

  static Future<Map<String, dynamic>> generateIntelligentAirQualityAssessment({
    required AirQualityMetrics metrics,
    String? locationName,
    List<HealthRecommendationTag>? healthRecommendations,
  }) async {
    try {
      debugPrint('Generating Gemini assessment for location: $locationName');
      debugPrint('API Key configured: ${ApiKeys.hasGeminiKey}');

      // Build health recommendations context
      String healthContext = '';
      if (healthRecommendations != null && healthRecommendations.isNotEmpty) {
        healthContext = '\nHEALTH RECOMMENDATIONS HIGHLIGHTS:\n';
        for (final rec in healthRecommendations) {
          healthContext += '- ${rec.population.displayName}: ${rec.recommendation} (Level: ${rec.level.name})\n';
        }
      }

      final prompt = '''
You are an expert environmental health scientist. Analyze the air quality data and provide a concise assessment.

LOCATION: ${locationName ?? 'Current Location'}

AIR QUALITY INDEX (AQI): ${metrics.universalAqi ?? 'Not available'}
${metrics.universalAqi != null ? _getAqiContext(metrics.universalAqi!) : ''}

POLLUTANT CONCENTRATIONS:
- PM2.5: ${metrics.pm25.toStringAsFixed(1)} μg/m³ (EPA: 35, WHO: 15)
- PM10: ${metrics.pm10.toStringAsFixed(1)} μg/m³ (EPA: 150, WHO: 45)
- Ozone: ${metrics.o3.toStringAsFixed(1)} ppb (EPA: 70)
- NO₂: ${metrics.no2.toStringAsFixed(1)} ppb (EPA: 100)${metrics.co != null ? '\n- CO: ${metrics.co!.toStringAsFixed(1)} ppb' : ''}${metrics.so2 != null ? '\n- SO₂: ${metrics.so2!.toStringAsFixed(1)} ppb' : ''}

ADDITIONAL FACTORS:
- Wildfire Index: ${metrics.wildfireIndex.toStringAsFixed(1)}/100${metrics.wildfireRiskLevel != null ? ' (${metrics.wildfireRiskLevel})' : ''}
- Radon: ${metrics.radon.toStringAsFixed(1)} pCi/L${metrics.radonRiskLevel != null ? ' (${metrics.radonRiskLevel} risk)' : ''}$healthContext

TASK: Provide a comprehensive assessment considering:
1. AQI score and pollutant levels relative to health standards
2. Special risks from wildfire smoke and radon exposure
3. Health recommendations for different population groups
4. Cumulative health impact of multiple pollutants

REQUIRED OUTPUT FORMAT (no deviation):
Status: [good/caution/avoid]
Justification: [Single sentence, max 150 characters, identifying primary concern and affected populations]

Assessment:''';

      if (model == null) {
        debugPrint('Gemini model is null - API key might be missing');
        throw Exception('Gemini not configured');
      }

      debugPrint('Calling Gemini API...');
      final response = await model!.generateContent([Content.text(prompt)]);

      if (response.text != null) {
        debugPrint('Gemini response received: ${response.text!.substring(0, 100 > response.text!.length ? response.text!.length : 100)}...');
        return _parseAirQualityAssessment(response.text!);
      } else {
        debugPrint('Gemini returned null response');
        throw Exception('No assessment available');
      }
    } catch (e) {
      debugPrint('Error generating Gemini air quality assessment: $e');
      debugPrint('Error type: ${e.runtimeType}');
      throw Exception('Assessment unavailable: $e');
    }
  }

  static String _getAqiContext(int aqi) {
    if (aqi <= 50) {
      return '(0-50: Good - Air quality is satisfactory)';
    } else if (aqi <= 100) {
      return '(51-100: Moderate - Acceptable for most, sensitive groups may experience minor issues)';
    } else if (aqi <= 150) {
      return '(101-150: Unhealthy for Sensitive Groups)';
    } else if (aqi <= 200) {
      return '(151-200: Unhealthy - Everyone may experience health effects)';
    } else if (aqi <= 300) {
      return '(201-300: Very Unhealthy - Health warnings)';
    } else {
      return '(301+: Hazardous - Emergency conditions)';
    }
  }

  static Map<String, dynamic> _parseAirQualityAssessment(String response) {
    // Clean and normalize the response
    final cleanResponse = response.trim();
    final lines = cleanResponse.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

    String status = 'caution';
    String justification = 'Air quality requires attention based on current pollutant levels.';

    // More robust parsing with fallback patterns
    for (final line in lines) {
      final lowerLine = line.toLowerCase();

      // Parse status with multiple pattern matching
      if (lowerLine.startsWith('status:') || lowerLine.startsWith('assessment:')) {
        final colonIndex = line.indexOf(':');
        if (colonIndex != -1) {
          final statusText = line.substring(colonIndex + 1).trim().toLowerCase();
          if (statusText.contains('good') || statusText.contains('satisfactory')) {
            status = 'good';
          } else if (statusText.contains('avoid') || statusText.contains('unhealthy') || statusText.contains('hazardous')) {
            status = 'avoid';
          } else if (statusText.contains('caution') || statusText.contains('moderate') || statusText.contains('sensitive')) {
            status = 'caution';
          }
        }
      }

      // Parse justification with better handling
      else if (lowerLine.startsWith('justification:') || lowerLine.startsWith('reason:')) {
        final colonIndex = line.indexOf(':');
        if (colonIndex != -1) {
          var rawJustification = line.substring(colonIndex + 1).trim();

          // Handle potential clipping by ensuring sentence completeness
          if (rawJustification.isNotEmpty) {
            // Ensure the justification ends properly (with punctuation or is reasonably complete)
            if (!rawJustification.endsWith('.') && !rawJustification.endsWith('!') && !rawJustification.endsWith('?')) {
              // If it seems cut off, add ellipsis for clarity but prefer complete sentences
              if (rawJustification.length > 100) {
                rawJustification = rawJustification.substring(0, 100).trim() + '...';
              }
            }

            // Truncate if too long while preserving meaning
            if (rawJustification.length > 200) {
              final sentences = rawJustification.split('. ');
              rawJustification = sentences.first;
              if (!rawJustification.endsWith('.')) {
                rawJustification += '.';
              }
            }

            justification = rawJustification;
          }
        }
      }

      // Try to extract status from patterns within the text if not found yet
      else if (status == 'caution' && (lowerLine.contains('good air quality') || lowerLine.contains('satisfactory'))) {
        status = 'good';
      } else if (status == 'caution' && (lowerLine.contains('avoid') || lowerLine.contains('unhealthy') || lowerLine.contains('hazardous'))) {
        status = 'avoid';
      }
    }

    // Fallback: try to extract information from the entire response if structured parsing failed
    if (status == 'caution' && justification.contains('current pollutant levels')) {
      final responseLower = cleanResponse.toLowerCase();
      if (responseLower.contains('good') && !responseLower.contains('avoid') && !responseLower.contains('unhealthy')) {
        status = 'good';
      } else if (responseLower.contains('avoid') || responseLower.contains('unhealthy') || responseLower.contains('hazardous')) {
        status = 'avoid';
      }

      // Extract a meaningful justification from the response if the default one is still being used
      if (justification.contains('current pollutant levels') && cleanResponse.length > 50) {
        // Try to find a sentence that explains the reasoning
        final sentences = cleanResponse.split(RegExp(r'[.!?]+'));
        for (final sentence in sentences) {
          final trimmedSentence = sentence.trim();
          if (trimmedSentence.length > 20 && trimmedSentence.length < 200 &&
              (trimmedSentence.toLowerCase().contains('pm') ||
               trimmedSentence.toLowerCase().contains('aqi') ||
               trimmedSentence.toLowerCase().contains('pollutant') ||
               trimmedSentence.toLowerCase().contains('air quality'))) {
            justification = trimmedSentence + (trimmedSentence.endsWith('.') ? '' : '.');
            break;
          }
        }
      }
    }

    // Final validation and cleanup
    if (justification.length > 200) {
      justification = justification.substring(0, 197) + '...';
    }

    return {
      'status': status,
      'justification': justification,
    };
  }


  static bool get isConfigured => ApiKeys.hasGeminiKey;
}