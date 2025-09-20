import 'package:json_annotation/json_annotation.dart';

part 'environmental_health_scores.g.dart';

@JsonSerializable()
class EnvironmentalHealthScores {
  final String locationId;
  final DateTime timestamp;
  final AirQualityScore airQuality;
  final IndoorEnvironmentScore indoorEnvironment;
  final AeroallergenScore aeroallergens;
  final MeteorologicalScore meteorology;
  final WildfireScore wildfire;
  final OverallEnvironmentalScore overall;

  const EnvironmentalHealthScores({
    required this.locationId,
    required this.timestamp,
    required this.airQuality,
    required this.indoorEnvironment,
    required this.aeroallergens,
    required this.meteorology,
    required this.wildfire,
    required this.overall,
  });

  factory EnvironmentalHealthScores.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentalHealthScoresFromJson(json);
  Map<String, dynamic> toJson() => _$EnvironmentalHealthScoresToJson(this);
}

@JsonSerializable()
class AirQualityScore {
  final double score; // 0-100 (lower is better)
  final ScoreLevel level;
  final double pm25;
  final double pm10;
  final double o3;
  final double no2;
  final double? co;
  final double? so2;
  final String primaryConcern;

  const AirQualityScore({
    required this.score,
    required this.level,
    required this.pm25,
    required this.pm10,
    required this.o3,
    required this.no2,
    this.co,
    this.so2,
    required this.primaryConcern,
  });

  factory AirQualityScore.fromJson(Map<String, dynamic> json) =>
      _$AirQualityScoreFromJson(json);
  Map<String, dynamic> toJson() => _$AirQualityScoreToJson(this);
}

@JsonSerializable()
class IndoorEnvironmentScore {
  final double score; // 0-100 (lower is better)
  final ScoreLevel level;
  final RadonRisk radon;
  final CombustionRisk combustion;
  final VocRisk volatileOrganicCompounds;
  final MoldRisk mold;
  final String primaryConcern;

  const IndoorEnvironmentScore({
    required this.score,
    required this.level,
    required this.radon,
    required this.combustion,
    required this.volatileOrganicCompounds,
    required this.mold,
    required this.primaryConcern,
  });

  factory IndoorEnvironmentScore.fromJson(Map<String, dynamic> json) =>
      _$IndoorEnvironmentScoreFromJson(json);
  Map<String, dynamic> toJson() => _$IndoorEnvironmentScoreToJson(this);
}

@JsonSerializable()
class AeroallergenScore {
  final double score; // 0-100 (lower is better for allergic individuals)
  final ScoreLevel level;
  final PollenLevel treePollen;
  final PollenLevel grassPollen;
  final PollenLevel weedPollen;
  final MoldSporeLevel moldSpores;
  final String dominantAllergen;

  const AeroallergenScore({
    required this.score,
    required this.level,
    required this.treePollen,
    required this.grassPollen,
    required this.weedPollen,
    required this.moldSpores,
    required this.dominantAllergen,
  });

  factory AeroallergenScore.fromJson(Map<String, dynamic> json) =>
      _$AeroallergenScoreFromJson(json);
  Map<String, dynamic> toJson() => _$AeroallergenScoreToJson(this);
}

@JsonSerializable()
class MeteorologicalScore {
  final double score; // 0-100 (lower is better)
  final ScoreLevel level;
  final TemperatureRisk temperature;
  final HumidityRisk humidity;
  final StagnationRisk airStagnation;
  final UvIndexRisk uvIndex;
  final String primaryConcern;

  const MeteorologicalScore({
    required this.score,
    required this.level,
    required this.temperature,
    required this.humidity,
    required this.airStagnation,
    required this.uvIndex,
    required this.primaryConcern,
  });

  factory MeteorologicalScore.fromJson(Map<String, dynamic> json) =>
      _$MeteorologicalScoreFromJson(json);
  Map<String, dynamic> toJson() => _$MeteorologicalScoreToJson(this);
}

@JsonSerializable()
class WildfireScore {
  final double score; // 0-100 (higher is worse)
  final ScoreLevel level;
  final double smokeConcentration; // PM2.5 from smoke specifically
  final double visibility; // km
  final int nearbyFireCount;
  final double? closestFireDistance; // km
  final String riskDescription;

