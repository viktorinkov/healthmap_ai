import 'package:json_annotation/json_annotation.dart';

part 'pollen_historical_data.g.dart';

@JsonSerializable()
class PollenHistoricalData {
  final int id;
  @JsonKey(name: 'pin_id')
  final int pinId;
  @JsonKey(name: 'tree_pollen')
  final int? treePollen;
  @JsonKey(name: 'grass_pollen')
  final int? grassPollen;
  @JsonKey(name: 'weed_pollen')
  final int? weedPollen;
  @JsonKey(name: 'overall_risk')
  final String? overallRisk;
  final DateTime timestamp;

  const PollenHistoricalData({
    required this.id,
    required this.pinId,
    this.treePollen,
    this.grassPollen,
    this.weedPollen,
    this.overallRisk,
    required this.timestamp,
  });

  factory PollenHistoricalData.fromJson(Map<String, dynamic> json) => _$PollenHistoricalDataFromJson(json);
  Map<String, dynamic> toJson() => _$PollenHistoricalDataToJson(this);

  /// Get the overall pollen index for this day (highest index among all types)
  int get overallPollenIndex {
    final values = [treePollen ?? 0, grassPollen ?? 0, weedPollen ?? 0];
    return values.reduce((a, b) => a > b ? a : b);
  }

  /// Get the dominant pollen type for this day
  String? get dominantPollenType {
    final tree = treePollen ?? 0;
    final grass = grassPollen ?? 0;
    final weed = weedPollen ?? 0;

    if (tree >= grass && tree >= weed && tree > 0) {
      return 'Tree';
    } else if (grass >= tree && grass >= weed && grass > 0) {
      return 'Grass';
    } else if (weed > 0) {
      return 'Weed';
    }
    return null;
  }
}