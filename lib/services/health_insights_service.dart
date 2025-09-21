import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_health_profile.dart';
import '../models/air_quality.dart';

class HealthInsightsService {
  static const String baseUrl = 'http://168.5.158.82:5001/api';
  
  // Generate daily health summary combining Fitbit data with air quality
  static Future<Map<String, dynamic>> getDailyHealthSummary({
    required String userId,
    required Map<String, dynamic> airQualityData,
    required UserHealthProfile userProfile,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/insights/daily-summary'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'air_quality': airQualityData,
          'user_profile': _profileToJson(userProfile),
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to generate health summary');
      }
    } catch (e) {
      print('Error getting daily health summary: $e');
      return {
        'success': false,
        'error': e.toString(),
        'insight': 'Unable to generate health insights at this time.',
      };
    }
  }

  // Get activity recommendations based on health data and air quality
  static Future<Map<String, dynamic>> getActivityRecommendation({
    required String userId,
    required String activityType,
    required Map<String, dynamic> airQualityData,
    required UserHealthProfile userProfile,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/insights/activity-recommendation'),
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
        throw Exception('Failed to generate activity recommendation');
      }
    } catch (e) {
      print('Error getting activity recommendation: $e');
      return {
        'success': false,
        'error': e.toString(),
        'insight': 'Unable to generate activity recommendations at this time.',
      };
    }
  }

  // Get health patterns and trends
  static Future<Map<String, dynamic>> getHealthPatterns({
    required String userId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/insights/health-patterns?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get health patterns');
      }
    } catch (e) {
      print('Error getting health patterns: $e');
      return {
        'success': false,
        'error': e.toString(),
        'insight': 'Unable to retrieve health patterns at this time.',
      };
    }
  }

  // Get heart rate data
  static Future<Map<String, dynamic>> getHeartRateData({
    required String userId,
    String? startDate,
    String? endDate,
    int limit = 1000,
  }) async {
    try {
      final queryParams = {
        'start_date': startDate ?? DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0],
        'end_date': endDate ?? DateTime.now().toIso8601String().split('T')[0],
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/users/$userId/heart-rate')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get heart rate data');
      }
    } catch (e) {
      print('Error getting heart rate data: $e');
      return {
        'success': false,
        'error': e.toString(),
        'data': [],
      };
    }
  }

  // Get activity data
  static Future<Map<String, dynamic>> getActivityData({
    required String userId,
    int days = 7,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/activity?days=$days'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get activity data');
      }
    } catch (e) {
      print('Error getting activity data: $e');
      return {
        'success': false,
        'error': e.toString(),
        'data': [],
      };
    }
  }

  // Get health summary
  static Future<Map<String, dynamic>> getHealthSummary({
    required String userId,
    int days = 7,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/health-summary?days=$days'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get health summary');
      }
    } catch (e) {
      print('Error getting health summary: $e');
      return {
        'success': false,
        'error': e.toString(),
        'summary': {},
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