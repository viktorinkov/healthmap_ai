// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherData _$WeatherDataFromJson(Map<String, dynamic> json) => WeatherData(
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feelsLike'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      pressure: (json['pressure'] as num).toDouble(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      windDirection: (json['windDirection'] as num).toDouble(),
      uvIndex: (json['uvIndex'] as num).toDouble(),
      visibility: (json['visibility'] as num).toDouble(),
      cloudCover: (json['cloudCover'] as num).toDouble(),
      dewPoint: (json['dewPoint'] as num).toDouble(),
      description: json['description'] as String,
      icon: json['icon'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      heatWaveAlert: json['heatWaveAlert'] as bool?,
      coldWaveAlert: json['coldWaveAlert'] as bool?,
      stagnationEvent: json['stagnationEvent'] as bool?,
      precipitationIntensity:
          (json['precipitationIntensity'] as num?)?.toDouble(),
      precipitationType: json['precipitationType'] as String?,
    );

Map<String, dynamic> _$WeatherDataToJson(WeatherData instance) =>
    <String, dynamic>{
      'temperature': instance.temperature,
      'feelsLike': instance.feelsLike,
      'humidity': instance.humidity,
      'pressure': instance.pressure,
      'windSpeed': instance.windSpeed,
      'windDirection': instance.windDirection,
      'uvIndex': instance.uvIndex,
      'visibility': instance.visibility,
      'cloudCover': instance.cloudCover,
      'dewPoint': instance.dewPoint,
      'description': instance.description,
      'icon': instance.icon,
      'timestamp': instance.timestamp.toIso8601String(),
      'heatWaveAlert': instance.heatWaveAlert,
      'coldWaveAlert': instance.coldWaveAlert,
      'stagnationEvent': instance.stagnationEvent,
      'precipitationIntensity': instance.precipitationIntensity,
      'precipitationType': instance.precipitationType,
    };

WeatherForecast _$WeatherForecastFromJson(Map<String, dynamic> json) =>
    WeatherForecast(
      hourly: (json['hourly'] as List<dynamic>)
          .map((e) => WeatherData.fromJson(e as Map<String, dynamic>))
          .toList(),
      daily: (json['daily'] as List<dynamic>)
          .map((e) => WeatherData.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$WeatherForecastToJson(WeatherForecast instance) =>
    <String, dynamic>{
      'hourly': instance.hourly,
      'daily': instance.daily,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };
