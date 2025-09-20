import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_health_profile.dart';
import '../models/air_quality.dart';
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
  }) async {
    try {
      final prompt = _buildRecommendationPrompt(
        userProfile: userProfile,
        recentAirQuality: recentAirQuality,
        location: location,
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

CURRENT AIR QUALITY in $location:
${currentAQ != null ? '''
- Status: ${currentAQ.status.displayName}
- PM2.5: ${currentAQ.metrics.pm25.toStringAsFixed(1)} μg/m³
- PM10: ${currentAQ.metrics.pm10.toStringAsFixed(1)} μg/m³
- Ozone: ${currentAQ.metrics.o3.toStringAsFixed(1)} ppb
- NO2: ${currentAQ.metrics.no2.toStringAsFixed(1)} ppb
- Wildfire Index: ${currentAQ.metrics.wildfireIndex.toStringAsFixed(1)}/100
- Radon: ${currentAQ.metrics.radon.toStringAsFixed(1)} pCi/L
''' : 'No current data available'}

INSTRUCTIONS:
1. Provide 5-8 specific, actionable health recommendations
2. Each recommendation should start with an emoji
3. Consider the person's specific health conditions and sensitivities
4. Include both outdoor activity guidance and indoor air quality tips
5. Be encouraging but prioritize safety
6. Format each recommendation as a separate line

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

  static bool get isConfigured => ApiKeys.hasGeminiKey;
}