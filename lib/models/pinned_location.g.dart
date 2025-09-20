// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pinned_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PinnedLocation _$PinnedLocationFromJson(Map<String, dynamic> json) =>
    PinnedLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$LocationTypeEnumMap, json['type']),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$PinnedLocationToJson(PinnedLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$LocationTypeEnumMap[instance.type]!,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'address': instance.address,
      'createdAt': instance.createdAt.toIso8601String(),
      'isActive': instance.isActive,
    };

const _$LocationTypeEnumMap = {
  LocationType.home: 'home',
  LocationType.work: 'work',
  LocationType.school: 'school',
  LocationType.gym: 'gym',
  LocationType.other: 'other',
};
