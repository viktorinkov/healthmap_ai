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
    try {
      print('🔍 RunRoute.fromJson: Parsing JSON: ${json.keys}');

      // Check for geometry field first
      List<List<double>> geometry;
      if (json['geometry'] != null) {
        print('🔍 geometry type: ${json['geometry'].runtimeType}');
        print('🔍 geometry value: ${json['geometry']}');
        geometry = _parseGeometry(json['geometry']);
      } else {
        print('⚠️ No geometry field found, extracting from segments');
        geometry = _extractGeometryFromSegments(json['segments']);
      }

      return RunRoute(
        id: json['id']?.toString() ?? 'unknown',
        polyline: json['polyline']?.toString() ?? '',
        geometry: geometry,
        distanceM: (json['distance_m'] ?? 0).toDouble(),
        durationMin: (json['duration_min'] ?? 0).toDouble(),
        elevationGainM: (json['elevation_gain_m'] ?? 0).toDouble(),
        avgAqi: (json['avg_aqi'] ?? 0).toDouble(),
        maxAqi: (json['max_aqi'] ?? 0).toDouble(),
        exposureScore: (json['exposure_score'] ?? 0).toDouble(),
        greenCoverage: (json['green_coverage'] ?? 0).toDouble(),
        safetyScore: (json['safety_score'] ?? 0).toDouble(),
        elevationProfile: _parseElevationProfile(json['elevation_profile']),
        segments: _parseSegments(json['segments']),
      );
    } catch (e) {
      print('❌ RunRoute.fromJson error: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  static List<List<double>> _parseGeometry(dynamic geometry) {
    if (geometry == null) return [];
    if (geometry is List) {
      try {
        return geometry
            .map((point) => (point as List).map((e) => (e as num).toDouble()).toList())
            .toList().cast<List<double>>();
      } catch (e) {
        print('❌ Error parsing geometry: $e');
        return [];
      }
    }
    print('❌ Unexpected geometry type: ${geometry.runtimeType}');
    return [];
  }

  static List<double>? _parseElevationProfile(dynamic profile) {
    if (profile == null) return null;
    if (profile is List) {
      try {
        return profile.map((e) => (e as num).toDouble()).toList().cast<double>();
      } catch (e) {
        print('❌ Error parsing elevation profile: $e');
        return null;
      }
    }
    return null;
  }

  static List<RouteSegment> _parseSegments(dynamic segments) {
    if (segments == null) return [];
    if (segments is List) {
      try {
        return segments.map((s) => RouteSegment.fromJson(s)).toList().cast<RouteSegment>();
      } catch (e) {
        print('❌ Error parsing segments: $e');
        return [];
      }
    }
    return [];
  }

  static List<List<double>> _extractGeometryFromSegments(dynamic segments) {
    if (segments == null || segments is! List) return [];

    List<List<double>> geometry = [];
    try {
      for (var segment in segments) {
        if (segment is Map<String, dynamic>) {
          // Add start point
          if (segment['start'] != null) {
            final start = RouteSegment._parsePoint(segment['start']);
            if (start.isNotEmpty) geometry.add(start);
          }
          // Add end point
          if (segment['end'] != null) {
            final end = RouteSegment._parsePoint(segment['end']);
            if (end.isNotEmpty) geometry.add(end);
          }
        }
      }

      // Remove duplicates while preserving order
      final Set<String> seen = {};
      geometry = geometry.where((point) {
        final key = '${point[0]},${point[1]}';
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();

      print('🔧 Extracted ${geometry.length} geometry points from ${segments.length} segments');
      return geometry;
    } catch (e) {
      print('❌ Error extracting geometry from segments: $e');
      return [];
    }
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
    try {
      return RouteSegment(
        startPoint: _parsePoint(json['start_point'] ?? json['start']),
        endPoint: _parsePoint(json['end_point'] ?? json['end']),
        distanceM: (json['distance_m'] ?? 0).toDouble(),
        aqi: (json['aqi'] ?? 0).toDouble(),
        pm25: (json['pm25'] ?? 0).toDouble(),
        recommendedPace: json['recommended_pace']?.toString() ?? 'moderate',
      );
    } catch (e) {
      print('❌ RouteSegment.fromJson error: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }

  static List<double> _parsePoint(dynamic point) {
    if (point == null) return [0.0, 0.0];
    if (point is List) {
      try {
        return point.map((e) => (e as num).toDouble()).toList().cast<double>();
      } catch (e) {
        print('❌ Error parsing point: $e');
        return [0.0, 0.0];
      }
    }
    return [0.0, 0.0];
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
    try {
      print('🔍 PollutionHeatmap.fromJson: JSON keys: ${json.keys}');
      print('🔍 bounds type: ${json['bounds'].runtimeType}');
      print('🔍 bounds value: ${json['bounds']}');

      // Handle bounds conversion safely
      Map<String, double> bounds = {};
      if (json['bounds'] is Map) {
        final boundsMap = json['bounds'] as Map<String, dynamic>;
        bounds = boundsMap.map((key, value) =>
          MapEntry(key.toString(), (value as num).toDouble())
        );
      }

      // Handle values array safely
      List<List<double>> values = [];
      if (json['values'] is List) {
        values = (json['values'] as List)
            .map((row) {
              if (row is List) {
                return row.map((e) => (e as num).toDouble()).toList().cast<double>();
              }
              return <double>[];
            })
            .toList()
            .cast<List<double>>();
      }

      // Handle uncertainty array safely
      List<List<double>> uncertainty = [];
      if (json['uncertainty'] is List) {
        uncertainty = (json['uncertainty'] as List)
            .map((row) {
              if (row is List) {
                return row.map((e) => (e as num).toDouble()).toList().cast<double>();
              }
              return <double>[];
            })
            .toList()
            .cast<List<double>>();
      }

      print('✅ PollutionHeatmap parsed: ${bounds.length} bounds, ${values.length}x${values.isNotEmpty ? values[0].length : 0} values');

      return PollutionHeatmap(
        bounds: bounds,
        values: values,
        uncertainty: uncertainty,
        resolution: json['resolution'] ?? 0,
        pollutant: json['pollutant'] ?? '',
        timestamp: json['timestamp'],
      );
    } catch (e) {
      print('❌ PollutionHeatmap.fromJson error: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
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
    try {
      print('🔍 RouteRecommendation.fromJson: JSON keys: ${json.keys}');

      // Merge segments from top level into route data
      final routeData = Map<String, dynamic>.from(json['route']);
      if (json['segments'] != null) {
        print('🔧 Adding segments from top level: ${(json['segments'] as List).length} segments');
        routeData['segments'] = json['segments'];
      }

      return RouteRecommendation(
        route: RunRoute.fromJson(routeData),
        timeWindows: (json['time_windows'] as List)
            .map((w) => TimeWindow.fromJson(w))
            .toList(),
        healthRecommendation: json['health_recommendation'],
      );
    } catch (e) {
      print('❌ RouteRecommendation.fromJson error: $e');
      print('❌ JSON data: $json');
      rethrow;
    }
  }
}