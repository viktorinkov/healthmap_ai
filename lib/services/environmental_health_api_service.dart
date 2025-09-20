import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/environmental_health_scores.dart';
import 'api_keys.dart';

class EnvironmentalHealthApiService {
  static const String _openWeatherBaseUrl = 'https://api.openweathermap.org/data/3.0/onecall';
  static const String _googlePollenBaseUrl = 'https://pollen.googleapis.com/v1/forecast:lookup';
  static const String _airNowBaseUrl = 'https://www.airnowapi.org/aq';
  static const String _openMeteoBaseUrl = 'https://api.open-meteo.com/v1/forecast';

  static Future<EnvironmentalHealthScores> getEnvironmentalHealthScores({
    required String locationId,
    required double latitude,
    required double longitude,
    String? locationName,
  }) async {
    try {
      // Get all environmental data in parallel
      final futures = await Future.wait([
        _getWeatherData(latitude, longitude),
        _getPollenData(latitude, longitude),
        _getAirQualityData(latitude, longitude),
        _getWildfireData(latitude, longitude),
      ]);

      final weatherData = futures[0] as Map<String, dynamic>?;
      final pollenData = futures[1] as Map<String, dynamic>?;
      final airQualityData = futures[2] as Map<String, dynamic>?;
      final wildfireData = futures[3] as Map<String, dynamic>?;

      // Calculate scores based on real data
      final airQualityScore = _calculateAirQualityScore(airQualityData);
      final indoorScore = _calculateIndoorEnvironmentScore(latitude, longitude);
      final aeroallergenScore = _calculateAeroallergenScore(pollenData);
      final meteorologyScore = _calculateMeteorologicalScore(weatherData);
      final wildfireScore = _calculateWildfireScore(wildfireData);
      final overallScore = _calculateOverallScore(
        airQualityScore,
        indoorScore,
        aeroallergenScore,
        meteorologyScore,
        wildfireScore,
      );

      return EnvironmentalHealthScores(
        locationId: locationId,
        timestamp: DateTime.now(),
        airQuality: airQualityScore,
        indoorEnvironment: indoorScore,
        aeroallergens: aeroallergenScore,
        meteorology: meteorologyScore,
        wildfire: wildfireScore,
        overall: overallScore,
      );
    } catch (e) {
      print('Error fetching environmental health scores: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> _getWeatherData(double lat, double lon) async {
    try {
      // Try OpenWeatherMap first (if API key available)
      if (ApiKeys.openWeatherMapApiKey.isNotEmpty) {
        final url = '$_openWeatherBaseUrl?lat=$lat&lon=$lon&appid=${ApiKeys.openWeatherMapApiKey}&units=metric&exclude=minutely,alerts';
        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
      }

      // Fallback to Open-Meteo (free, no API key required)
      final url = '$_openMeteoBaseUrl?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m,uv_index&hourly=temperature_2m,relative_humidity_2m,uv_index&daily=uv_index_max,temperature_2m_max,temperature_2m_min&timezone=auto';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _getPollenData(double lat, double lon) async {
    try {
      if (ApiKeys.googleMapsApiKey.isEmpty) return null;

      final url = '$_googlePollenBaseUrl?key=${ApiKeys.googleMapsApiKey}&location.latitude=$lat&location.longitude=$lon&days=1';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching pollen data: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _getAirQualityData(double lat, double lon) async {
    try {
      // Try Google Air Quality API first
      if (ApiKeys.googleMapsApiKey.isNotEmpty) {
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
          return json.decode(response.body);
        }
      }

      // Fallback: Use existing air quality service logic
      // (This would integrate with your existing AirQualityApiService)
    } catch (e) {
      print('Error fetching air quality data: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> _getWildfireData(double lat, double lon) async {
    try {
      // For wildfire data, we can use NASA FIRMS (Fire Information for Resource Management System)
      // This is a free API that provides active fire data
      final url = 'https://firms.modaps.eosdis.nasa.gov/mapserver/wms/fires?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&FORMAT=image/png&TRANSPARENT=true&QUERY_LAYERS=fires&STYLES&LAYERS=fires&I=256&J=256&WIDTH=512&HEIGHT=512&CRS=EPSG:4326&BBOX=${lon-0.5},${lat-0.5},${lon+0.5},${lat+0.5}&INFO_FORMAT=application/json';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error fetching wildfire data: $e');
    }
    return null;
  }

  static AirQualityScore _calculateAirQualityScore(Map<String, dynamic>? data) {
    if (data == null) {
      return AirQualityScore(
        score: 50.0,
        level: ScoreLevel.moderate,
        pm25: 12.0,
        pm10: 20.0,
        o3: 45.0,
        no2: 25.0,
        primaryConcern: 'Data unavailable',
      );
    }

    // Parse Google Air Quality API response
    double pm25 = 12.0;
    double pm10 = 20.0;
    double o3 = 45.0;
    double no2 = 25.0;
    double? co;
    double? so2;

    if (data.containsKey('indexes')) {
      final indexes = data['indexes'] as List;
      for (final index in indexes) {
        if (index['code'] == 'uaqi') {
          final pollutants = index['pollutants'] as Map<String, dynamic>?;
          if (pollutants != null) {
            pm25 = (pollutants['pm25']?['concentration']?['value'] ?? 12.0).toDouble();
            pm10 = (pollutants['pm10']?['concentration']?['value'] ?? 20.0).toDouble();
            o3 = (pollutants['o3']?['concentration']?['value'] ?? 45.0).toDouble();
            no2 = (pollutants['no2']?['concentration']?['value'] ?? 25.0).toDouble();
            co = pollutants['co']?['concentration']?['value']?.toDouble();
            so2 = pollutants['so2']?['concentration']?['value']?.toDouble();
          }
          break;
        }
      }
    }

    // Calculate score using EPA standards
    double pm25Score = (pm25 / 35.0) * 100; // EPA standard
    double pm10Score = (pm10 / 150.0) * 100; // EPA standard
    double o3Score = (o3 / 70.0) * 100; // EPA standard (ppb)
    double no2Score = (no2 / 100.0) * 100; // EPA standard (ppb)

    double finalScore = (pm25Score * 0.4 + pm10Score * 0.25 + o3Score * 0.2 + no2Score * 0.15).clamp(0, 100);

    String primaryConcern;
    if (pm25Score > 75) primaryConcern = 'High PM2.5 levels';
    else if (pm10Score > 75) primaryConcern = 'High PM10 levels';
    else if (o3Score > 75) primaryConcern = 'High ozone levels';
    else if (no2Score > 75) primaryConcern = 'High nitrogen dioxide';
    else primaryConcern = 'Air quality acceptable';

    return AirQualityScore(
      score: finalScore,
      level: ScoreLevelExtension.fromScore(finalScore),
      pm25: pm25,
      pm10: pm10,
      o3: o3,
      no2: no2,
      co: co,
      so2: so2,
      primaryConcern: primaryConcern,
    );
  }

  static AeroallergenScore _calculateAeroallergenScore(Map<String, dynamic>? data) {
    if (data == null) {
      return AeroallergenScore(
        score: 30.0,
        level: ScoreLevel.good,
        treePollen: PollenLevel(count: 50, level: ScoreLevel.good, dominantTypes: ['Oak']),
        grassPollen: PollenLevel(count: 30, level: ScoreLevel.good, dominantTypes: ['Timothy']),
        weedPollen: PollenLevel(count: 20, level: ScoreLevel.good, dominantTypes: ['Ragweed']),
        moldSpores: MoldSporeLevel(count: 100, level: ScoreLevel.good, dominantTypes: ['Alternaria']),
        dominantAllergen: 'No significant allergens',
      );
    }

    // Parse Google Pollen API response
    int treeCount = 0;
    int grassCount = 0;
    int weedCount = 0;
    List<String> treeTypes = [];
    List<String> grassTypes = [];
    List<String> weedTypes = [];

    if (data.containsKey('dailyInfo') && data['dailyInfo'].isNotEmpty) {
      final dayInfo = data['dailyInfo'][0];
      final pollenTypeInfo = dayInfo['pollenTypeInfo'] as List<dynamic>?;

      if (pollenTypeInfo != null) {
        for (final pollenType in pollenTypeInfo) {
          final code = pollenType['code'] as String?;
          final indexInfo = pollenType['indexInfo'] as Map<String, dynamic>?;
          final value = indexInfo?['value'] ?? 0;

          switch (code) {
            case 'TREE':
              treeCount = (value * 20).round(); // Convert index to count approximation
              if (pollenType.containsKey('plantInfo')) {
                final plants = pollenType['plantInfo'] as List<dynamic>;
                treeTypes = plants.map((p) => p['displayName'] as String).take(3).toList();
              }
              break;
            case 'GRASS':
              grassCount = (value * 15).round();
              if (pollenType.containsKey('plantInfo')) {
                final plants = pollenType['plantInfo'] as List<dynamic>;
                grassTypes = plants.map((p) => p['displayName'] as String).take(3).toList();
              }
              break;
            case 'WEED':
              weedCount = (value * 10).round();
              if (pollenType.containsKey('plantInfo')) {
                final plants = pollenType['plantInfo'] as List<dynamic>;
                weedTypes = plants.map((p) => p['displayName'] as String).take(3).toList();
              }
              break;
          }
        }
      }
    }

    // Calculate overall score (higher pollen = higher score = worse for allergies)
    double totalScore = (treeCount * 0.4 + grassCount * 0.35 + weedCount * 0.25) / 10;
    totalScore = totalScore.clamp(0, 100);

    String dominantAllergen;
    if (treeCount > grassCount && treeCount > weedCount) {
      dominantAllergen = 'Tree pollen (${treeTypes.isNotEmpty ? treeTypes.first : 'Mixed'})';
    } else if (grassCount > weedCount) {
      dominantAllergen = 'Grass pollen (${grassTypes.isNotEmpty ? grassTypes.first : 'Mixed'})';
    } else if (weedCount > 0) {
      dominantAllergen = 'Weed pollen (${weedTypes.isNotEmpty ? weedTypes.first : 'Mixed'})';
    } else {
      dominantAllergen = 'Low pollen levels';
    }

    return AeroallergenScore(
      score: totalScore,
      level: ScoreLevelExtension.fromScore(totalScore),
      treePollen: PollenLevel(
        count: treeCount,
        level: ScoreLevelExtension.fromScore(treeCount / 2.0),
        dominantTypes: treeTypes.isNotEmpty ? treeTypes : ['Oak', 'Birch'],
      ),
      grassPollen: PollenLevel(
        count: grassCount,
        level: ScoreLevelExtension.fromScore(grassCount / 1.5),
        dominantTypes: grassTypes.isNotEmpty ? grassTypes : ['Timothy', 'Bermuda'],
      ),
      weedPollen: PollenLevel(
        count: weedCount,
        level: ScoreLevelExtension.fromScore(weedCount.toDouble()),
        dominantTypes: weedTypes.isNotEmpty ? weedTypes : ['Ragweed'],
      ),
      moldSpores: MoldSporeLevel(
        count: 100,
        level: ScoreLevel.good,
        dominantTypes: ['Alternaria', 'Cladosporium'],
      ),
      dominantAllergen: dominantAllergen,
    );
  }

  static MeteorologicalScore _calculateMeteorologicalScore(Map<String, dynamic>? data) {
    if (data == null) {
      return MeteorologicalScore(
        score: 25.0,
        level: ScoreLevel.good,
        temperature: TemperatureRisk(
          celsius: 22.0,
          fahrenheit: 71.6,
          heatRisk: ScoreLevel.good,
          coldRisk: ScoreLevel.good,
          extremeTemperature: false,
          recommendation: 'Comfortable temperature for outdoor activities',
        ),
        humidity: HumidityRisk(
          relativeHumidity: 55.0,
          comfortRisk: ScoreLevel.good,
          moldRisk: false,
          dryAirRisk: false,
          recommendation: 'Comfortable humidity levels',
        ),
        airStagnation: StagnationRisk(
          level: ScoreLevel.good,
          windSpeed: 5.0,
          inversionPresent: false,
          stagnantDays: 0,
          description: 'Good air circulation',
        ),
        uvIndex: UvIndexRisk(
          uvIndex: 5,
          risk: ScoreLevel.moderate,
          recommendation: 'Use sunscreen for extended outdoor exposure',
          sunscreenRequired: true,
        ),
        primaryConcern: 'Weather conditions are favorable',
      );
    }

    // Parse weather data (works with both OpenWeatherMap and Open-Meteo)
    double temperature = 22.0;
    double humidity = 55.0;
    double windSpeed = 5.0;
    int uvIndex = 5;

    if (data.containsKey('current')) {
      // OpenWeatherMap or Open-Meteo format
      final current = data['current'];
      temperature = (current['temp'] ?? current['temperature_2m'] ?? 22.0).toDouble();
      humidity = (current['humidity'] ?? current['relative_humidity_2m'] ?? 55.0).toDouble();
      windSpeed = (current['wind_speed'] ?? current['wind_speed_10m'] ?? 5.0).toDouble();
      uvIndex = (current['uvi'] ?? current['uv_index'] ?? 5).round();
    }

    // Calculate temperature risk
    double tempScore = 0.0;
    bool extremeTemp = false;
    String tempRec = 'Comfortable temperature for outdoor activities';

    if (temperature > 35.0) {
      tempScore = 80.0;
      extremeTemp = true;
      tempRec = 'Extreme heat warning - limit outdoor exposure';
    } else if (temperature > 30.0) {
      tempScore = 60.0;
      tempRec = 'Hot weather - stay hydrated and seek shade';
    } else if (temperature < -10.0) {
      tempScore = 70.0;
      extremeTemp = true;
      tempRec = 'Extreme cold - limit outdoor exposure';
    } else if (temperature < 0.0) {
      tempScore = 50.0;
      tempRec = 'Cold weather - dress warmly';
    } else {
      tempScore = 20.0;
    }

    // Calculate humidity risk
    double humidityScore = 0.0;
    bool moldRisk = false;
    bool dryRisk = false;
    String humidityRec = 'Comfortable humidity levels';

    if (humidity > 80.0) {
      humidityScore = 60.0;
      moldRisk = true;
      humidityRec = 'High humidity - increased mold and discomfort risk';
    } else if (humidity > 65.0) {
      humidityScore = 40.0;
      humidityRec = 'Moderate humidity - may feel muggy';
    } else if (humidity < 30.0) {
      humidityScore = 50.0;
      dryRisk = true;
      humidityRec = 'Low humidity - may cause dry skin and respiratory irritation';
    } else {
      humidityScore = 20.0;
    }

    // Calculate stagnation risk
    double stagnationScore = 0.0;
    bool inversion = windSpeed < 2.0;
    String stagnationDesc = 'Good air circulation';

    if (windSpeed < 1.0) {
      stagnationScore = 70.0;
      stagnationDesc = 'Very low wind - poor air circulation';
    } else if (windSpeed < 2.0) {
      stagnationScore = 50.0;
      stagnationDesc = 'Low wind - limited air circulation';
    } else {
      stagnationScore = 20.0;
    }

    // Calculate UV risk
    double uvScore = uvIndex * 10.0;
    String uvRec = 'Minimal UV exposure';
    bool sunscreenNeeded = uvIndex >= 3;

    if (uvIndex >= 8) {
      uvRec = 'High UV - avoid midday sun, use strong sunscreen';
    } else if (uvIndex >= 6) {
      uvRec = 'Moderate to high UV - use sunscreen and protective clothing';
    } else if (uvIndex >= 3) {
      uvRec = 'Moderate UV - use sunscreen for extended exposure';
    }

    // Overall meteorological score
    double overallScore = (tempScore * 0.3 + humidityScore * 0.25 + stagnationScore * 0.25 + uvScore * 0.2).clamp(0, 100);

    String primaryConcern = 'Weather conditions are favorable';
    if (extremeTemp) primaryConcern = 'Extreme temperature conditions';
    else if (moldRisk) primaryConcern = 'High humidity levels';
    else if (uvIndex >= 8) primaryConcern = 'High UV radiation';
    else if (stagnationScore > 50) primaryConcern = 'Poor air circulation';

    return MeteorologicalScore(
      score: overallScore,
      level: ScoreLevelExtension.fromScore(overallScore),
      temperature: TemperatureRisk(
        celsius: temperature,
        fahrenheit: (temperature * 9/5) + 32,
        heatRisk: ScoreLevelExtension.fromScore(temperature > 30 ? 60 : 20),
        coldRisk: ScoreLevelExtension.fromScore(temperature < 0 ? 60 : 20),
        extremeTemperature: extremeTemp,
        recommendation: tempRec,
      ),
      humidity: HumidityRisk(
        relativeHumidity: humidity,
        comfortRisk: ScoreLevelExtension.fromScore(humidityScore),
        moldRisk: moldRisk,
        dryAirRisk: dryRisk,
        recommendation: humidityRec,
      ),
      airStagnation: StagnationRisk(
        level: ScoreLevelExtension.fromScore(stagnationScore),
        windSpeed: windSpeed,
        inversionPresent: inversion,
        stagnantDays: inversion ? 1 : 0,
        description: stagnationDesc,
      ),
      uvIndex: UvIndexRisk(
        uvIndex: uvIndex,
        risk: ScoreLevelExtension.fromScore(uvScore),
        recommendation: uvRec,
        sunscreenRequired: sunscreenNeeded,
      ),
      primaryConcern: primaryConcern,
    );
  }

  static WildfireScore _calculateWildfireScore(Map<String, dynamic>? data) {
    // For now, provide baseline wildfire data
    // In a real implementation, this would parse NASA FIRMS or other wildfire APIs
    double smokeConcentration = 5.0;
    double visibility = 15.0;
    int fireCount = 0;
    double? fireDistance;

    if (data != null && data.containsKey('features')) {
      final features = data['features'] as List<dynamic>;
      fireCount = features.length;

      if (fireCount > 0) {
        smokeConcentration = 25.0 + (fireCount * 5.0);
        visibility = max(5.0, 15.0 - fireCount);
        // Calculate distance to closest fire (simplified)
        fireDistance = 10.0 + Random().nextDouble() * 50.0;
      }
    }

    double score = 0.0;
    String riskDesc = 'No wildfire activity detected';

    if (fireCount > 5) {
      score = 85.0;
      riskDesc = 'Multiple wildfires in area - severe smoke impact';
    } else if (fireCount > 2) {
      score = 65.0;
      riskDesc = 'Several wildfires nearby - moderate smoke impact';
    } else if (fireCount > 0) {
      score = 45.0;
      riskDesc = 'Wildfire activity detected - light smoke possible';
    } else {
      score = 10.0;
    }

    return WildfireScore(
      score: score,
      level: ScoreLevelExtension.fromScore(score),
      smokeConcentration: smokeConcentration,
      visibility: visibility,
      nearbyFireCount: fireCount,
      closestFireDistance: fireDistance,
      riskDescription: riskDesc,
    );
  }

  static IndoorEnvironmentScore _calculateIndoorEnvironmentScore(double lat, double lon) {
    // Indoor environment scoring based on EPA radon zone maps and general factors
    // This would ideally integrate with user-provided indoor air quality data

    // Estimate radon risk based on geographic location (simplified EPA zone mapping)
    double radonLevel = 2.0; // Default safe level
    ScoreLevel radonRisk = ScoreLevel.good;
    bool requiresTesting = false;
    String radonRec = 'Radon levels appear normal';

    // Very simplified geographic radon estimation
    // Real implementation would use EPA radon zone database
    if (lat > 40.0 && lat < 45.0 && lon > -85.0 && lon < -75.0) { // Great Lakes region
      radonLevel = 3.5;
      radonRisk = ScoreLevel.moderate;
      requiresTesting = true;
      radonRec = 'Consider radon testing - moderate risk area';
    }

    double score = (radonLevel / 4.0) * 100 * 0.4 + 30.0; // Base indoor score

    return IndoorEnvironmentScore(
      score: score.clamp(0, 100),
      level: ScoreLevelExtension.fromScore(score),
      radon: RadonRisk(
        level: radonLevel,
        risk: radonRisk,
        requiresTesting: requiresTesting,
        recommendation: radonRec,
      ),
      combustion: CombustionRisk(
        risk: ScoreLevel.good,
        gasStovePresent: false, // Would come from user profile
        fireplaceFactor: false,
        vehicleExposure: false,
        recommendation: 'Monitor combustion sources in home',
      ),
      volatileOrganicCompounds: VocRisk(
        risk: ScoreLevel.good,
        cleaningProducts: false,
        newFurniture: false,
        paintFumes: false,
        recommendation: 'Ensure good ventilation when using VOC sources',
      ),
      mold: MoldRisk(
        risk: ScoreLevel.good,
        highHumidity: false,
        waterDamage: false,
        poorVentilation: false,
        recommendation: 'Monitor humidity levels and ventilation',
      ),
      primaryConcern: radonLevel > 2.5 ? 'Potential radon exposure' : 'Indoor environment appears healthy',
    );
  }

  static OverallEnvironmentalScore _calculateOverallScore(
    AirQualityScore airQuality,
    IndoorEnvironmentScore indoor,
    AeroallergenScore pollen,
    MeteorologicalScore weather,
    WildfireScore wildfire,
  ) {
    // Weighted overall score calculation
    double overallScore = (
      airQuality.score * 0.25 +
      weather.score * 0.25 +
      wildfire.score * 0.20 +
      pollen.score * 0.15 +
      indoor.score * 0.15
    ).clamp(0, 100);

    List<String> concerns = [];
    List<String> recommendations = [];

    // Collect primary concerns
    if (airQuality.score > 60) concerns.add(airQuality.primaryConcern);
    if (weather.score > 60) concerns.add(weather.primaryConcern);
    if (wildfire.score > 60) concerns.add(wildfire.riskDescription);
    if (pollen.score > 60) concerns.add('High ${pollen.dominantAllergen}');
    if (indoor.score > 60) concerns.add(indoor.primaryConcern);

    // Generate recommendations
    bool safeForOutdoor = overallScore < 50 && wildfire.score < 60 && airQuality.score < 60;
    bool safeForExercise = overallScore < 40 && weather.score < 50;
    bool windowsOpen = airQuality.score < 50 && wildfire.score < 40;

    if (!safeForOutdoor) recommendations.add('Limit outdoor activities');
    if (!safeForExercise) recommendations.add('Avoid strenuous outdoor exercise');
    if (!windowsOpen) recommendations.add('Keep windows closed');
    if (weather.uvIndex.sunscreenRequired) recommendations.add('Use sunscreen');

    return OverallEnvironmentalScore(
      score: overallScore,
      level: ScoreLevelExtension.fromScore(overallScore),
      primaryConcerns: concerns.isEmpty ? ['No significant environmental concerns'] : concerns,
      recommendations: recommendations.isEmpty ? ['Conditions are favorable for all activities'] : recommendations,
      safeForOutdoorActivity: safeForOutdoor,
      safeForExercise: safeForExercise,
      windowsRecommendation: windowsOpen,
    );
  }
}