// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pollen_historical_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PollenHistoricalData _$PollenHistoricalDataFromJson(
        Map<String, dynamic> json) =>
    PollenHistoricalData(
      id: (json['id'] as num).toInt(),
      pinId: (json['pin_id'] as num).toInt(),
      treePollen: (json['tree_pollen'] as num?)?.toInt(),
      grassPollen: (json['grass_pollen'] as num?)?.toInt(),
      weedPollen: (json['weed_pollen'] as num?)?.toInt(),
      overallRisk: json['overall_risk'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$PollenHistoricalDataToJson(
        PollenHistoricalData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pin_id': instance.pinId,
      'tree_pollen': instance.treePollen,
      'grass_pollen': instance.grassPollen,
      'weed_pollen': instance.weedPollen,
      'overall_risk': instance.overallRisk,
      'timestamp': instance.timestamp.toIso8601String(),
    };
