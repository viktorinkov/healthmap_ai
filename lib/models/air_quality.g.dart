// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'air_quality.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AirQualityData _$AirQualityDataFromJson(Map<String, dynamic> json) =>
    AirQualityData(
      id: json['id'] as String,
      locationName: json['locationName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metrics:
          AirQualityMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
      status: $enumDecode(_$AirQualityStatusEnumMap, json['status']),
      statusReason: json['statusReason'] as String,
    );

Map<String, dynamic> _$AirQualityDataToJson(AirQualityData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'locationName': instance.locationName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timestamp': instance.timestamp.toIso8601String(),
      'metrics': instance.metrics,
      'status': _$AirQualityStatusEnumMap[instance.status]!,
      'statusReason': instance.statusReason,
    };

const _$AirQualityStatusEnumMap = {
  AirQualityStatus.good: 'good',
  AirQualityStatus.caution: 'caution',
  AirQualityStatus.avoid: 'avoid',
};

AirQualityMetrics _$AirQualityMetricsFromJson(Map<String, dynamic> json) =>
    AirQualityMetrics(
      pm25: (json['pm25'] as num).toDouble(),
      pm10: (json['pm10'] as num).toDouble(),
      o3: (json['o3'] as num).toDouble(),
      no2: (json['no2'] as num).toDouble(),
      wildfireIndex: (json['wildfireIndex'] as num).toDouble(),
      radon: (json['radon'] as num).toDouble(),
    );

Map<String, dynamic> _$AirQualityMetricsToJson(AirQualityMetrics instance) =>
    <String, dynamic>{
      'pm25': instance.pm25,
      'pm10': instance.pm10,
      'o3': instance.o3,
      'no2': instance.no2,
      'wildfireIndex': instance.wildfireIndex,
      'radon': instance.radon,
    };
