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
      healthRecommendations: (json['healthRecommendations'] as List<dynamic>?)
          ?.map((e) =>
              HealthRecommendationTag.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      'healthRecommendations': instance.healthRecommendations,
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
      co: (json['co'] as num?)?.toDouble(),
      so2: (json['so2'] as num?)?.toDouble(),
      nox: (json['nox'] as num?)?.toDouble(),
      no: (json['no'] as num?)?.toDouble(),
      nh3: (json['nh3'] as num?)?.toDouble(),
      c6h6: (json['c6h6'] as num?)?.toDouble(),
      ox: (json['ox'] as num?)?.toDouble(),
      nmhc: (json['nmhc'] as num?)?.toDouble(),
      trs: (json['trs'] as num?)?.toDouble(),
      wildfireIndex: (json['wildfireIndex'] as num).toDouble(),
      radon: (json['radon'] as num).toDouble(),
      universalAqi: (json['universalAqi'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AirQualityMetricsToJson(AirQualityMetrics instance) =>
    <String, dynamic>{
      'pm25': instance.pm25,
      'pm10': instance.pm10,
      'o3': instance.o3,
      'no2': instance.no2,
      'co': instance.co,
      'so2': instance.so2,
      'nox': instance.nox,
      'no': instance.no,
      'nh3': instance.nh3,
      'c6h6': instance.c6h6,
      'ox': instance.ox,
      'nmhc': instance.nmhc,
      'trs': instance.trs,
      'wildfireIndex': instance.wildfireIndex,
      'radon': instance.radon,
      'universalAqi': instance.universalAqi,
    };

HealthRecommendationTag _$HealthRecommendationTagFromJson(
        Map<String, dynamic> json) =>
    HealthRecommendationTag(
      population: $enumDecode(_$HealthPopulationEnumMap, json['population']),
      recommendation: json['recommendation'] as String,
      level: $enumDecode(_$HealthAdviceLevelEnumMap, json['level']),
    );

Map<String, dynamic> _$HealthRecommendationTagToJson(
        HealthRecommendationTag instance) =>
    <String, dynamic>{
      'population': _$HealthPopulationEnumMap[instance.population]!,
      'recommendation': instance.recommendation,
      'level': _$HealthAdviceLevelEnumMap[instance.level]!,
    };

const _$HealthPopulationEnumMap = {
  HealthPopulation.general: 'general',
  HealthPopulation.elderly: 'elderly',
  HealthPopulation.lungDisease: 'lungDisease',
  HealthPopulation.heartDisease: 'heartDisease',
  HealthPopulation.athletes: 'athletes',
  HealthPopulation.pregnantWomen: 'pregnantWomen',
  HealthPopulation.children: 'children',
};

const _$HealthAdviceLevelEnumMap = {
  HealthAdviceLevel.safe: 'safe',
  HealthAdviceLevel.caution: 'caution',
  HealthAdviceLevel.avoid: 'avoid',
};
