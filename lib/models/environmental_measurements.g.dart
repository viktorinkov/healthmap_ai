// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'environmental_measurements.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvironmentalMeasurements _$EnvironmentalMeasurementsFromJson(
        Map<String, dynamic> json) =>
    EnvironmentalMeasurements(
      locationId: json['locationId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      airQuality: json['airQuality'] == null
          ? null
          : AirQualityMeasurements.fromJson(
              json['airQuality'] as Map<String, dynamic>),
      indoorEnvironment: json['indoorEnvironment'] == null
          ? null
          : IndoorEnvironmentMeasurements.fromJson(
              json['indoorEnvironment'] as Map<String, dynamic>),
      aeroallergens: json['aeroallergens'] == null
          ? null
          : AeroallergenMeasurements.fromJson(
              json['aeroallergens'] as Map<String, dynamic>),
      meteorology: json['meteorology'] == null
          ? null
          : MeteorologicalMeasurements.fromJson(
              json['meteorology'] as Map<String, dynamic>),
      wildfire: json['wildfire'] == null
          ? null
          : WildfireMeasurements.fromJson(
              json['wildfire'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EnvironmentalMeasurementsToJson(
        EnvironmentalMeasurements instance) =>
    <String, dynamic>{
      'locationId': instance.locationId,
      'timestamp': instance.timestamp.toIso8601String(),
      'airQuality': instance.airQuality,
      'indoorEnvironment': instance.indoorEnvironment,
      'aeroallergens': instance.aeroallergens,
      'meteorology': instance.meteorology,
      'wildfire': instance.wildfire,
    };

AirQualityMeasurements _$AirQualityMeasurementsFromJson(
        Map<String, dynamic> json) =>
    AirQualityMeasurements(
      pm25: (json['pm25'] as num?)?.toDouble(),
      pm10: (json['pm10'] as num?)?.toDouble(),
      ozone: (json['ozone'] as num?)?.toDouble(),
      nitrogenDioxide: (json['nitrogenDioxide'] as num?)?.toDouble(),
      carbonMonoxide: (json['carbonMonoxide'] as num?)?.toDouble(),
      sulfurDioxide: (json['sulfurDioxide'] as num?)?.toDouble(),
      measurementSource: json['measurementSource'] as String,
    );

Map<String, dynamic> _$AirQualityMeasurementsToJson(
        AirQualityMeasurements instance) =>
    <String, dynamic>{
      'pm25': instance.pm25,
      'pm10': instance.pm10,
      'ozone': instance.ozone,
      'nitrogenDioxide': instance.nitrogenDioxide,
      'carbonMonoxide': instance.carbonMonoxide,
      'sulfurDioxide': instance.sulfurDioxide,
      'measurementSource': instance.measurementSource,
    };

WildfireMeasurements _$WildfireMeasurementsFromJson(
        Map<String, dynamic> json) =>
    WildfireMeasurements(
      fireCount: (json['fireCount'] as num).toInt(),
      measurementSource: json['measurementSource'] as String,
    );

Map<String, dynamic> _$WildfireMeasurementsToJson(
        WildfireMeasurements instance) =>
    <String, dynamic>{
      'fireCount': instance.fireCount,
      'measurementSource': instance.measurementSource,
    };

IndoorEnvironmentMeasurements _$IndoorEnvironmentMeasurementsFromJson(
        Map<String, dynamic> json) =>
    IndoorEnvironmentMeasurements(
      volatileOrganicCompoundsPpb:
          (json['volatileOrganicCompoundsPpb'] as num?)?.toDouble(),
      carbonMonoxidePpm: (json['carbonMonoxidePpm'] as num?)?.toDouble(),
      moldSporesPerM3: (json['moldSporesPerM3'] as num?)?.toDouble(),
      formaldehydePpb: (json['formaldehydePpb'] as num?)?.toDouble(),
      measurementSource: json['measurementSource'] as String,
    );

Map<String, dynamic> _$IndoorEnvironmentMeasurementsToJson(
        IndoorEnvironmentMeasurements instance) =>
    <String, dynamic>{
      'volatileOrganicCompoundsPpb': instance.volatileOrganicCompoundsPpb,
      'carbonMonoxidePpm': instance.carbonMonoxidePpm,
      'moldSporesPerM3': instance.moldSporesPerM3,
      'formaldehydePpb': instance.formaldehydePpb,
      'measurementSource': instance.measurementSource,
    };

AeroallergenMeasurements _$AeroallergenMeasurementsFromJson(
        Map<String, dynamic> json) =>
    AeroallergenMeasurements(
      treePollenGrainsPerM3: (json['treePollenGrainsPerM3'] as num?)?.toInt(),
      grassPollenGrainsPerM3: (json['grassPollenGrainsPerM3'] as num?)?.toInt(),
      weedPollenGrainsPerM3: (json['weedPollenGrainsPerM3'] as num?)?.toInt(),
      moldSporesPerM3: (json['moldSporesPerM3'] as num?)?.toInt(),
      dominantPollenTypes: (json['dominantPollenTypes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      measurementSource: json['measurementSource'] as String,
    );

Map<String, dynamic> _$AeroallergenMeasurementsToJson(
        AeroallergenMeasurements instance) =>
    <String, dynamic>{
      'treePollenGrainsPerM3': instance.treePollenGrainsPerM3,
      'grassPollenGrainsPerM3': instance.grassPollenGrainsPerM3,
      'weedPollenGrainsPerM3': instance.weedPollenGrainsPerM3,
      'moldSporesPerM3': instance.moldSporesPerM3,
      'dominantPollenTypes': instance.dominantPollenTypes,
      'measurementSource': instance.measurementSource,
    };

MeteorologicalMeasurements _$MeteorologicalMeasurementsFromJson(
        Map<String, dynamic> json) =>
    MeteorologicalMeasurements(
      temperatureCelsius: (json['temperatureCelsius'] as num?)?.toDouble(),
      temperatureFahrenheit:
          (json['temperatureFahrenheit'] as num?)?.toDouble(),
      relativeHumidityPercent:
          (json['relativeHumidityPercent'] as num?)?.toDouble(),
      windSpeedMs: (json['windSpeedMs'] as num?)?.toDouble(),
      windSpeedMph: (json['windSpeedMph'] as num?)?.toDouble(),
      uvIndex: (json['uvIndex'] as num?)?.toInt(),
      atmosphericPressureHpa:
          (json['atmosphericPressureHpa'] as num?)?.toDouble(),
      stagnationEvent: json['stagnationEvent'] as bool,
      measurementSource: json['measurementSource'] as String,
    );

Map<String, dynamic> _$MeteorologicalMeasurementsToJson(
        MeteorologicalMeasurements instance) =>
    <String, dynamic>{
      'temperatureCelsius': instance.temperatureCelsius,
      'temperatureFahrenheit': instance.temperatureFahrenheit,
      'relativeHumidityPercent': instance.relativeHumidityPercent,
      'windSpeedMs': instance.windSpeedMs,
      'windSpeedMph': instance.windSpeedMph,
      'uvIndex': instance.uvIndex,
      'atmosphericPressureHpa': instance.atmosphericPressureHpa,
      'stagnationEvent': instance.stagnationEvent,
      'measurementSource': instance.measurementSource,
    };

HealthContext _$HealthContextFromJson(Map<String, dynamic> json) =>
    HealthContext(
      measurement: json['measurement'] as String,
      unit: json['unit'] as String,
      value: (json['value'] as num?)?.toDouble(),
      healthStandard: json['healthStandard'] as String?,
      exceedsStandard: json['exceedsStandard'] as bool,
    );

Map<String, dynamic> _$HealthContextToJson(HealthContext instance) =>
    <String, dynamic>{
      'measurement': instance.measurement,
      'unit': instance.unit,
      'value': instance.value,
      'healthStandard': instance.healthStandard,
      'exceedsStandard': instance.exceedsStandard,
    };
