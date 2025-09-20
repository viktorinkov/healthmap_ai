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
  final List<HealthRecommendationTag>? healthRecommendations;

  const AirQualityData({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.metrics,
    required this.status,
    required this.statusReason,
    this.healthRecommendations,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) => _$AirQualityDataFromJson(json);
  Map<String, dynamic> toJson() => _$AirQualityDataToJson(this);
}

@JsonSerializable()
class AirQualityMetrics {
  // Core pollutants (always present)
  final double pm25; // PM2.5 in μg/m³
  final double pm10; // PM10 in μg/m³
  final double o3; // Ozone in ppb
  final double no2; // Nitrogen dioxide in ppb

  // Additional Google Maps pollutants (optional)
  final double? co; // Carbon monoxide in ppb
  final double? so2; // Sulfur dioxide in ppb
  final double? nox; // Nitrogen oxides in ppb
  final double? no; // Nitrogen monoxide in ppb
  final double? nh3; // Ammonia in ppb
  final double? c6h6; // Benzene in μg/m³
  final double? ox; // Photochemical oxidants in ppb
  final double? nmhc; // Non-methane hydrocarbons in ppb
  final double? trs; // Total reduced sulfur in μg/m³

  // Additional metrics
  final double wildfireIndex; // 0-100 scale
  final double radon; // pCi/L
  final int? universalAqi; // Universal Air Quality Index (0-500)

  const AirQualityMetrics({
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
    required this.wildfireIndex,
    required this.radon,
    this.universalAqi,
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

@JsonSerializable()
class HealthRecommendationTag {
  final HealthPopulation population;
  final String recommendation;
  final HealthAdviceLevel level;

  const HealthRecommendationTag({
    required this.population,
    required this.recommendation,
    required this.level,
  });

  factory HealthRecommendationTag.fromJson(Map<String, dynamic> json) => _$HealthRecommendationTagFromJson(json);
  Map<String, dynamic> toJson() => _$HealthRecommendationTagToJson(this);
}

enum HealthPopulation {
  @JsonValue('general')
  general,
  @JsonValue('elderly')
  elderly,
  @JsonValue('lungDisease')
  lungDisease,
  @JsonValue('heartDisease')
  heartDisease,
  @JsonValue('athletes')
  athletes,
  @JsonValue('pregnantWomen')
  pregnantWomen,
  @JsonValue('children')
  children,
}

enum HealthAdviceLevel {
  @JsonValue('safe')
  safe,
  @JsonValue('caution')
  caution,
  @JsonValue('avoid')
  avoid,
}

extension HealthPopulationExtension on HealthPopulation {
  String get displayName {
    switch (this) {
      case HealthPopulation.general:
        return 'General Population';
      case HealthPopulation.elderly:
        return 'Elderly';
      case HealthPopulation.lungDisease:
        return 'Lung Diseases';
      case HealthPopulation.heartDisease:
        return 'Heart Diseases';
      case HealthPopulation.athletes:
        return 'Athletes';
      case HealthPopulation.pregnantWomen:
        return 'Pregnant Women';
      case HealthPopulation.children:
        return 'Children';
    }
  }

  String get icon {
    switch (this) {
      case HealthPopulation.general:
        return '👥';
      case HealthPopulation.elderly:
        return '👴';
      case HealthPopulation.lungDisease:
        return '🫁';
      case HealthPopulation.heartDisease:
        return '❤️';
      case HealthPopulation.athletes:
        return '🏃';
      case HealthPopulation.pregnantWomen:
        return '🤱';
      case HealthPopulation.children:
        return '👶';
    }
  }
}