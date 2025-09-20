import 'package:json_annotation/json_annotation.dart';

part 'enhanced_environmental_data.g.dart';

/// Enhanced data structure for detailed radon information from backend
@JsonSerializable()
class RadonDetails {
  final double? level; // pCi/L
  final String? riskLevel; // 'Low', 'Moderate', 'High'
  final int? epaZone; // 1, 2, 3
  final String? zoneDescription;
  final String? recommendation;
  final String? source;

  const RadonDetails({
    this.level,
    this.riskLevel,
    this.epaZone,
    this.zoneDescription,
    this.recommendation,
    this.source,
  });

  factory RadonDetails.fromJson(Map<String, dynamic> json) =>
      _$RadonDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$RadonDetailsToJson(this);

  /// Create RadonDetails from backend radon API response
  factory RadonDetails.fromBackendResponse(Map<String, dynamic> data) {
    double? radonLevel;
    final radonValue = data['averageRadonLevel'];
    
    if (radonValue is num) {
      radonLevel = radonValue.toDouble();
    } else if (radonValue is String && radonValue != 'N/A') {
      try {
        radonLevel = double.parse(radonValue);
      } catch (e) {
        radonLevel = null;
      }
    }

    return RadonDetails(
      level: radonLevel,
      riskLevel: data['radonRisk'] != 'N/A' ? data['radonRisk'] : null,
      epaZone: data['radonZone'] != 'N/A' ? data['radonZone'] : null,
      zoneDescription: data['description'] != 'N/A' ? data['description'] : null,
      recommendation: data['recommendation'] != 'N/A' ? data['recommendation'] : null,
      source: data['source'] != 'N/A' ? data['source'] : null,
    );
  }
}

/// Enhanced data structure for detailed wildfire information from backend
@JsonSerializable()
class WildfireDetails {
  final double? index; // 0-100 scale
  final int? nearbyFires; // Count of fires within radius
  final double? closestFireDistanceKm;
  final String? riskLevel; // 'Low', 'Moderate', 'High', 'Critical'
  final String? smokeImpact; // 'Light', 'Moderate', 'Heavy', 'Severe'
  final String? airQualityImpact;
  final List<String>? recommendations;
  final String? source;

  const WildfireDetails({
    this.index,
    this.nearbyFires,
    this.closestFireDistanceKm,
    this.riskLevel,
    this.smokeImpact,
    this.airQualityImpact,
    this.recommendations,
    this.source,
  });

  factory WildfireDetails.fromJson(Map<String, dynamic> json) =>
      _$WildfireDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$WildfireDetailsToJson(this);

  /// Create WildfireDetails from backend wildfire API response
  factory WildfireDetails.fromBackendResponse(Map<String, dynamic> data) {
    final nearbyFires = data['nearbyFires'] as int? ?? 0;
    final closestDistance = (data['closestFireDistance'] as num?)?.toDouble();
    
    // Calculate index based on distance and fire count (same logic as air_quality_api_service.dart)
    double wildfireIndex = 0.0;
    if (closestDistance != null) {
      if (closestDistance <= 10) {
        wildfireIndex = 90.0 + (nearbyFires.clamp(0, 10));
      } else if (closestDistance <= 25) {
        wildfireIndex = 60.0 + (nearbyFires.clamp(0, 20));
      } else if (closestDistance <= 50) {
        wildfireIndex = 30.0 + (nearbyFires.clamp(0, 20));
      } else if (closestDistance <= 100) {
        wildfireIndex = 10.0 + (nearbyFires.clamp(0, 10));
      } else {
        wildfireIndex = nearbyFires.clamp(0, 10).toDouble();
      }
    }

    // Determine risk level based on index
    String riskLevel = 'Low';
    String smokeImpact = 'Light';
    String airQualityImpact = 'No significant impact expected';
    
    if (wildfireIndex >= 90) {
      riskLevel = 'Critical';
      smokeImpact = 'Severe';
      airQualityImpact = 'Very unhealthy air quality likely';
    } else if (wildfireIndex >= 60) {
      riskLevel = 'High';
      smokeImpact = 'Heavy';
      airQualityImpact = 'Unhealthy air quality expected';
    } else if (wildfireIndex >= 30) {
      riskLevel = 'Moderate';
      smokeImpact = 'Moderate';
      airQualityImpact = 'Air quality may be affected';
    }

    return WildfireDetails(
      index: wildfireIndex,
      nearbyFires: nearbyFires,
      closestFireDistanceKm: closestDistance,
      riskLevel: riskLevel,
      smokeImpact: smokeImpact,
      airQualityImpact: airQualityImpact,
      recommendations: _getWildfireRecommendations(riskLevel),
      source: 'NASA FIRMS (via Backend)',
    );
  }

  static List<String> _getWildfireRecommendations(String riskLevel) {
    switch (riskLevel) {
      case 'Critical':
        return [
          'Immediate evacuation may be necessary',
          'Stay indoors with windows closed',
          'Use air purifiers if available',
        ];
      case 'High':
        return [
          'Avoid outdoor activities',
          'Keep windows closed',
          'Monitor evacuation alerts',
        ];
      case 'Moderate':
        return [
          'Limit outdoor activities for sensitive groups',
          'Monitor air quality conditions',
        ];
      default:
        return [
          'Monitor wildfire conditions',
          'Be prepared for changing conditions',
        ];
    }
  }
}

/// Enhanced air quality metrics with detailed radon and wildfire information
@JsonSerializable()
class EnhancedAirQualityMetrics {
  // Core pollutants (always present)
  final double pm25;
  final double pm10;
  final double o3;
  final double no2;

  // Additional pollutants (optional)
  final double? co;
  final double? so2;
  final double? nox;
  final double? no;
  final double? nh3;
  final double? c6h6;
  final double? ox;
  final double? nmhc;
  final double? trs;

  // Enhanced environmental data
  final RadonDetails? radonDetails;
  final WildfireDetails? wildfireDetails;
  final int? universalAqi;

  const EnhancedAirQualityMetrics({
    required this.pm25,
    required this.pm10,
    required this.o3,
    required this.no2,
    this.co,
    this.so2,
    this.nox,
    this.no,
    this.nh3,
    this.c6h6,
    this.ox,
    this.nmhc,
    this.trs,
    this.radonDetails,
    this.wildfireDetails,
    this.universalAqi,
  });

  factory EnhancedAirQualityMetrics.fromJson(Map<String, dynamic> json) =>
      _$EnhancedAirQualityMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$EnhancedAirQualityMetricsToJson(this);

  // Backward compatibility: get simple radon level
  double get radon => radonDetails?.level ?? 0.0;

  // Backward compatibility: get simple wildfire index
  double get wildfireIndex => wildfireDetails?.index ?? 0.0;
}