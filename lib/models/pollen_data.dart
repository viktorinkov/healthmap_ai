import 'package:flutter/material.dart' as flutter;
import 'package:json_annotation/json_annotation.dart';

part 'pollen_data.g.dart';

@JsonSerializable()
class PollenForecast {
  final String regionCode;
  final List<PollenDailyInfo> dailyInfo;

  const PollenForecast({
    required this.regionCode,
    required this.dailyInfo,
  });

  factory PollenForecast.fromJson(Map<String, dynamic> json) => _$PollenForecastFromJson(json);
  Map<String, dynamic> toJson() => _$PollenForecastToJson(this);
}

@JsonSerializable()
class PollenDailyInfo {
  final DateTime date;
  final List<PollenTypeInfo> pollenTypeInfo;
  final List<PlantInfo> plantInfo;

  const PollenDailyInfo({
    required this.date,
    required this.pollenTypeInfo,
    required this.plantInfo,
  });

  factory PollenDailyInfo.fromJson(Map<String, dynamic> json) => _$PollenDailyInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PollenDailyInfoToJson(this);

  /// Get the overall pollen index for this day (highest index among all types)
  int get overallPollenIndex {
    if (pollenTypeInfo.isEmpty) return 0;
    return pollenTypeInfo.map((info) => info.indexInfo?.value ?? 0).reduce((a, b) => a > b ? a : b);
  }

  /// Get the dominant pollen type for this day
  PollenType? get dominantPollenType {
    if (pollenTypeInfo.isEmpty) return null;

    final sortedTypes = pollenTypeInfo.toList()..sort((a, b) => (b.indexInfo?.value ?? 0).compareTo(a.indexInfo?.value ?? 0));
    return sortedTypes.first.code;
  }
}

@JsonSerializable()
class PollenTypeInfo {
  final PollenType code;
  final String displayName;
  final bool inSeason;
  final PollenIndexInfo? indexInfo;
  final PollenHealthRecommendation? healthRecommendation;

  const PollenTypeInfo({
    required this.code,
    required this.displayName,
    required this.inSeason,
    this.indexInfo,
    this.healthRecommendation,
  });

  factory PollenTypeInfo.fromJson(Map<String, dynamic> json) => _$PollenTypeInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PollenTypeInfoToJson(this);
}

@JsonSerializable()
class PollenIndexInfo {
  final int value;
  final PollenIndexCategory category;
  final String indexDescription;
  final Color? color;

  const PollenIndexInfo({
    required this.value,
    required this.category,
    required this.indexDescription,
    this.color,
  });

  factory PollenIndexInfo.fromJson(Map<String, dynamic> json) => _$PollenIndexInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PollenIndexInfoToJson(this);
}

@JsonSerializable()
class Color {
  final double red;
  final double green;
  final double blue;
  final double? alpha;

  const Color({
    required this.red,
    required this.green,
    required this.blue,
    this.alpha,
  });

  factory Color.fromJson(Map<String, dynamic> json) => _$ColorFromJson(json);
  Map<String, dynamic> toJson() => _$ColorToJson(this);

  /// Convert to Flutter Color
  flutter.Color toFlutterColor() {
    return flutter.Color.fromRGBO(
      (red * 255).round(),
      (green * 255).round(),
      (blue * 255).round(),
      alpha ?? 1.0,
    );
  }
}

@JsonSerializable()
class PollenHealthRecommendation {
  final String generalPopulation;
  final String? elderly;
  final String? lungDiseaseAtRisk;
  final String? heartDiseaseAtRisk;
  final String? athletes;
  final String? pregnantWomen;
  final String? children;

  const PollenHealthRecommendation({
    required this.generalPopulation,
    this.elderly,
    this.lungDiseaseAtRisk,
    this.heartDiseaseAtRisk,
    this.athletes,
    this.pregnantWomen,
    this.children,
  });

  factory PollenHealthRecommendation.fromJson(Map<String, dynamic> json) => _$PollenHealthRecommendationFromJson(json);
  Map<String, dynamic> toJson() => _$PollenHealthRecommendationToJson(this);
}

@JsonSerializable()
class PlantInfo {
  final PlantType code;
  final String displayName;
  final bool inSeason;
  final PollenIndexInfo? indexInfo;
  final PlantDescription? plantDescription;

  const PlantInfo({
    required this.code,
    required this.displayName,
    required this.inSeason,
    this.indexInfo,
    this.plantDescription,
  });

  factory PlantInfo.fromJson(Map<String, dynamic> json) => _$PlantInfoFromJson(json);
  Map<String, dynamic> toJson() => _$PlantInfoToJson(this);
}

