import 'package:json_annotation/json_annotation.dart';
import 'air_quality.dart';

part 'neighborhood.g.dart';

@JsonSerializable()
class Neighborhood {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final List<String> zipCodes;
  final AirQualityData? currentAirQuality;
  final double healthScore; // 0-100, higher is better
  final int ranking; // 1-based ranking among all neighborhoods

  const Neighborhood({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.zipCodes,
    this.currentAirQuality,
    required this.healthScore,
    required this.ranking,
  });

  factory Neighborhood.fromJson(Map<String, dynamic> json) => _$NeighborhoodFromJson(json);
  Map<String, dynamic> toJson() => _$NeighborhoodToJson(this);

  AirQualityStatus get status {
    if (currentAirQuality != null) {
      return currentAirQuality!.status;
    }
    return AirQualityStatusExtension.fromScore(100 - healthScore);
  }

  String get statusReason {
    if (currentAirQuality != null) {
      return currentAirQuality!.statusReason;
    }
    if (healthScore >= 80) {
      return "Excellent air quality with minimal health risks";
    } else if (healthScore >= 60) {
      return "Good air quality suitable for most activities";
    } else if (healthScore >= 40) {
      return "Moderate air quality, sensitive individuals should limit outdoor activities";
    } else {
      return "Poor air quality, avoid prolonged outdoor exposure";
    }
  }
}