import 'package:json_annotation/json_annotation.dart';

part 'environmental_measurements.g.dart';

@JsonSerializable()
class EnvironmentalMeasurements {
  final String locationId;
  final DateTime timestamp;
  final AirQualityMeasurements? airQuality;
  final IndoorEnvironmentMeasurements? indoorEnvironment;
  final AeroallergenMeasurements? aeroallergens;
  final MeteorologicalMeasurements? meteorology;
  final WildfireMeasurements? wildfire;

  const EnvironmentalMeasurements({
    required this.locationId,
    required this.timestamp,
    this.airQuality,
    this.indoorEnvironment,
    this.aeroallergens,
    this.meteorology,
    this.wildfire,
  });

  factory EnvironmentalMeasurements.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentalMeasurementsFromJson(json);
  Map<String, dynamic> toJson() => _$EnvironmentalMeasurementsToJson(this);
}

@JsonSerializable()
class AirQualityMeasurements {
  final double? pm25; // PM2.5 in μg/m³
  final double? pm10; // PM10 in μg/m³
  final double? ozone; // Ozone in ppb
  final double? nitrogenDioxide; // NO2 in ppb
  final double? carbonMonoxide; // CO in ppb
  final double? sulfurDioxide; // SO2 in ppb
  final String measurementSource; // e.g., "Google Air Quality API", "EPA AirNow"

  const AirQualityMeasurements({
    this.pm25,
    this.pm10,
    this.ozone,
    this.nitrogenDioxide,
    this.carbonMonoxide,
    this.sulfurDioxide,
    required this.measurementSource,
  });

  factory AirQualityMeasurements.fromJson(Map<String, dynamic> json) =>
      _$AirQualityMeasurementsFromJson(json);
  Map<String, dynamic> toJson() => _$AirQualityMeasurementsToJson(this);
}

@JsonSerializable()
class WildfireMeasurements {
  final double? smokeParticulates; // PM2.5 from wildfire smoke in μg/m³
  final double? visibilityKm; // Visibility in kilometers
  final int activeFireCount; // Number of active fires within radius
  final double? nearestFireDistanceKm; // Distance to nearest fire in km
  final String measurementSource; // e.g., "NASA FIRMS", "NOAA HMS"

  const WildfireMeasurements({
    this.smokeParticulates,
    this.visibilityKm,
    required this.activeFireCount,
    this.nearestFireDistanceKm,
    required this.measurementSource,
  });

  factory WildfireMeasurements.fromJson(Map<String, dynamic> json) =>
      _$WildfireMeasurementsFromJson(json);
  Map<String, dynamic> toJson() => _$WildfireMeasurementsToJson(this);
}

@JsonSerializable()
class IndoorEnvironmentMeasurements {
  final double? radonLevelPciL; // Radon in picocuries per liter (pCi/L)
  final double? volatileOrganicCompoundsPpb; // VOCs in parts per billion
  final double? carbonMonoxidePpm; // CO from combustion in parts per million
  final double? moldSporesPerM3; // Mold spores per cubic meter
  final double? formaldehydePpb; // Formaldehyde in ppb
  final String measurementSource; // e.g., "EPA Radon Database", "User Sensor"

  const IndoorEnvironmentMeasurements({
    this.radonLevelPciL,
    this.volatileOrganicCompoundsPpb,
    this.carbonMonoxidePpm,
    this.moldSporesPerM3,
    this.formaldehydePpb,
    required this.measurementSource,
  });

  factory IndoorEnvironmentMeasurements.fromJson(Map<String, dynamic> json) =>
      _$IndoorEnvironmentMeasurementsFromJson(json);
  Map<String, dynamic> toJson() => _$IndoorEnvironmentMeasurementsToJson(this);
}

@JsonSerializable()
class AeroallergenMeasurements {
  final int? treePollenGrainsPerM3; // Tree pollen grains per cubic meter
  final int? grassPollenGrainsPerM3; // Grass pollen grains per cubic meter
  final int? weedPollenGrainsPerM3; // Weed pollen grains per cubic meter
  final int? moldSporesPerM3; // Mold spores per cubic meter
  final List<String> dominantPollenTypes; // e.g., ["Oak", "Birch", "Ragweed"]
  final String measurementSource; // e.g., "Google Pollen API", "NAB Network"

  const AeroallergenMeasurements({
    this.treePollenGrainsPerM3,
    this.grassPollenGrainsPerM3,
    this.weedPollenGrainsPerM3,
    this.moldSporesPerM3,
    required this.dominantPollenTypes,
    required this.measurementSource,
  });

  factory AeroallergenMeasurements.fromJson(Map<String, dynamic> json) =>
      _$AeroallergenMeasurementsFromJson(json);
  Map<String, dynamic> toJson() => _$AeroallergenMeasurementsToJson(this);
}

@JsonSerializable()
class MeteorologicalMeasurements {
  final double? temperatureCelsius; // Temperature in °C
  final double? temperatureFahrenheit; // Temperature in °F
  final double? relativeHumidityPercent; // Relative humidity in %
  final double? windSpeedMs; // Wind speed in m/s
  final double? windSpeedMph; // Wind speed in mph
  final int? uvIndex; // UV Index (0-11+)
  final double? atmosphericPressureHpa; // Atmospheric pressure in hPa
  final bool stagnationEvent; // True if air stagnation event occurring
  final String measurementSource; // e.g., "OpenWeatherMap", "Open-Meteo"

  const MeteorologicalMeasurements({
    this.temperatureCelsius,
    this.temperatureFahrenheit,
    this.relativeHumidityPercent,
    this.windSpeedMs,
    this.windSpeedMph,
    this.uvIndex,
    this.atmosphericPressureHpa,
    required this.stagnationEvent,
    required this.measurementSource,
  });

  factory MeteorologicalMeasurements.fromJson(Map<String, dynamic> json) =>
      _$MeteorologicalMeasurementsFromJson(json);
  Map<String, dynamic> toJson() => _$MeteorologicalMeasurementsToJson(this);
}

// Helper class for health impact context (NOT scores)
@JsonSerializable()
class HealthContext {
  final String measurement;
  final String unit;
  final double? value;
  final String? healthStandard; // e.g., "EPA Standard: 35 μg/m³"
  final bool exceedsStandard;

  const HealthContext({
    required this.measurement,
    required this.unit,
    this.value,
    this.healthStandard,
    required this.exceedsStandard,
  });

  factory HealthContext.fromJson(Map<String, dynamic> json) =>
      _$HealthContextFromJson(json);
  Map<String, dynamic> toJson() => _$HealthContextToJson(this);
}