import 'package:json_annotation/json_annotation.dart';

part 'air_quality.g.dart';

@JsonSerializable()
class AirQualityData {
  final String id;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final AirQualityMetrics metrics;
  final AirQualityStatus status;
  final String statusReason;

  const AirQualityData({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.metrics,
    required this.status,
    required this.statusReason,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) => _$AirQualityDataFromJson(json);
  Map<String, dynamic> toJson() => _$AirQualityDataToJson(this);
}

@JsonSerializable()
class AirQualityMetrics {
  final double pm25; // PM2.5 in μg/m³
  final double pm10; // PM10 in μg/m³
  final double o3; // Ozone in ppb
  final double no2; // Nitrogen dioxide in ppb
  final double wildfireIndex; // 0-100 scale
  final double radon; // pCi/L

  const AirQualityMetrics({
    required this.pm25,
    required this.pm10,
    required this.o3,
    required this.no2,
    required this.wildfireIndex,
    required this.radon,
  });

  factory AirQualityMetrics.fromJson(Map<String, dynamic> json) => _$AirQualityMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$AirQualityMetricsToJson(this);

  double get overallScore {
    // Calculate a weighted overall score (0-100, lower is better)
    double pm25Score = (pm25 / 35.0) * 100; // EPA standard
    double pm10Score = (pm10 / 150.0) * 100; // EPA standard
    double o3Score = (o3 / 70.0) * 100; // EPA standard
    double no2Score = (no2 / 100.0) * 100; // EPA standard
    double wildfireScore = wildfireIndex;
    double radonScore = (radon / 4.0) * 100; // EPA action level

    return (pm25Score * 0.25 + pm10Score * 0.2 + o3Score * 0.2 + no2Score * 0.15 + wildfireScore * 0.1 + radonScore * 0.1).clamp(0, 100);
  }
}

enum AirQualityStatus {
  @JsonValue('good')
  good,
  @JsonValue('caution')
  caution,
  @JsonValue('avoid')
  avoid,
}

extension AirQualityStatusExtension on AirQualityStatus {
  String get displayName {
    switch (this) {
      case AirQualityStatus.good:
        return 'Good';
      case AirQualityStatus.caution:
        return 'Caution';
      case AirQualityStatus.avoid:
        return 'Avoid';
    }
  }

  static AirQualityStatus fromScore(double score) {
    if (score <= 50) return AirQualityStatus.good;
    if (score <= 75) return AirQualityStatus.caution;
    return AirQualityStatus.avoid;
  }
}