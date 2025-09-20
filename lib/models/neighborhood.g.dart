// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'neighborhood.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Neighborhood _$NeighborhoodFromJson(Map<String, dynamic> json) => Neighborhood(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      zipCodes:
          (json['zipCodes'] as List<dynamic>).map((e) => e as String).toList(),
      currentAirQuality: json['currentAirQuality'] == null
          ? null
          : AirQualityData.fromJson(
              json['currentAirQuality'] as Map<String, dynamic>),
      healthScore: (json['healthScore'] as num).toDouble(),
      ranking: (json['ranking'] as num).toInt(),
    );

Map<String, dynamic> _$NeighborhoodToJson(Neighborhood instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'zipCodes': instance.zipCodes,
      'currentAirQuality': instance.currentAirQuality,
      'healthScore': instance.healthScore,
      'ranking': instance.ranking,
    };
