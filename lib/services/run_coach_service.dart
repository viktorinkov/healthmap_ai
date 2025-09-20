import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/run_coach_models.dart';
import '../models/user_health_profile.dart';

class RunCoachService {
  static const String baseUrl = 'http://10.0.2.2:5001/api/run-coach';
  
  // Mock user profile - in production, this would come from user settings
  final Map<String, dynamic> _mockUserProfile = {
    'user_id': 'user123',
    'health_conditions': ['asthma'],
    'age_group': '25-34',
    'fitness_level': 'intermediate',
    'resting_hr': 55,
    'avg_hrv': 45,
    'vo2_max_estimate': 48,
  };

  Future<RouteRecommendation> getRouteRecommendation({
    required LatLng location,
    required double distanceKm,
    required bool prioritizeParks,
    required bool avoidTraffic,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/recommend-route'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'location': {
            'lat': location.latitude,
            'lon': location.longitude,
          },
          'user_profile': _mockUserProfile,
          'preferences': {
            'preferred_distance_m': (distanceKm * 1000).round(),
            'max_elevation_gain_m': 100,
            'avoid_traffic': avoidTraffic,
            'prioritize_parks': prioritizeParks,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RouteRecommendation.fromJson(data);
      } else {
        throw Exception('Failed to get route recommendation: ${response.body}');
      }
    } catch (e) {
      print('Error getting route recommendation: $e');
      // Return mock data for development
      return _getMockRouteRecommendation();
    }
  }

  Future<List<TimeWindow>> getOptimalTimes({
    required LatLng location,
    required int durationMinutes,
    int lookaheadHours = 24,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/optimal-times'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'location': {
            'lat': location.latitude,
            'lon': location.longitude,
          },
          'user_profile': _mockUserProfile,
          'duration_minutes': durationMinutes,
          'lookahead_hours': lookaheadHours,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['optimal_windows'] as List)
            .map((w) => TimeWindow.fromJson(w))
            .toList();
      } else {
        throw Exception('Failed to get optimal times: ${response.body}');
      }
    } catch (e) {
      print('Error getting optimal times: $e');
      // Return mock data for development
      return _getMockTimeWindows();
    }
  }

  Future<HealthRiskAssessment> getHealthRiskAssessment({
    required double currentAqi,
    String activityType = 'running',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/health-risk-assessment'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_profile': _mockUserProfile,
          'current_aqi': currentAqi,
          'activity_type': activityType,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return HealthRiskAssessment.fromJson(data);
      } else {
        throw Exception('Failed to get health risk assessment: ${response.body}');
      }
    } catch (e) {
      print('Error getting health risk assessment: $e');
      // Return mock data for development
      return _getMockHealthRiskAssessment();
    }
  }

  Future<PollutionHeatmap> getPollutionHeatmap({
    required LatLng location,
    required double radiusKm,
    String pollutant = 'aqi',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/pollution-heatmap'
            '?lat=${location.latitude}'
            '&lon=${location.longitude}'
            '&radius_km=$radiusKm'
            '&pollutant=$pollutant'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PollutionHeatmap.fromJson(data);
      } else {
        throw Exception('Failed to get pollution heatmap: ${response.body}');
      }
    } catch (e) {
      print('Error getting pollution heatmap: $e');
      // Return null for optional heatmap
      throw e;
    }
  }

  // Mock data methods for development
  RouteRecommendation _getMockRouteRecommendation() {
    return RouteRecommendation(
      route: RunRoute(
        id: 'mock_route_1',
        polyline: 'mock_polyline',
        geometry: [
          [37.7749, -122.4194],
          [37.7751, -122.4180],
          [37.7755, -122.4170],
          [37.7760, -122.4165],
          [37.7758, -122.4155],
          [37.7752, -122.4150],
          [37.7749, -122.4194],
        ],
        distanceM: 5200,
        durationMin: 28,
        elevationGainM: 25,
        avgAqi: 42,
        maxAqi: 58,
        exposureScore: 0.23,
        greenCoverage: 0.65,
        safetyScore: 0.85,
        elevationProfile: [10, 12, 15, 20, 25, 20, 15, 10],
        segments: [
          RouteSegment(
            startPoint: [37.7749, -122.4194],
            endPoint: [37.7751, -122.4180],
            distanceM: 150,
            aqi: 38,
            pm25: 12.5,
            recommendedPace: 'moderate',
          ),
        ],
      ),
      timeWindows: _getMockTimeWindows(),
      healthRecommendation: {
        'current': {
          'status': 'good',
          'advice': 'Good conditions for outdoor activities',
        },
        'activities': {
          'running': {
            'recommended': true,
            'intensity': 'moderate',
            'duration': 'normal',
            'notes': 'Good conditions, stay hydrated',
          },
        },
      },
    );
  }

  List<TimeWindow> _getMockTimeWindows() {
    final now = DateTime.now();
    return [
      TimeWindow(
        start: now.add(const Duration(hours: 2)),
        end: now.add(const Duration(hours: 3)),
        avgAqi: 35,
        quality: 'excellent',
        confidence: 0.9,
      ),
      TimeWindow(
        start: now.add(const Duration(hours: 6)),
        end: now.add(const Duration(hours: 7)),
        avgAqi: 42,
        quality: 'good',
        confidence: 0.85,
      ),
      TimeWindow(
        start: now.add(const Duration(hours: 18)),
        end: now.add(const Duration(hours: 19)),
        avgAqi: 48,
        quality: 'good',
        confidence: 0.8,
      ),
    ];
  }

  HealthRiskAssessment _getMockHealthRiskAssessment() {
    return HealthRiskAssessment(
      personalThreshold: 60,
      currentRiskLevel: 'low',
      exposureBudget: {
        'daily_limit': 800.0,
        'weekly_limit': 4000.0,
        'current_usage': 1200.0,
        'remaining_budget': 2800.0,
        'usage_percentage': 30.0,
      },
      recommendations: {
        'current': {
          'status': 'good',
          'advice': 'Good conditions for outdoor activities',
          'aqi': 42.0,
          'threshold': 60.0,
        },
        'activities': {
          'running': {
            'recommended': true,
            'intensity': 'moderate',
            'duration': 'normal',
            'notes': 'Good conditions, stay hydrated',
          },
        },
      },
    );
  }
}