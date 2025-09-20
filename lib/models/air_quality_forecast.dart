import 'package:json_annotation/json_annotation.dart';

part 'air_quality_forecast.g.dart';

@JsonSerializable()
class AirQualityForecast {
  final String id;
  final String locationName;
  final double latitude;
  final double longitude;
  final DateTime requestTimestamp;
  final List<AirQualityForecastHour> hourlyForecasts;

  const AirQualityForecast({
    required this.id,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.requestTimestamp,
    required this.hourlyForecasts,
  });

  factory AirQualityForecast.fromJson(Map<String, dynamic> json) => _$AirQualityForecastFromJson(json);
  Map<String, dynamic> toJson() => _$AirQualityForecastToJson(this);

  /// Get forecast data for the next 12 hours
  List<AirQualityForecastHour> get next12Hours {
    final now = DateTime.now();
    return hourlyForecasts
        .where((hour) => hour.timestamp.isAfter(now))
        .take(12)
        .toList();
  }

  /// Get forecast data for a specific pollutant over the next 12 hours
  List<PollutantForecastPoint> getPollutantForecast(String pollutantCode) {
    return next12Hours
        .map((hour) => PollutantForecastPoint(
              timestamp: hour.timestamp,
              value: hour.getPollutantValue(pollutantCode),
            ))
        .where((point) => point.value != null)
        .toList();
  }
}

@JsonSerializable()
class AirQualityForecastHour {
  final DateTime timestamp;
  final int? universalAqi;
  final String? status;
  final String? dominantPollutant;
  final List<PollutantConcentration> pollutants;
  final String? color;

  const AirQualityForecastHour({
    required this.timestamp,
    this.universalAqi,
    this.status,
    this.dominantPollutant,
    required this.pollutants,
    this.color,
  });

  factory AirQualityForecastHour.fromJson(Map<String, dynamic> json) => _$AirQualityForecastHourFromJson(json);
  Map<String, dynamic> toJson() => _$AirQualityForecastHourToJson(this);

  /// Get pollutant value by code (pm25, pm10, o3, no2, etc.)
  double? getPollutantValue(String code) {
    try {
      final pollutant = pollutants.firstWhere((p) => p.code == code);
      return pollutant.concentration;
    } catch (e) {
      return null;
    }
  }

  /// Get all available pollutant codes for this hour
  List<String> get availablePollutants {
    return pollutants.map((p) => p.code).toList();
  }
}

@JsonSerializable()
class PollutantConcentration {
  final String code;
  final String displayName;
  final double concentration;
  final String unit;

  const PollutantConcentration({
    required this.code,
    required this.displayName,
    required this.concentration,
    required this.unit,
  });

  factory PollutantConcentration.fromJson(Map<String, dynamic> json) => _$PollutantConcentrationFromJson(json);
  Map<String, dynamic> toJson() => _$PollutantConcentrationToJson(this);
}

class PollutantForecastPoint {
  final DateTime timestamp;
  final double? value;

  const PollutantForecastPoint({
    required this.timestamp,
    required this.value,
  });
}

/// Helper class to define common pollutants with their display information
class PollutantInfo {
  final String code;
  final String displayName;
  final String unit;
  final String description;

  const PollutantInfo({
    required this.code,
    required this.displayName,
    required this.unit,
    required this.description,
  });

  static const List<PollutantInfo> commonPollutants = [
    PollutantInfo(
      code: 'pm25',
      displayName: 'PM2.5',
      unit: 'μg/m³',
      description: 'Fine particulate matter',
    ),
    PollutantInfo(
      code: 'pm10',
      displayName: 'PM10',
      unit: 'μg/m³',
      description: 'Coarse particulate matter',
    ),
    PollutantInfo(
      code: 'o3',
      displayName: 'Ozone',
      unit: 'μg/m³',
      description: 'Ground-level ozone',
    ),
    PollutantInfo(
      code: 'no2',
      displayName: 'NO₂',
      unit: 'μg/m³',
      description: 'Nitrogen dioxide',
    ),
    PollutantInfo(
      code: 'so2',
      displayName: 'SO₂',
      unit: 'μg/m³',
      description: 'Sulfur dioxide',
    ),
    PollutantInfo(
      code: 'co',
      displayName: 'CO',
      unit: 'mg/m³',
      description: 'Carbon monoxide',
    ),
  ];

  static PollutantInfo? getPollutantInfo(String code) {
    try {
      return commonPollutants.firstWhere((p) => p.code == code);
    } catch (e) {
      return null;
    }
  }
}