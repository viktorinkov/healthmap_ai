import 'package:json_annotation/json_annotation.dart';

part 'pinned_location.g.dart';

@JsonSerializable()
class PinnedLocation {
  final String id;
  final String name;
  final LocationType type;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime createdAt;
  final bool isActive;

  const PinnedLocation({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.createdAt,
    this.isActive = true,
  });

  factory PinnedLocation.fromJson(Map<String, dynamic> json) => _$PinnedLocationFromJson(json);
  Map<String, dynamic> toJson() => _$PinnedLocationToJson(this);
}

enum LocationType {
  @JsonValue('home')
  home,
  @JsonValue('work')
  work,
  @JsonValue('school')
  school,
  @JsonValue('gym')
  gym,
  @JsonValue('other')
  other,
}

extension LocationTypeExtension on LocationType {
  String get displayName {
    switch (this) {
      case LocationType.home:
        return 'Home';
      case LocationType.work:
        return 'Work';
      case LocationType.school:
        return 'School';
      case LocationType.gym:
        return 'Gym';
      case LocationType.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case LocationType.home:
        return '🏠';
      case LocationType.work:
        return '🏢';
      case LocationType.school:
        return '🏫';
      case LocationType.gym:
        return '🏋️';
      case LocationType.other:
        return '📍';
    }
  }
}