@JsonSerializable()
class PlantDescription {
  final String? type;
  final String? family;
  final String? season;
  final String? specialShapes;
  final String? specialColors;
  final String? crossReaction;
  final String? picture;
  final String? pictureCloseup;

  const PlantDescription({
    this.type,
    this.family,
    this.season,
    this.specialShapes,
    this.specialColors,
    this.crossReaction,
    this.picture,
    this.pictureCloseup,
  });

  factory PlantDescription.fromJson(Map<String, dynamic> json) => _$PlantDescriptionFromJson(json);
  Map<String, dynamic> toJson() => _$PlantDescriptionToJson(this);
}

enum PollenType {
  @JsonValue('GRASS')
  grass,
  @JsonValue('TREE')
  tree,
  @JsonValue('WEED')
  weed,
}

enum PlantType {
  @JsonValue('ALDER')
  alder,
  @JsonValue('BIRCH')
  birch,
  @JsonValue('CYPRESS')
  cypress,
  @JsonValue('ELM')
  elm,
  @JsonValue('HAZEL')
  hazel,
  @JsonValue('OAK')
  oak,
  @JsonValue('PINE')
  pine,
  @JsonValue('PLANE')
  plane,
  @JsonValue('POPLAR')
  poplar,
  @JsonValue('ASH')
  ash,
  @JsonValue('COTTONWOOD')
  cottonwood,
  @JsonValue('GRAMINALES')
  graminales,
  @JsonValue('RAGWEED')
  ragweed,
  @JsonValue('MUGWORT')
  mugwort,
  @JsonValue('OLIVE')
  olive,
  @JsonValue('JUNIPER')
  juniper,
  @JsonValue('CHENOPOD')
  chenopod,
}

enum PollenIndexCategory {
  @JsonValue('UPI_CATEGORY_0')
  none,
  @JsonValue('UPI_CATEGORY_1')
  veryLow,
  @JsonValue('UPI_CATEGORY_2')
  low,
  @JsonValue('UPI_CATEGORY_3')
  moderate,
  @JsonValue('UPI_CATEGORY_4')
  high,
  @JsonValue('UPI_CATEGORY_5')
  veryHigh,
}

extension PollenTypeExtension on PollenType {
  String get displayName {
    switch (this) {
      case PollenType.grass:
        return 'Grass';
      case PollenType.tree:
        return 'Tree';
      case PollenType.weed:
        return 'Weed';
    }
  }

  String get icon {
    switch (this) {
      case PollenType.grass:
        return '🌾';
      case PollenType.tree:
        return '🌳';
      case PollenType.weed:
        return '🌿';
    }
  }
}

extension PlantTypeExtension on PlantType {
  String get displayName {
    switch (this) {
      case PlantType.alder:
        return 'Alder';
      case PlantType.birch:
        return 'Birch';
      case PlantType.cypress:
        return 'Cypress';
      case PlantType.elm:
        return 'Elm';
      case PlantType.hazel:
        return 'Hazel';
      case PlantType.oak:
        return 'Oak';
      case PlantType.pine:
        return 'Pine';
      case PlantType.plane:
        return 'Plane';
      case PlantType.poplar:
        return 'Poplar';
      case PlantType.ash:
        return 'Ash';
      case PlantType.cottonwood:
        return 'Cottonwood';
      case PlantType.graminales:
        return 'Graminales';
      case PlantType.ragweed:
        return 'Ragweed';
      case PlantType.mugwort:
        return 'Mugwort';
      case PlantType.olive:
        return 'Olive';
      case PlantType.juniper:
        return 'Juniper';
      case PlantType.chenopod:
        return 'Chenopod';
    }
  }
}

extension PollenIndexCategoryExtension on PollenIndexCategory {
  String get displayName {
    switch (this) {
      case PollenIndexCategory.none:
        return 'None';
      case PollenIndexCategory.veryLow:
        return 'Very Low';
      case PollenIndexCategory.low:
        return 'Low';
      case PollenIndexCategory.moderate:
        return 'Moderate';
      case PollenIndexCategory.high:
        return 'High';
      case PollenIndexCategory.veryHigh:
        return 'Very High';
    }
  }

  flutter.Color get color {
    switch (this) {
      case PollenIndexCategory.none:
        return flutter.Colors.grey;
      case PollenIndexCategory.veryLow:
        return flutter.Colors.green;
      case PollenIndexCategory.low:
        return flutter.Colors.lightGreen;
      case PollenIndexCategory.moderate:
        return flutter.Colors.yellow;
      case PollenIndexCategory.high:
        return flutter.Colors.orange;
      case PollenIndexCategory.veryHigh:
        return flutter.Colors.red;
    }
  }
}

