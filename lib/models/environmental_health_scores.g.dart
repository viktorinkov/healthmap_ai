// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environmental_health_scores.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvironmentalHealthScores _$EnvironmentalHealthScoresFromJson(
        Map<String, dynamic> json) =>
    EnvironmentalHealthScores(
      locationId: json['locationId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      airQuality:
          AirQualityScore.fromJson(json['airQuality'] as Map<String, dynamic>),
      indoorEnvironment: IndoorEnvironmentScore.fromJson(
          json['indoorEnvironment'] as Map<String, dynamic>),
      aeroallergens: AeroallergenScore.fromJson(
          json['aeroallergens'] as Map<String, dynamic>),
      meteorology: MeteorologicalScore.fromJson(
          json['meteorology'] as Map<String, dynamic>),
      wildfire:
          WildfireScore.fromJson(json['wildfire'] as Map<String, dynamic>),
      overall: OverallEnvironmentalScore.fromJson(
          json['overall'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EnvironmentalHealthScoresToJson(
        EnvironmentalHealthScores instance) =>
    <String, dynamic>{
      'locationId': instance.locationId,
      'timestamp': instance.timestamp.toIso8601String(),
      'airQuality': instance.airQuality,
      'indoorEnvironment': instance.indoorEnvironment,
      'aeroallergens': instance.aeroallergens,
      'meteorology': instance.meteorology,
      'wildfire': instance.wildfire,
      'overall': instance.overall,
    };

AirQualityScore _$AirQualityScoreFromJson(Map<String, dynamic> json) =>
    AirQualityScore(
      score: (json['score'] as num).toDouble(),
      level: $enumDecode(_$ScoreLevelEnumMap, json['level']),
      pm25: (json['pm25'] as num).toDouble(),
      pm10: (json['pm10'] as num).toDouble(),
      o3: (json['o3'] as num).toDouble(),
      no2: (json['no2'] as num).toDouble(),
      co: (json['co'] as num?)?.toDouble(),
      so2: (json['so2'] as num?)?.toDouble(),
      primaryConcern: json['primaryConcern'] as String,
    );

Map<String, dynamic> _$AirQualityScoreToJson(AirQualityScore instance) =>
    <String, dynamic>{
      'score': instance.score,
      'level': _$ScoreLevelEnumMap[instance.level]!,
      'pm25': instance.pm25,
      'pm10': instance.pm10,
      'o3': instance.o3,
      'no2': instance.no2,
      'co': instance.co,
      'so2': instance.so2,
      'primaryConcern': instance.primaryConcern,
    };

const _$ScoreLevelEnumMap = {
  ScoreLevel.excellent: 'excellent',
  ScoreLevel.good: 'good',
  ScoreLevel.moderate: 'moderate',
  ScoreLevel.poor: 'poor',
  ScoreLevel.hazardous: 'hazardous',
};

IndoorEnvironmentScore _$IndoorEnvironmentScoreFromJson(
        Map<String, dynamic> json) =>
    IndoorEnvironmentScore(
      score: (json['score'] as num).toDouble(),
      level: $enumDecode(_$ScoreLevelEnumMap, json['level']),
      radon: RadonRisk.fromJson(json['radon'] as Map<String, dynamic>),
      combustion:
          CombustionRisk.fromJson(json['combustion'] as Map<String, dynamic>),
      volatileOrganicCompounds: VocRisk.fromJson(
          json['volatileOrganicCompounds'] as Map<String, dynamic>),
      mold: MoldRisk.fromJson(json['mold'] as Map<String, dynamic>),
      primaryConcern: json['primaryConcern'] as String,
    );

Map<String, dynamic> _$IndoorEnvironmentScoreToJson(
        IndoorEnvironmentScore instance) =>
    <String, dynamic>{
      'score': instance.score,
      'level': _$ScoreLevelEnumMap[instance.level]!,
      'radon': instance.radon,
      'combustion': instance.combustion,
      'volatileOrganicCompounds': instance.volatileOrganicCompounds,
      'mold': instance.mold,
      'primaryConcern': instance.primaryConcern,
    };

AeroallergenScore _$AeroallergenScoreFromJson(Map<String, dynamic> json) =>
    AeroallergenScore(
      score: (json['score'] as num).toDouble(),
      level: $enumDecode(_$ScoreLevelEnumMap, json['level']),
      treePollen:
          PollenLevel.fromJson(json['treePollen'] as Map<String, dynamic>),
      grassPollen:
          PollenLevel.fromJson(json['grassPollen'] as Map<String, dynamic>),
      weedPollen:
          PollenLevel.fromJson(json['weedPollen'] as Map<String, dynamic>),
      moldSpores:
          MoldSporeLevel.fromJson(json['moldSpores'] as Map<String, dynamic>),
      dominantAllergen: json['dominantAllergen'] as String,
    );

Map<String, dynamic> _$AeroallergenScoreToJson(AeroallergenScore instance) =>
    <String, dynamic>{
      'score': instance.score,
      'level': _$ScoreLevelEnumMap[instance.level]!,
      'treePollen': instance.treePollen,
      'grassPollen': instance.grassPollen,
      'weedPollen': instance.weedPollen,
      'moldSpores': instance.moldSpores,
      'dominantAllergen': instance.dominantAllergen,
    };

MeteorologicalScore _$MeteorologicalScoreFromJson(Map<String, dynamic> json) =>
    MeteorologicalScore(
      score: (json['score'] as num).toDouble(),
      level: $enumDecode(_$ScoreLevelEnumMap, json['level']),
      temperature:
          TemperatureRisk.fromJson(json['temperature'] as Map<String, dynamic>),
      humidity: HumidityRisk.fromJson(json['humidity'] as Map<String, dynamic>),
      airStagnation: StagnationRisk.fromJson(
          json['airStagnation'] as Map<String, dynamic>),
      uvIndex: UvIndexRisk.fromJson(json['uvIndex'] as Map<String, dynamic>),
      primaryConcern: json['primaryConcern'] as String,
    );

Map<String, dynamic> _$MeteorologicalScoreToJson(
        MeteorologicalScore instance) =>
    <String, dynamic>{
      'score': instance.score,
      'level': _$ScoreLevelEnumMap[instance.level]!,
      'temperature': instance.temperature,
      'humidity': instance.humidity,
      'airStagnation': instance.airStagnation,
      'uvIndex': instance.uvIndex,
      'primaryConcern': instance.primaryConcern,
    };

WildfireScore _$WildfireScoreFromJson(Map<String, dynamic> json) =>
    WildfireScore(
      score: (json['score'] as num).toDouble(),
      level: $enumDecode(_$ScoreLevelEnumMap, json['level']),
      smokeConcentration: (json['smokeConcentration'] as num).toDouble(),
      visibility: (json['visibility'] as num).toDouble(),
      nearbyFireCount: (json['nearbyFireCount'] as num).toInt(),
      closestFireDistance: (json['closestFireDistance'] as num?)?.toDouble(),
      riskDescription: json['riskDescription'] as String,
    );

Map<String, dynamic> _$WildfireScoreToJson(WildfireScore instance) =>
    <String, dynamic>{
      'score': instance.score,
      'level': _$ScoreLevelEnumMap[instance.level]!,
      'smokeConcentration': instance.smokeConcentration,
      'visibility': instance.visibility,
      'nearbyFireCount': instance.nearbyFireCount,
      'closestFireDistance': instance.closestFireDistance,
      'riskDescription': instance.riskDescription,
    };

OverallEnvironmentalScore _$OverallEnvironmentalScoreFromJson(
        Map<String, dynamic> json) =>
    OverallEnvironmentalScore(
      score: (json['score'] as num).toDouble(),
      level: $enumDecode(_$ScoreLevelEnumMap, json['level']),
      primaryConcerns: (json['primaryConcerns'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      recommendations: (json['recommendations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      safeForOutdoorActivity: json['safeForOutdoorActivity'] as bool,
      safeForExercise: json['safeForExercise'] as bool,
      windowsRecommendation: json['windowsRecommendation'] as bool,
    );

Map<String, dynamic> _$OverallEnvironmentalScoreToJson(
        OverallEnvironmentalScore instance) =>
    <String, dynamic>{
      'score': instance.score,
      'level': _$ScoreLevelEnumMap[instance.level]!,
      'primaryConcerns': instance.primaryConcerns,
      'recommendations': instance.recommendations,
      'safeForOutdoorActivity': instance.safeForOutdoorActivity,
      'safeForExercise': instance.safeForExercise,
      'windowsRecommendation': instance.windowsRecommendation,
    };

RadonRisk _$RadonRiskFromJson(Map<String, dynamic> json) => RadonRisk(
      level: (json['level'] as num).toDouble(),
      risk: $enumDecode(_$ScoreLevelEnumMap, json['risk']),
      requiresTesting: json['requiresTesting'] as bool,
      recommendation: json['recommendation'] as String,
    );

Map<String, dynamic> _$RadonRiskToJson(RadonRisk instance) => <String, dynamic>{
      'level': instance.level,
      'risk': _$ScoreLevelEnumMap[instance.risk]!,
      'requiresTesting': instance.requiresTesting,
      'recommendation': instance.recommendation,
    };

CombustionRisk _$CombustionRiskFromJson(Map<String, dynamic> json) =>
    CombustionRisk(
      risk: $enumDecode(_$ScoreLevelEnumMap, json['risk']),
      gasStovePresent: json['gasStovePresent'] as bool,
      fireplaceFactor: json['fireplaceFactor'] as bool,
      vehicleExposure: json['vehicleExposure'] as bool,
      recommendation: json['recommendation'] as String,
    );

Map<String, dynamic> _$CombustionRiskToJson(CombustionRisk instance) =>
    <String, dynamic>{
      'risk': _$ScoreLevelEnumMap[instance.risk]!,
      'gasStovePresent': instance.gasStovePresent,
      'fireplaceFactor': instance.fireplaceFactor,
      'vehicleExposure': instance.vehicleExposure,
      'recommendation': instance.recommendation,
    };

VocRisk _$VocRiskFromJson(Map<String, dynamic> json) => VocRisk(
      risk: $enumDecode(_$ScoreLevelEnumMap, json['risk']),
      cleaningProducts: json['cleaningProducts'] as bool,
      newFurniture: json['newFurniture'] as bool,
      paintFumes: json['paintFumes'] as bool,
      recommendation: json['recommendation'] as String,
    );

Map<String, dynamic> _$VocRiskToJson(VocRisk instance) => <String, dynamic>{
      'risk': _$ScoreLevelEnumMap[instance.risk]!,
      'cleaningProducts': instance.cleaningProducts,
      'newFurniture': instance.newFurniture,
      'paintFumes': instance.paintFumes,
      'recommendation': instance.recommendation,
    };

MoldRisk _$MoldRiskFromJson(Map<String, dynamic> json) => MoldRisk(
      risk: $enumDecode(_$ScoreLevelEnumMap, json['risk']),
      highHumidity: json['highHumidity'] as bool,
      waterDamage: json['waterDamage'] as bool,
      poorVentilation: json['poorVentilation'] as bool,
      recommendation: json['recommendation'] as String,
    );

Map<String, dynamic> _$MoldRiskToJson(MoldRisk instance) => <String, dynamic>{
      'risk': _$ScoreLevelEnumMap[instance.risk]!,
      'highHumidity': instance.highHumidity,
      'waterDamage': instance.waterDamage,
      'poorVentilation': instance.poorVentilation,
      'recommendation': instance.recommendation,
    };

PollenLevel _$PollenLevelFromJson(Map<String, dynamic> json) => PollenLevel(
      count: (json['count'] as num).toInt(),
      level: $enumDecode(_$ScoreLevelEnumMap, json['level']),
      dominantTypes: (json['dominantTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$PollenLevelToJson(PollenLevel instance) =>
    <String, dynamic>{
      'count': instance.count,
      'level': _$ScoreLevelEnumMap[instance.level]!,
      'dominantTypes': instance.dominantTypes,
    };

MoldSporeLevel _$MoldSporeLevelFromJson(Map<String, dynamic> json) =>
    MoldSporeLevel(
      count: (json['count'] as num).toInt(),
      level: $enumDecode(_$ScoreLevelEnumMap, json['level']),
      dominantTypes: (json['dominantTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$MoldSporeLevelToJson(MoldSporeLevel instance) =>
    <String, dynamic>{
      'count': instance.count,
      'level': _$ScoreLevelEnumMap[instance.level]!,
      'dominantTypes': instance.dominantTypes,
    };

TemperatureRisk _$TemperatureRiskFromJson(Map<String, dynamic> json) =>
    TemperatureRisk(
      celsius: (json['celsius'] as num).toDouble(),
      fahrenheit: (json['fahrenheit'] as num).toDouble(),
      heatRisk: $enumDecode(_$ScoreLevelEnumMap, json['heatRisk']),
      coldRisk: $enumDecode(_$ScoreLevelEnumMap, json['coldRisk']),
      extremeTemperature: json['extremeTemperature'] as bool,
      recommendation: json['recommendation'] as String,
    );

Map<String, dynamic> _$TemperatureRiskToJson(TemperatureRisk instance) =>
    <String, dynamic>{
      'celsius': instance.celsius,
      'fahrenheit': instance.fahrenheit,
      'heatRisk': _$ScoreLevelEnumMap[instance.heatRisk]!,
      'coldRisk': _$ScoreLevelEnumMap[instance.coldRisk]!,
      'extremeTemperature': instance.extremeTemperature,
      'recommendation': instance.recommendation,
    };

HumidityRisk _$HumidityRiskFromJson(Map<String, dynamic> json) => HumidityRisk(
      relativeHumidity: (json['relativeHumidity'] as num).toDouble(),
      comfortRisk: $enumDecode(_$ScoreLevelEnumMap, json['comfortRisk']),
      moldRisk: json['moldRisk'] as bool,
      dryAirRisk: json['dryAirRisk'] as bool,
      recommendation: json['recommendation'] as String,
    );

Map<String, dynamic> _$HumidityRiskToJson(HumidityRisk instance) =>
    <String, dynamic>{
      'relativeHumidity': instance.relativeHumidity,
      'comfortRisk': _$ScoreLevelEnumMap[instance.comfortRisk]!,
      'moldRisk': instance.moldRisk,
      'dryAirRisk': instance.dryAirRisk,
      'recommendation': instance.recommendation,
    };

StagnationRisk _$StagnationRiskFromJson(Map<String, dynamic> json) =>
    StagnationRisk(
      level: $enumDecode(_$ScoreLevelEnumMap, json['level']),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      inversionPresent: json['inversionPresent'] as bool,
      stagnantDays: (json['stagnantDays'] as num).toInt(),
      description: json['description'] as String,
    );

Map<String, dynamic> _$StagnationRiskToJson(StagnationRisk instance) =>
    <String, dynamic>{
      'level': _$ScoreLevelEnumMap[instance.level]!,
      'windSpeed': instance.windSpeed,
      'inversionPresent': instance.inversionPresent,
      'stagnantDays': instance.stagnantDays,
      'description': instance.description,
    };

UvIndexRisk _$UvIndexRiskFromJson(Map<String, dynamic> json) => UvIndexRisk(
      uvIndex: (json['uvIndex'] as num).toInt(),
      risk: $enumDecode(_$ScoreLevelEnumMap, json['risk']),
      recommendation: json['recommendation'] as String,
      sunscreenRequired: json['sunscreenRequired'] as bool,
    );

Map<String, dynamic> _$UvIndexRiskToJson(UvIndexRisk instance) =>
    <String, dynamic>{
      'uvIndex': instance.uvIndex,
      'risk': _$ScoreLevelEnumMap[instance.risk]!,
      'recommendation': instance.recommendation,
      'sunscreenRequired': instance.sunscreenRequired,
    };
