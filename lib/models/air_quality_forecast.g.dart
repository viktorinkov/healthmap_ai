// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'air_quality_forecast.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AirQualityForecast _$AirQualityForecastFromJson(Map<String, dynamic> json) =>
    AirQualityForecast(
      id: json['id'] as String,
      locationName: json['locationName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      requestTimestamp: DateTime.parse(json['requestTimestamp'] as String),
      hourlyForecasts: (json['hourlyForecasts'] as List<dynamic>)
          .map(
              (e) => AirQualityForecastHour.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AirQualityForecastToJson(AirQualityForecast instance) =>
    <String, dynamic>{
      'id': instance.id,
      'locationName': instance.locationName,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'requestTimestamp': instance.requestTimestamp.toIso8601String(),
      'hourlyForecasts': instance.hourlyForecasts,
    };

AirQualityForecastHour _$AirQualityForecastHourFromJson(
        Map<String, dynamic> json) =>
    AirQualityForecastHour(
      timestamp: DateTime.parse(json['timestamp'] as String),
      universalAqi: (json['universalAqi'] as num?)?.toInt(),
      status: json['status'] as String?,
      dominantPollutant: json['dominantPollutant'] as String?,
      pollutants: (json['pollutants'] as List<dynamic>)
          .map(
              (e) => PollutantConcentration.fromJson(e as Map<String, dynamic>))
          .toList(),
      color: json['color'] as String?,
    );

Map<String, dynamic> _$AirQualityForecastHourToJson(
        AirQualityForecastHour instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'universalAqi': instance.universalAqi,
      'status': instance.status,
      'dominantPollutant': instance.dominantPollutant,
      'pollutants': instance.pollutants,
      'color': instance.color,
    };

PollutantConcentration _$PollutantConcentrationFromJson(
        Map<String, dynamic> json) =>
    PollutantConcentration(
      code: json['code'] as String,
      displayName: json['displayName'] as String,
      concentration: (json['concentration'] as num).toDouble(),
      unit: json['unit'] as String,
    );

Map<String, dynamic> _$PollutantConcentrationToJson(
        PollutantConcentration instance) =>
    <String, dynamic>{
      'code': instance.code,
      'displayName': instance.displayName,
      'concentration': instance.concentration,
      'unit': instance.unit,
    };
