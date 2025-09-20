import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/environmental_measurements.dart';
import 'api_keys.dart';
import 'api_service.dart';

class EnvironmentalMeasurementsService {
  static const String _openWeatherBaseUrl = 'https://api.openweathermap.org/data/3.0/onecall';
  static const String _googlePollenBaseUrl = 'https://pollen.googleapis.com/v1/forecast:lookup';
  static const String _openMeteoBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  static Future<EnvironmentalMeasurements?> getEnvironmentalMeasurements({
    required String locationId,
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    try {
      // First try to get data from our backend API which includes radon
      try {
        final backendData = await ApiService.getAllEnvironmentalData(
          latitude: latitude,
          longitude: longitude,
        );

        if (backendData.isNotEmpty) {
          return _parseBackendEnvironmentalData(backendData, locationId);
        }
      } catch (e) {
        print('Backend API unavailable, falling back to direct APIs: $e');
      }

      // Fallback to direct API calls if backend is unavailable
      final futures = await Future.wait([
        _getWeatherMeasurements(latitude, longitude),
        _getPollenMeasurements(latitude, longitude),
        _getAirQualityMeasurements(latitude, longitude),
        _getWildfireMeasurements(latitude, longitude),
      ]);

      final weatherData = futures[0] as MeteorologicalMeasurements?;
      final pollenData = futures[1] as AeroallergenMeasurements?;
      final airQualityData = futures[2] as AirQualityMeasurements?;
      final wildfireData = futures[3] as WildfireMeasurements?;

      // Only return if we have at least some real measurements
      if (weatherData == null && pollenData == null && airQualityData == null && wildfireData == null) {
        return null; // No real environmental measurements available
      }

      return EnvironmentalMeasurements(
        locationId: locationId,
        timestamp: DateTime.now(),
        airQuality: airQualityData,
        indoorEnvironment: null, // No real indoor data available without sensors
        aeroallergens: pollenData,
        meteorology: weatherData,
        wildfire: wildfireData,
      );
    } catch (e) {
      print('Error fetching environmental measurements: $e');
      return null;
    }
  }

  static Future<MeteorologicalMeasurements?> _getWeatherMeasurements(double lat, double lon) async {
    try {
      // Try OpenWeatherMap first (if API key available)
      if (ApiKeys.openWeatherMapApiKey.isNotEmpty) {
        final url = '$_openWeatherBaseUrl?lat=$lat&lon=$lon&appid=${ApiKeys.openWeatherMapApiKey}&units=metric&exclude=minutely,alerts';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return _parseOpenWeatherMapData(data);
        }
      }

      // Fallback to Open-Meteo (free, no API key required)
      final url = '$_openMeteoBaseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m,uv_index,surface_pressure&timezone=auto';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseOpenMeteoData(data);
      }
    } catch (e) {
      print('Error fetching weather measurements: $e');
    }
    return null;
  }

  static MeteorologicalMeasurements _parseOpenWeatherMapData(Map<String, dynamic> data) {
    final current = data['current'];
    final tempC = current['temp']?.toDouble();
    final humidity = current['humidity']?.toDouble();
    final windSpeed = current['wind_speed']?.toDouble();
    final uvIndex = current['uvi']?.round();
    final pressure = current['pressure']?.toDouble();

    return MeteorologicalMeasurements(
      temperatureCelsius: tempC,
      temperatureFahrenheit: tempC != null ? (tempC * 9/5) + 32 : null,
      relativeHumidityPercent: humidity,
      windSpeedMs: windSpeed,
      windSpeedMph: windSpeed != null ? windSpeed * 2.237 : null,
      uvIndex: uvIndex,
      atmosphericPressureHpa: pressure,
      stagnationEvent: windSpeed != null ? windSpeed < 2.0 : false,
      measurementSource: 'OpenWeatherMap API',
    );
  }

  static MeteorologicalMeasurements _parseOpenMeteoData(Map<String, dynamic> data) {
    final current = data['current'];
    final tempC = current['temperature_2m']?.toDouble();
    final humidity = current['relative_humidity_2m']?.toDouble();
    final windSpeed = current['wind_speed_10m']?.toDouble();
    final uvIndex = current['uv_index']?.round();
    final pressure = current['surface_pressure']?.toDouble();

    return MeteorologicalMeasurements(
      temperatureCelsius: tempC,
      temperatureFahrenheit: tempC != null ? (tempC * 9/5) + 32 : null,
      relativeHumidityPercent: humidity,
      windSpeedMs: windSpeed,
      windSpeedMph: windSpeed != null ? windSpeed * 2.237 : null,
      uvIndex: uvIndex,
      atmosphericPressureHpa: pressure,
      stagnationEvent: windSpeed != null ? windSpeed < 2.0 : false,
      measurementSource: 'Open-Meteo API',
    );
  }

  static Future<AeroallergenMeasurements?> _getPollenMeasurements(double lat, double lon) async {
    try {
      if (ApiKeys.googleMapsApiKey.isEmpty) return null;

      final url = '$_googlePollenBaseUrl?key=${ApiKeys.googleMapsApiKey}&location.latitude=$lat&location.longitude=$lon&days=1';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseGooglePollenData(data);
      }
    } catch (e) {
      print('Error fetching pollen measurements: $e');
    }
    return null;
  }

  static AeroallergenMeasurements _parseGooglePollenData(Map<String, dynamic> data) {
    int? treeCount;
    int? grassCount;
    int? weedCount;
    List<String> dominantTypes = [];

    if (data.containsKey('dailyInfo') && data['dailyInfo'].isNotEmpty) {
      final dayInfo = data['dailyInfo'][0];
      final pollenTypeInfo = dayInfo['pollenTypeInfo'] as List<dynamic>?;

      if (pollenTypeInfo != null) {
        for (final pollenType in pollenTypeInfo) {
          final code = pollenType['code'] as String?;
          final indexInfo = pollenType['indexInfo'] as Map<String, dynamic>?;
          final value = indexInfo?['value'] ?? 0;

          // Convert Google's index to approximate grains per cubic meter
          int estimatedCount = (value * 50).round(); // Rough conversion

          switch (code) {
            case 'TREE':
              treeCount = estimatedCount;
              if (pollenType.containsKey('plantInfo')) {
                final plants = pollenType['plantInfo'] as List<dynamic>;
                for (final plant in plants.take(3)) {
                  dominantTypes.add(plant['displayName'] as String);
                }
              }
              break;
            case 'GRASS':
              grassCount = estimatedCount;
              if (pollenType.containsKey('plantInfo')) {
                final plants = pollenType['plantInfo'] as List<dynamic>;
                for (final plant in plants.take(2)) {
                  dominantTypes.add(plant['displayName'] as String);
                }
              }
              break;
            case 'WEED':
              weedCount = estimatedCount;
              if (pollenType.containsKey('plantInfo')) {
                final plants = pollenType['plantInfo'] as List<dynamic>;
                for (final plant in plants.take(2)) {
                  dominantTypes.add(plant['displayName'] as String);
                }
              }
              break;
          }
        }
      }
    }

    return AeroallergenMeasurements(
      treePollenGrainsPerM3: treeCount,
      grassPollenGrainsPerM3: grassCount,
      weedPollenGrainsPerM3: weedCount,
      moldSporesPerM3: null, // Not provided by Google Pollen API
      dominantPollenTypes: dominantTypes,
      measurementSource: 'Google Pollen API',
    );
  }

  static Future<AirQualityMeasurements?> _getAirQualityMeasurements(double lat, double lon) async {
    try {
      if (ApiKeys.googleMapsApiKey.isEmpty) return null;

      final url = 'https://airquality.googleapis.com/v1/currentConditions:lookup?key=${ApiKeys.googleMapsApiKey}';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'location': {
            'latitude': lat,
            'longitude': lon,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseGoogleAirQualityData(data);
      }
    } catch (e) {
      print('Error fetching air quality measurements: $e');
    }
    return null;
  }

  static AirQualityMeasurements _parseGoogleAirQualityData(Map<String, dynamic> data) {
    double? pm25;
    double? pm10;
    double? o3;
    double? no2;
    double? co;
    double? so2;

    if (data.containsKey('indexes')) {
      final indexes = data['indexes'] as List;
      for (final index in indexes) {
        if (index['code'] == 'uaqi') {
          final pollutants = index['pollutants'] as Map<String, dynamic>?;
          if (pollutants != null) {
            pm25 = pollutants['pm25']?['concentration']?['value']?.toDouble();
            pm10 = pollutants['pm10']?['concentration']?['value']?.toDouble();
            o3 = pollutants['o3']?['concentration']?['value']?.toDouble();
            no2 = pollutants['no2']?['concentration']?['value']?.toDouble();
            co = pollutants['co']?['concentration']?['value']?.toDouble();
            so2 = pollutants['so2']?['concentration']?['value']?.toDouble();
          }
          break;
        }
      }
    }

    return AirQualityMeasurements(
      pm25: pm25,
      pm10: pm10,
      ozone: o3,
      nitrogenDioxide: no2,
      carbonMonoxide: co,
      sulfurDioxide: so2,
      measurementSource: 'Google Air Quality API',
    );
  }

  static Future<WildfireMeasurements?> _getWildfireMeasurements(double lat, double lon) async {
    try {
      // NASA FIRMS (Fire Information for Resource Management System) - free API
      final url = 'https://firms.modaps.eosdis.nasa.gov/api/area/csv/c6/VIIRS_SNPP_NRT/${lon-0.5},${lat-0.5},${lon+0.5},${lat+0.5}/1';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return _parseNASAFirmsData(response.body, lat, lon);
      }
    } catch (e) {
      print('Error fetching wildfire measurements: $e');
    }
    return null;
  }

  static WildfireMeasurements _parseNASAFirmsData(String csvData, double lat, double lon) {
    final lines = csvData.split('\n');
    if (lines.length <= 1) {
      // No fires detected
      return WildfireMeasurements(
        smokeParticulates: null,
        visibilityKm: null,
        activeFireCount: 0,
        nearestFireDistanceKm: null,
        measurementSource: 'NASA FIRMS',
      );
    }

    // Parse CSV data (skip header)
    final fires = <Map<String, String>>[];
    final headers = lines[0].split(',');

    for (int i = 1; i < lines.length; i++) {
      if (lines[i].trim().isEmpty) continue;
      final values = lines[i].split(',');
      if (values.length >= headers.length) {
        final fire = <String, String>{};
        for (int j = 0; j < headers.length; j++) {
          fire[headers[j].trim()] = values[j].trim();
        }
        fires.add(fire);
      }
    }

    double? nearestDistance;
    if (fires.isNotEmpty) {
      // Calculate distance to nearest fire
      double minDistance = double.infinity;
      for (final fire in fires) {
        final fireLat = double.tryParse(fire['latitude'] ?? '');
        final fireLon = double.tryParse(fire['longitude'] ?? '');
        if (fireLat != null && fireLon != null) {
          final distance = _calculateDistance(lat, lon, fireLat, fireLon);
          if (distance < minDistance) {
            minDistance = distance;
          }
        }
      }
      nearestDistance = minDistance == double.infinity ? null : minDistance;
    }

    return WildfireMeasurements(
      smokeParticulates: null, // Would need additional air quality data
      visibilityKm: null, // Would need visibility sensors
      activeFireCount: fires.length,
      nearestFireDistanceKm: nearestDistance,
      measurementSource: 'NASA FIRMS',
    );
  }

  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Haversine formula to calculate distance between two points
    const double earthRadius = 6371; // km
    final double dLat = (lat2 - lat1) * pi / 180;
    final double dLon = (lon2 - lon1) * pi / 180;
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Parse environmental data from our backend API
  static EnvironmentalMeasurements _parseBackendEnvironmentalData(
    Map<String, dynamic> data,
    String locationId,
  ) {
    // Parse air quality data
    AirQualityMeasurements? airQuality;
    if (data['airQuality'] != null && data['airQuality'] is Map) {
      final aq = data['airQuality'] as Map<String, dynamic>;
      if (!aq.containsKey('error')) {
        airQuality = AirQualityMeasurements(
          pm25: aq['pm25']?.toDouble(),
          pm10: aq['pm10']?.toDouble(),
          ozone: aq['o3']?.toDouble(),
          nitrogenDioxide: aq['no2']?.toDouble(),
          carbonMonoxide: aq['co']?.toDouble(),
          sulfurDioxide: aq['so2']?.toDouble(),
          measurementSource: 'HealthMap AI Backend',
        );
      }
    }

    // Parse weather data
    MeteorologicalMeasurements? weather;
    if (data['weather'] != null && data['weather'] is Map) {
      final w = data['weather'] as Map<String, dynamic>;
      if (!w.containsKey('error')) {
        weather = MeteorologicalMeasurements(
          temperatureCelsius: w['temperature']?.toDouble(),
          temperatureFahrenheit: w['temperature'] != null
            ? (w['temperature'].toDouble() * 9/5) + 32
            : null,
          relativeHumidityPercent: w['humidity']?.toDouble(),
          windSpeedMs: w['windSpeed']?.toDouble(),
          windSpeedMph: w['windSpeed'] != null
            ? w['windSpeed'].toDouble() * 2.237
            : null,
          uvIndex: null, // Not provided by our backend yet
          atmosphericPressureHpa: w['pressure']?.toDouble(),
          stagnationEvent: w['windSpeed'] != null ? w['windSpeed'].toDouble() < 2.0 : false,
          measurementSource: 'HealthMap AI Backend',
        );
      }
    }

    // Parse pollen data
    AeroallergenMeasurements? pollen;
    if (data['pollen'] != null && data['pollen'] is Map) {
      final p = data['pollen'] as Map<String, dynamic>;
      if (!p.containsKey('error')) {
        pollen = AeroallergenMeasurements(
          treePollenGrainsPerM3: p['treePollen'],
          grassPollenGrainsPerM3: p['grassPollen'],
          weedPollenGrainsPerM3: p['weedPollen'],
          moldSporesPerM3: null,
          dominantPollenTypes: [],
          measurementSource: 'HealthMap AI Backend',
        );
      }
    }

    // Parse wildfire data
    WildfireMeasurements? wildfire;
    if (data['wildfire'] != null && data['wildfire'] is Map) {
      final wf = data['wildfire'] as Map<String, dynamic>;
      if (!wf.containsKey('error')) {
        wildfire = WildfireMeasurements(
          smokeParticulates: wf['smokeImpact'] != null ? 25.0 : null, // Estimated based on smoke impact
          visibilityKm: null,
          activeFireCount: wf['nearbyFires'] ?? 0,
          nearestFireDistanceKm: wf['closestFireDistance']?.toDouble(),
          measurementSource: 'HealthMap AI Backend',
        );
      }
    }

    // Parse radon data (NEW!)
    IndoorEnvironmentMeasurements? indoorEnvironment;
    if (data['radon'] != null && data['radon'] is Map) {
      final r = data['radon'] as Map<String, dynamic>;
      if (!r.containsKey('error')) {
        indoorEnvironment = IndoorEnvironmentMeasurements(
          radonLevelPciL: r['averageRadonLevel']?.toDouble(),
          volatileOrganicCompoundsPpb: null,
          carbonMonoxidePpm: null,
          moldSporesPerM3: null,
          formaldehydePpb: null,
          measurementSource: 'EPA Radon Zone Data',
        );
      }
    }

    return EnvironmentalMeasurements(
      locationId: locationId,
      timestamp: DateTime.now(),
      airQuality: airQuality,
      indoorEnvironment: indoorEnvironment,
      aeroallergens: pollen,
      meteorology: weather,
      wildfire: wildfire,
    );
  }
}