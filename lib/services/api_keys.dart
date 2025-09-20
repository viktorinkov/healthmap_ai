import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static String get googleMapsApiKey {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception(
          'Google Maps API key not found. Please create a .env file with GOOGLE_MAPS_API_KEY=your_api_key_here');
    }
    return apiKey;
  }

  static String get geminiApiKey {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    // Don't throw exception, just return empty string if not configured
    return apiKey;
  }

  static String get openWeatherMapApiKey {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    return apiKey;
  }

  // Optional: Check if keys are configured with real values (not placeholders)
  static bool get hasGoogleMapsKey {
    final key = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    return key.isNotEmpty && !key.contains('your_') && !key.contains('_here');
  }

  static bool get hasGeminiKey {
    final key = dotenv.env['GEMINI_API_KEY'] ?? '';
    return key.isNotEmpty && !key.contains('your_') && !key.contains('_here');
  }

  static bool get hasOpenWeatherKey {
    final key = dotenv.env['OPENWEATHER_API_KEY'] ?? '';
    return key.isNotEmpty && !key.contains('your_') && !key.contains('_here');
  }
}
