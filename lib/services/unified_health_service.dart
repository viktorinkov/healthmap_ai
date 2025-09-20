import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_health_profile.dart';
import '../models/air_quality.dart';
import 'api_service.dart';
import 'health_insights_service.dart';

class UnifiedHealthService {
  static const String pythonBackendUrl = 'http://10.0.2.2:5001/api';
  
  /// Get unified health recommendations from Python backend's daily-summary endpoint
  /// This calls the actual Gemini AI service that analyzes real Fitbit data
  static Future<Map<String, dynamic>> getUnifiedRecommendation({
    required String userId,
    required Map<String, dynamic> currentLocation,
  }) async {
    try {
      // First get current air quality from Node.js backend
      final airQualityData = await ApiService.getCurrentAirQuality(
        latitude: currentLocation['latitude'] ?? 29.7604,
        longitude: currentLocation['longitude'] ?? -95.3698,
      );
      
      // Create user profile for request (simplified)
      final userProfile = {
        'health_conditions': [],
        'age_group': 'adult',
        'is_pregnant': false,
        'sensitivity_level': 3,
        'lifestyle_risks': [],
        'domestic_risks': [],
      };
      
      // Call Python backend's daily-summary endpoint which uses Gemini AI
      final response = await http.post(
        Uri.parse('$pythonBackendUrl/insights/daily-summary'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'air_quality': airQualityData,
          'user_profile': userProfile,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'recommendation': data['insight'] ?? 'No insights available',
          'confidence': data['confidence_score'] ?? 0.0,
          'health_summary': data['health_summary'] ?? {},
          'warnings': data['warnings'] ?? [],
          'timestamp': data['timestamp'] ?? DateTime.now().toIso8601String(),
          'success': data['success'] ?? false,
        };
      } else {
        throw Exception('Backend returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error getting unified recommendation: $e');
      return {
        'recommendation': 'Unable to generate insights. Please ensure the Python backend is running on port 5001 and has processed health data.',
        'confidence': 0.0,
        'error': e.toString(),
        'success': false,
      };
    }
  }
  
  /// Get health patterns insight from Python backend
  static Future<Map<String, dynamic>> getHealthPatterns({
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$pythonBackendUrl/insights/health-patterns?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get health patterns: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'insight': 'Unable to retrieve health patterns.',
        'error': e.toString(),
      };
    }
  }
  
  /// Get activity-specific recommendations
  static Future<Map<String, dynamic>> getActivityRecommendation({
    required String userId,
    required String activityType,
    required double latitude,
    required double longitude,
    required UserHealthProfile userProfile,
  }) async {
    try {
      // Get current air quality
      final airQualityData = await ApiService.getCurrentAirQuality(
        latitude: latitude,
        longitude: longitude,
      );
      
      // Get recommendation from Python backend
      final response = await http.post(
        Uri.parse('$pythonBackendUrl/insights/activity-recommendation'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'activity_type': activityType,
          'air_quality': airQualityData,
          'user_profile': _profileToJson(userProfile),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get activity recommendation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting activity recommendation: $e');
      return {
        'success': false,
        'insight': 'Unable to generate activity recommendation.',
        'error': e.toString(),
      };
    }
  }

  // Convert UserHealthProfile to JSON
  static Map<String, dynamic> _profileToJson(UserHealthProfile profile) {
    return {
      'health_conditions': profile.conditions.map((c) => c.name).toList(),
      'age_group': profile.ageGroup.name,
      'is_pregnant': profile.isPregnant,
      'lifestyle_risks': profile.lifestyleRisks.map((r) => r.name).toList(),
      'domestic_risks': profile.domesticRisks.map((r) => r.name).toList(),
    };
  }
}