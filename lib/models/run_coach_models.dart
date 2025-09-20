import 'package:flutter/foundation.dart';

class RunRoute {
  final String id;
  final String polyline;
  final List<List<double>> geometry;
  final double distanceM;
  final double durationMin;
  final double elevationGainM;
  final double avgAqi;
  final double maxAqi;
  final double exposureScore;
  final double greenCoverage;
  final double safetyScore;
  final List<double>? elevationProfile;
  final List<RouteSegment> segments;

  RunRoute({
    required this.id,
    required this.polyline,
    required this.geometry,
    required this.distanceM,
    required this.durationMin,
    required this.elevationGainM,
    required this.avgAqi,
    required this.maxAqi,
    required this.exposureScore,
    required this.greenCoverage,
    required this.safetyScore,
    this.elevationProfile,
    required this.segments,
  });

  factory RunRoute.fromJson(Map<String, dynamic> json) {
    return RunRoute(
      id: json['id'],
      polyline: json['polyline'],
      geometry: (json['geometry'] as List?)
          ?.map((point) => (point as List).map((e) => e.toDouble()).toList().cast<double>())
          .toList().cast<List<double>>() ?? [],
      distanceM: json['distance_m'].toDouble(),
      durationMin: json['duration_min'].toDouble(),
      elevationGainM: json['elevation_gain_m'].toDouble(),
      avgAqi: json['avg_aqi'].toDouble(),
      maxAqi: json['max_aqi'].toDouble(),
      exposureScore: json['exposure_score'].toDouble(),
      greenCoverage: json['green_coverage'].toDouble(),
      safetyScore: json['safety_score'].toDouble(),
      elevationProfile: (json['elevation_profile'] as List?)
          ?.map((e) => e.toDouble())
          .toList()
          .cast<double>(),
      segments: (json['segments'] as List)
          .map((s) => RouteSegment.fromJson(s))
          .toList(),
    );
  }

  double get distanceKm => distanceM / 1000;
}

class RouteSegment {
  final List<double> startPoint;
  final List<double> endPoint;
  final double distanceM;
  final double aqi;
  final double pm25;
  final String recommendedPace;

  RouteSegment({
    required this.startPoint,
    required this.endPoint,
    required this.distanceM,
    required this.aqi,
    required this.pm25,
    required this.recommendedPace,
  });

  factory RouteSegment.fromJson(Map<String, dynamic> json) {
    return RouteSegment(
      startPoint: (json['start'] as List).map((e) => e.toDouble()).toList().cast<double>(),
      endPoint: (json['end'] as List).map((e) => e.toDouble()).toList().cast<double>(),
      distanceM: json['distance_m'].toDouble(),
      aqi: json['aqi'].toDouble(),
      pm25: json['pm25'].toDouble(),
      recommendedPace: json['recommended_pace'],
    );
  }
}

class TimeWindow {
  final DateTime start;
  final DateTime end;
  final double avgAqi;
  final String quality;
  final double confidence;

  TimeWindow({
    required this.start,
    required this.end,
    required this.avgAqi,
    required this.quality,
    required this.confidence,
  });

  factory TimeWindow.fromJson(Map<String, dynamic> json) {
    return TimeWindow(
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
      avgAqi: json['avg_aqi'].toDouble(),
      quality: json['quality'],
      confidence: json['confidence'].toDouble(),
    );
  }

  String get timeRange {
    final startTime = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTime = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startTime - $endTime';
  }
}

class HealthRiskAssessment {
  final double personalThreshold;
  final String currentRiskLevel;
  final Map<String, dynamic> exposureBudget;
  final Map<String, dynamic> recommendations;

  HealthRiskAssessment({
    required this.personalThreshold,
    required this.currentRiskLevel,
    required this.exposureBudget,
    required this.recommendations,
  });

  factory HealthRiskAssessment.fromJson(Map<String, dynamic> json) {
    return HealthRiskAssessment(
      personalThreshold: json['personal_threshold'].toDouble(),
      currentRiskLevel: json['current_risk_level'],
      exposureBudget: json['exposure_budget'],
      recommendations: json['recommendations'],
    );
  }

  String get riskLevelDisplay {
    switch (currentRiskLevel) {
      case 'very_low':
        return 'Very Low';
      case 'low':
        return 'Low';
      case 'moderate':
        return 'Moderate';
      case 'high':
        return 'High';
      case 'very_high':
        return 'Very High';
      default:
        return 'Unknown';
    }
  }
}

class PollutionHeatmap {
  final Map<String, double> bounds;
  final List<List<double>> values;
  final List<List<double>> uncertainty;
  final int resolution;
  final String pollutant;
  final String? timestamp;

  PollutionHeatmap({
    required this.bounds,
    required this.values,
    required this.uncertainty,
    required this.resolution,
    required this.pollutant,
    this.timestamp,
  });

  factory PollutionHeatmap.fromJson(Map<String, dynamic> json) {
    return PollutionHeatmap(
      bounds: Map<String, double>.from(json['bounds']),
      values: (json['values'] as List)
          .map((row) => (row as List).map((e) => e.toDouble()).toList().cast<double>())
          .toList()
          .cast<List<double>>(),
      uncertainty: (json['uncertainty'] as List)
          .map((row) => (row as List).map((e) => e.toDouble()).toList().cast<double>())
          .toList()
          .cast<List<double>>(),
      resolution: json['resolution'],
      pollutant: json['pollutant'],
      timestamp: json['timestamp'],
    );
  }
}

class RouteRecommendation {
  final RunRoute route;
  final List<TimeWindow> timeWindows;
  final Map<String, dynamic> healthRecommendation;

  RouteRecommendation({
    required this.route,
    required this.timeWindows,
    required this.healthRecommendation,
  });

  factory RouteRecommendation.fromJson(Map<String, dynamic> json) {
    return RouteRecommendation(
      route: RunRoute.fromJson(json['route']),
      timeWindows: (json['time_windows'] as List)
          .map((w) => TimeWindow.fromJson(w))
          .toList(),
      healthRecommendation: json['health_recommendation'],
    );
  }
}