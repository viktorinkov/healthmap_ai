import 'package:json_annotation/json_annotation.dart';

part 'enhanced_environmental_data.g.dart';

/// Simplified wildfire information from backend (fire count only)
@JsonSerializable()
class WildfireDetails {
  final double? index; // 0-50 scale based on fire count
  final int fireCount; // Count of fires within 100km radius
  final String? source;

  const WildfireDetails({
    this.index,
    required this.fireCount,
    this.source,
  });

  factory WildfireDetails.fromJson(Map<String, dynamic> json) =>
      _$WildfireDetailsFromJson(json);
  Map<String, dynamic> toJson() => _$WildfireDetailsToJson(this);

  /// Create WildfireDetails from backend wildfire API response
  factory WildfireDetails.fromBackendResponse(Map<String, dynamic> data) {
    final fireCount = data['fireCount'] as int? ?? 0;

    // Calculate index based on fire count (simplified logic)
    double wildfireIndex = 0.0;
    if (fireCount > 0) {
      if (fireCount >= 10) {
        wildfireIndex = 40.0 + (fireCount.clamp(0, 10));  // 40-50 for many fires
      } else if (fireCount >= 5) {
        wildfireIndex = 20.0 + (fireCount.clamp(0, 20));  // 20-40 for moderate fires
      } else {
        wildfireIndex = 5.0 + (fireCount.clamp(0, 15));  // 5-20 for few fires
      }
    }

    return WildfireDetails(
      index: wildfireIndex,
      fireCount: fireCount,
      source: 'NASA FIRMS (via Backend)',
    );
  }

}

/// Enhanced air quality metrics with detailed wildfire information
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
    this.wildfireDetails,
    this.universalAqi,
  });

  factory EnhancedAirQualityMetrics.fromJson(Map<String, dynamic> json) =>
      _$EnhancedAirQualityMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$EnhancedAirQualityMetricsToJson(this);

  // Backward compatibility: get simple wildfire index
  double get wildfireIndex => wildfireDetails?.index ?? 0.0;
}