import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class RunningRoutesService {
  static String get baseUrl => ApiService.baseUrl;

  // Get all routes for the user
  static Future<List<dynamic>> getUserRoutes({bool includeWaypoints = false}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/running/routes?includeWaypoints=$includeWaypoints'),
      headers: ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch routes');
    }
  }

  // Get a single route with details
  static Future<Map<String, dynamic>> getRoute(int routeId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/running/routes/$routeId'),
      headers: ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch route');
    }
  }

  // Create a new route
  static Future<Map<String, dynamic>> createRoute({
    required String name,
    String? description,
    required double distanceKm,
    int? durationMinutes,
    String? difficulty,
    String? routeType,
    required List<Map<String, dynamic>> waypoints,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/running/routes'),
      headers: ApiService.getHeaders(),
      body: jsonEncode({
        'name': name,
        'description': description,
        'distance_km': distanceKm,
        'duration_minutes': durationMinutes,
        'difficulty': difficulty,
        'route_type': routeType,
        'waypoints': waypoints,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create route');
    }
  }

  // Generate example routes
  static Future<Map<String, dynamic>> generateExampleRoutes({
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/running/routes/generate?latitude=$latitude&longitude=$longitude'),
      headers: ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate example routes');
    }
  }

  // Optimize a route based on pollution
  static Future<Map<String, dynamic>> optimizeRoute({
    required int routeId,
    String optimizationType = 'pollution',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/running/routes/$routeId/optimize'),
      headers: ApiService.getHeaders(),
      body: jsonEncode({
        'optimization_type': optimizationType,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to optimize route');
    }
  }

  // Get optimal running times for a route
  static Future<Map<String, dynamic>> getOptimalRunningTimes({
    required int routeId,
    int days = 3,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/running/routes/$routeId/optimal-times?days=$days'),
      headers: ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get optimal running times');
    }
  }

  // Update a route
  static Future<Map<String, dynamic>> updateRoute({
    required int routeId,
    String? name,
    String? description,
    bool? isFavorite,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (isFavorite != null) body['is_favorite'] = isFavorite;

    final response = await http.put(
      Uri.parse('$baseUrl/running/routes/$routeId'),
      headers: ApiService.getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update route');
    }
  }

  // Delete a route
  static Future<void> deleteRoute(int routeId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/running/routes/$routeId'),
      headers: ApiService.getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete route');
    }
  }

  // Record a running session
  static Future<Map<String, dynamic>> recordRunningSession({
    int? routeId,
    required DateTime startedAt,
    DateTime? completedAt,
    double? actualDistanceKm,
    int? actualDurationMinutes,
    int? avgAqi,
    int? avgHeartRate,
    int? caloriesBurned,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/running/sessions'),
      headers: ApiService.getHeaders(),
      body: jsonEncode({
        'route_id': routeId,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'actual_distance_km': actualDistanceKm,
        'actual_duration_minutes': actualDurationMinutes,
        'avg_aqi': avgAqi,
        'avg_heart_rate': avgHeartRate,
        'calories_burned': caloriesBurned,
        'notes': notes,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to record running session');
    }
  }

  // Get running history
  static Future<List<dynamic>> getRunningHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/running/history?limit=$limit&offset=$offset'),
      headers: ApiService.getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch running history');
    }
  }
}