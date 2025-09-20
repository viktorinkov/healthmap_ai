import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiKeys {
  static String get googleMapsApiKey {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception(
        'Google Maps API key not found. Please create a .env file with GOOGLE_MAPS_API_KEY=your_api_key_here'
      );
    }
    return apiKey;
  }

  static String get geminiApiKey {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    // Don't throw exception, just return empty string if not configured
    return apiKey;
  }

  // Optional: Check if keys are configured
  static bool get hasGoogleMapsKey => dotenv.env['GOOGLE_MAPS_API_KEY']?.isNotEmpty ?? false;
  static bool get hasGeminiKey => dotenv.env['GEMINI_API_KEY']?.isNotEmpty ?? false;
}