// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enhanced_environmental_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WildfireDetails _$WildfireDetailsFromJson(Map<String, dynamic> json) =>
    WildfireDetails(
      index: (json['index'] as num?)?.toDouble(),
      fireCount: (json['fireCount'] as num).toInt(),
      source: json['source'] as String?,
    );

Map<String, dynamic> _$WildfireDetailsToJson(WildfireDetails instance) =>
    <String, dynamic>{
      'index': instance.index,
      'fireCount': instance.fireCount,
      'source': instance.source,
    };

EnhancedAirQualityMetrics _$EnhancedAirQualityMetricsFromJson(
        Map<String, dynamic> json) =>
    EnhancedAirQualityMetrics(
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
      wildfireDetails: json['wildfireDetails'] == null
          ? null
          : WildfireDetails.fromJson(
              json['wildfireDetails'] as Map<String, dynamic>),
      universalAqi: (json['universalAqi'] as num?)?.toInt(),
    );

Map<String, dynamic> _$EnhancedAirQualityMetricsToJson(
        EnhancedAirQualityMetrics instance) =>
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
      'wildfireDetails': instance.wildfireDetails,
      'universalAqi': instance.universalAqi,
    };
