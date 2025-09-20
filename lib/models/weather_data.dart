import 'package:json_annotation/json_annotation.dart';

part 'weather_data.g.dart';

@JsonSerializable()
class WeatherData {
  final double temperature;
  final double? minTemp;
  final double? maxTemp;
  final double feelsLike;
  final double humidity;
  final double pressure;
  final double windSpeed;
  final double windDirection;
  final double uvIndex;
  final double visibility;
  final double cloudCover;
  final double dewPoint;
  final String description;
  final String icon;
  final DateTime timestamp;
  final double? precipitationProbability;

  // Extreme conditions
  final bool? heatWaveAlert;
  final bool? coldWaveAlert;
  final bool? stagnationEvent;
  final double? precipitationIntensity;
  final String? precipitationType;

  WeatherData({
    required this.temperature,
    this.minTemp,
    this.maxTemp,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    required this.uvIndex,
    required this.visibility,
    required this.cloudCover,
    required this.dewPoint,
    required this.description,
    required this.icon,
    required this.timestamp,
    this.heatWaveAlert,
    this.coldWaveAlert,
    this.stagnationEvent,
    this.precipitationIntensity,
    this.precipitationType,
    this.precipitationProbability,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) => _$WeatherDataFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherDataToJson(this);

  // Helper methods for condition severity
  bool get isExtremeTemperature => temperature > 35 || temperature < -10;
  bool get isHighHumidity => humidity > 80;
  bool get isLowVisibility => visibility < 1000;
  bool get isStagnant => windSpeed < 2 && stagnationEvent == true;

  String get temperatureStatus {
    if (temperature > 35) return 'Extreme Heat';
    if (temperature > 30) return 'Very Hot';
    if (temperature > 25) return 'Hot';
    if (temperature > 20) return 'Warm';
    if (temperature > 15) return 'Mild';
    if (temperature > 10) return 'Cool';
    if (temperature > 5) return 'Cold';
    if (temperature > 0) return 'Very Cold';
    return 'Freezing';
  }

  String get humidityStatus {
    if (humidity > 80) return 'Very High';
    if (humidity > 60) return 'High';
    if (humidity > 40) return 'Moderate';
    if (humidity > 20) return 'Low';
    return 'Very Low';
  }

  String get windStatus {
    if (windSpeed > 20) return 'Very Strong';
    if (windSpeed > 15) return 'Strong';
    if (windSpeed > 10) return 'Moderate';
    if (windSpeed > 5) return 'Light';
    if (windSpeed > 2) return 'Calm';
    return 'Stagnant';
  }
}

@JsonSerializable()
class WeatherForecast {
  final List<WeatherData> hourly;
  final List<WeatherData> daily;
  final DateTime lastUpdated;

  WeatherForecast({
    required this.hourly,
    required this.daily,
    required this.lastUpdated,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) => _$WeatherForecastFromJson(json);
  Map<String, dynamic> toJson() => _$WeatherForecastToJson(this);
}