  const WildfireScore({
    required this.score,
    required this.level,
    required this.smokeConcentration,
    required this.visibility,
    required this.nearbyFireCount,
    this.closestFireDistance,
    required this.riskDescription,
  });

  factory WildfireScore.fromJson(Map<String, dynamic> json) =>
      _$WildfireScoreFromJson(json);
  Map<String, dynamic> toJson() => _$WildfireScoreToJson(this);
}

@JsonSerializable()
class OverallEnvironmentalScore {
  final double score; // 0-100 (lower is better)
  final ScoreLevel level;
  final List<String> primaryConcerns;
  final List<String> recommendations;
  final bool safeForOutdoorActivity;
  final bool safeForExercise;
  final bool windowsRecommendation; // true = keep open, false = keep closed

  const OverallEnvironmentalScore({
    required this.score,
    required this.level,
    required this.primaryConcerns,
    required this.recommendations,
    required this.safeForOutdoorActivity,
    required this.safeForExercise,
    required this.windowsRecommendation,
  });

  factory OverallEnvironmentalScore.fromJson(Map<String, dynamic> json) =>
      _$OverallEnvironmentalScoreFromJson(json);
  Map<String, dynamic> toJson() => _$OverallEnvironmentalScoreToJson(this);
}

// Supporting classes for specific risk assessments

@JsonSerializable()
class RadonRisk {
  final double level; // pCi/L
  final ScoreLevel risk;
  final bool requiresTesting;
  final String recommendation;

  const RadonRisk({
    required this.level,
    required this.risk,
    required this.requiresTesting,
    required this.recommendation,
  });

  factory RadonRisk.fromJson(Map<String, dynamic> json) => _$RadonRiskFromJson(json);
  Map<String, dynamic> toJson() => _$RadonRiskToJson(this);
}

@JsonSerializable()
class CombustionRisk {
  final ScoreLevel risk;
  final bool gasStovePresent;
  final bool fireplaceFactor;
  final bool vehicleExposure;
  final String recommendation;

  const CombustionRisk({
    required this.risk,
    required this.gasStovePresent,
    required this.fireplaceFactor,
    required this.vehicleExposure,
    required this.recommendation,
  });

  factory CombustionRisk.fromJson(Map<String, dynamic> json) => _$CombustionRiskFromJson(json);
  Map<String, dynamic> toJson() => _$CombustionRiskToJson(this);
}

@JsonSerializable()
class VocRisk {
  final ScoreLevel risk;
  final bool cleaningProducts;
  final bool newFurniture;
  final bool paintFumes;
  final String recommendation;

  const VocRisk({
    required this.risk,
    required this.cleaningProducts,
    required this.newFurniture,
    required this.paintFumes,
    required this.recommendation,
  });

  factory VocRisk.fromJson(Map<String, dynamic> json) => _$VocRiskFromJson(json);
  Map<String, dynamic> toJson() => _$VocRiskToJson(this);
}

@JsonSerializable()
class MoldRisk {
  final ScoreLevel risk;
  final bool highHumidity;
  final bool waterDamage;
  final bool poorVentilation;
  final String recommendation;

  const MoldRisk({
    required this.risk,
    required this.highHumidity,
    required this.waterDamage,
    required this.poorVentilation,
    required this.recommendation,
  });

  factory MoldRisk.fromJson(Map<String, dynamic> json) => _$MoldRiskFromJson(json);
  Map<String, dynamic> toJson() => _$MoldRiskToJson(this);
}

@JsonSerializable()
class PollenLevel {
  final int count; // grains per cubic meter
  final ScoreLevel level;
  final List<String> dominantTypes;

  const PollenLevel({
    required this.count,
    required this.level,
    required this.dominantTypes,
  });

  factory PollenLevel.fromJson(Map<String, dynamic> json) => _$PollenLevelFromJson(json);
  Map<String, dynamic> toJson() => _$PollenLevelToJson(this);
}

@JsonSerializable()
class MoldSporeLevel {
  final int count; // spores per cubic meter
  final ScoreLevel level;
  final List<String> dominantTypes;

  const MoldSporeLevel({
    required this.count,
    required this.level,
    required this.dominantTypes,
  });

  factory MoldSporeLevel.fromJson(Map<String, dynamic> json) => _$MoldSporeLevelFromJson(json);
  Map<String, dynamic> toJson() => _$MoldSporeLevelToJson(this);
}

@JsonSerializable()
class TemperatureRisk {
  final double celsius;
  final double fahrenheit;
  final ScoreLevel heatRisk;
  final ScoreLevel coldRisk;
  final bool extremeTemperature;
  final String recommendation;

  const TemperatureRisk({
    required this.celsius,
    required this.fahrenheit,
    required this.heatRisk,
    required this.coldRisk,
    required this.extremeTemperature,
    required this.recommendation,
  });

  factory TemperatureRisk.fromJson(Map<String, dynamic> json) => _$TemperatureRiskFromJson(json);
  Map<String, dynamic> toJson() => _$TemperatureRiskToJson(this);
}

@JsonSerializable()
class HumidityRisk {
  final double relativeHumidity; // percentage
  final ScoreLevel comfortRisk;
  final bool moldRisk;
  final bool dryAirRisk;
  final String recommendation;

  const HumidityRisk({
    required this.relativeHumidity,
    required this.comfortRisk,
    required this.moldRisk,
    required this.dryAirRisk,
    required this.recommendation,
  });

  factory HumidityRisk.fromJson(Map<String, dynamic> json) => _$HumidityRiskFromJson(json);
  Map<String, dynamic> toJson() => _$HumidityRiskToJson(this);
}

@JsonSerializable()
class StagnationRisk {
  final ScoreLevel level;
  final double windSpeed; // m/s
  final bool inversionPresent;
  final int stagnantDays;
  final String description;

  const StagnationRisk({
    required this.level,
    required this.windSpeed,
    required this.inversionPresent,
    required this.stagnantDays,
    required this.description,
  });

  factory StagnationRisk.fromJson(Map<String, dynamic> json) => _$StagnationRiskFromJson(json);
  Map<String, dynamic> toJson() => _$StagnationRiskToJson(this);
}

@JsonSerializable()
class UvIndexRisk {
  final int uvIndex; // 0-11+
  final ScoreLevel risk;
  final String recommendation;
  final bool sunscreenRequired;

  const UvIndexRisk({
    required this.uvIndex,
    required this.risk,
    required this.recommendation,
    required this.sunscreenRequired,
  });

  factory UvIndexRisk.fromJson(Map<String, dynamic> json) => _$UvIndexRiskFromJson(json);
  Map<String, dynamic> toJson() => _$UvIndexRiskToJson(this);
}

// Enums

enum ScoreLevel {
  @JsonValue('excellent')
  excellent,   // 0-20
  @JsonValue('good')
  good,        // 21-40
  @JsonValue('moderate')
  moderate,    // 41-60
  @JsonValue('poor')
  poor,        // 61-80
  @JsonValue('hazardous')
  hazardous,   // 81-100
}

extension ScoreLevelExtension on ScoreLevel {
  String get displayName {
    switch (this) {
      case ScoreLevel.excellent:
        return 'Excellent';
      case ScoreLevel.good:
        return 'Good';
      case ScoreLevel.moderate:
        return 'Moderate';
      case ScoreLevel.poor:
        return 'Poor';
      case ScoreLevel.hazardous:
        return 'Hazardous';
    }
  }

  String get icon {
    switch (this) {
      case ScoreLevel.excellent:
        return '🟢';
      case ScoreLevel.good:
        return '🟡';
      case ScoreLevel.moderate:
        return '🟠';
      case ScoreLevel.poor:
        return '🔴';
      case ScoreLevel.hazardous:
        return '🟣';
    }
  }

  static ScoreLevel fromScore(double score) {
    if (score <= 20) return ScoreLevel.excellent;
    if (score <= 40) return ScoreLevel.good;
    if (score <= 60) return ScoreLevel.moderate;
    if (score <= 80) return ScoreLevel.poor;
    return ScoreLevel.hazardous;
  }
}