import 'dart:async';
import 'api_service.dart';
import 'database_service.dart';

/// Repository that manages data fetching from API and local caching
class DataRepository {
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  final _databaseService = DatabaseService();

  // Cache for current session
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidity = Duration(minutes: 5);

  // Get current environmental data for a location
  Future<Map<String, dynamic>> getEnvironmentalData({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey = 'env_${latitude}_$longitude';

    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      // Fetch from API
      final data = await ApiService.getAllEnvironmentalData(
        latitude: latitude,
        longitude: longitude,
      );

      // Update cache
      _updateCache(cacheKey, data);

      // Store in local database for offline access
      await _storeLocalData(latitude, longitude, data);

      return data;
    } catch (e) {
      // If API fails, try to get last known data from local database
      final localData = await _getLocalData(latitude, longitude);
      if (localData != null) {
        return localData;
      }
      rethrow;
    }
  }

  // Get air quality data
  Future<Map<String, dynamic>> getAirQuality({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey = 'aqi_${latitude}_$longitude';

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final data = await ApiService.getCurrentAirQuality(
        latitude: latitude,
        longitude: longitude,
      );

      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      // Return cached data if available
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey];
      }

      // Return default data
      return {
        'aqi': 0,
        'category': 'Unknown',
        'color': '#808080',
        'error': true,
      };
    }
  }

  // Get weather data
  Future<Map<String, dynamic>> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey = 'weather_${latitude}_$longitude';

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final data = await ApiService.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );

      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      // Return cached data if available
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey];
      }

      // Return default data
      return {
        'temperature': 0,
        'description': 'No data',
        'error': true,
      };
    }
  }

  // Get pollen data
  Future<Map<String, dynamic>> getPollen({
    required double latitude,
    required double longitude,
  }) async {
    final cacheKey = 'pollen_${latitude}_$longitude';

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final data = await ApiService.getPollenData(
        latitude: latitude,
        longitude: longitude,
      );

      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      // Return cached data if available
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey];
      }

      // Return default data
      return {
        'treePollen': 0,
        'grassPollen': 0,
        'weedPollen': 0,
        'overallRisk': 'Low',
        'error': true,
      };
    }
  }

  // Get weather forecast
  Future<Map<String, dynamic>> getWeatherForecast({
    required double latitude,
    required double longitude,
    int days = 5,
  }) async {
    final cacheKey = 'forecast_${latitude}_${longitude}_$days';

    if (_isCacheValid(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final data = await ApiService.getWeatherForecast(
        latitude: latitude,
        longitude: longitude,
        days: days,
      );

      _updateCache(cacheKey, data);
      return data;
    } catch (e) {
      // Return cached data if available
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey];
      }

      return {'daily': [], 'hourly': [], 'error': true};
    }
  }

  // Get health recommendations (requires auth)
  Future<Map<String, dynamic>> getHealthRecommendations({
    required double latitude,
    required double longitude,
  }) async {
    if (!ApiService.isAuthenticated) {
      // Return basic recommendations without medical profile
      final envData = await getEnvironmentalData(
        latitude: latitude,
        longitude: longitude,
      );

      return _generateBasicRecommendations(envData);
    }

    try {
      final data = await ApiService.getHealthRecommendations(
        latitude: latitude,
        longitude: longitude,
      );

      return data;
    } catch (e) {
      // Generate basic recommendations from environmental data
      final envData = await getEnvironmentalData(
        latitude: latitude,
        longitude: longitude,
      );

      return _generateBasicRecommendations(envData);
    }
  }

  // Pin management (requires auth)
  Future<List<dynamic>> getUserPins() async {
    if (!ApiService.isAuthenticated) {
      // Return pins from local database
      final db = await _databaseService.database;
      final pins = await db.query('pins');
      return pins;
    }

    try {
      final pins = await ApiService.getPins(includeCurrentData: true);

      // Sync with local database
      final db = await _databaseService.database;
      for (final pin in pins) {
        await db.insert('pins', {
          'name': pin['name'],
          'latitude': pin['latitude'],
          'longitude': pin['longitude'],
          'address': pin['address'],
        });
      }

      return pins;
    } catch (e) {
      // Return local pins if API fails
      final db = await _databaseService.database;
      final pins = await db.query('pins');
      return pins;
    }
  }

  Future<Map<String, dynamic>?> createPin({
    required String name,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    // Save locally first
    final db = await _databaseService.database;
    await db.insert('pins', {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    });

    // If authenticated, sync with backend
    if (ApiService.isAuthenticated) {
      try {
        final pin = await ApiService.createPin(
          name: name,
          latitude: latitude,
          longitude: longitude,
          address: address,
        );

        return pin;
      } catch (e) {
        // Pin is saved locally, can sync later
        print('Failed to sync pin with backend: $e');
      }
    }

    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'local': true,
    };
  }

  // Helper methods
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now();

    return now.difference(timestamp) < _cacheValidity;
  }

  void _updateCache(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  Future<void> _storeLocalData(
    double latitude,
    double longitude,
    Map<String, dynamic> data,
  ) async {
    try {
      // Store in local database for offline access
      // This is a simplified version - you might want to create specific tables
      await _databaseService.database.then((db) {
        // Implementation depends on your database schema
      });
    } catch (e) {
      print('Failed to store local data: $e');
    }
  }

  Future<Map<String, dynamic>?> _getLocalData(
    double latitude,
    double longitude,
  ) async {
    try {
      // Retrieve from local database
      // This is a simplified version
      return null;
    } catch (e) {
      print('Failed to get local data: $e');
      return null;
    }
  }

  Map<String, dynamic> _generateBasicRecommendations(
    Map<String, dynamic> envData,
  ) {
    final recommendations = {
      'general': <String>[],
      'outdoor': <String>[],
      'indoor': <String>[],
      'riskLevel': 'Low',
    } as Map<String, dynamic>;

    // Parse AQI
    final airQuality = envData['airQuality'];
    if (airQuality != null && airQuality['aqi'] != null) {
      final aqi = airQuality['aqi'];

      if (aqi > 150) {
        recommendations['riskLevel'] = 'High';
        (recommendations['general'] as List<String>).add('Air quality is poor. Limit outdoor activities.');
        (recommendations['indoor'] as List<String>).add('Keep windows closed and use air purifiers if available.');
      } else if (aqi > 100) {
        recommendations['riskLevel'] = 'Moderate';
        (recommendations['general'] as List<String>).add('Air quality is moderate. Sensitive groups should limit prolonged outdoor exposure.');
      } else if (aqi > 50) {
        (recommendations['general'] as List<String>).add('Air quality is acceptable for most people.');
      } else {
        (recommendations['general'] as List<String>).add('Air quality is good. Enjoy outdoor activities!');
      }
    }

    // Parse weather
    final weather = envData['weather'];
    if (weather != null && weather['temperature'] != null) {
      final temp = weather['temperature'];

      if (temp > 32) {
        (recommendations['outdoor'] as List<String>).add('High temperature alert. Stay hydrated and seek shade.');
      } else if (temp < 0) {
        (recommendations['outdoor'] as List<String>).add('Cold weather alert. Dress warmly in layers.');
      }
    }

    // Parse pollen
    final pollen = envData['pollen'];
    if (pollen != null) {
      final maxPollen = [
        pollen['treePollen'] ?? 0,
        pollen['grassPollen'] ?? 0,
        pollen['weedPollen'] ?? 0,
      ].reduce((a, b) => a > b ? a : b);

      if (maxPollen > 4) {
        (recommendations['outdoor'] as List<String>).add('High pollen levels. Consider taking allergy medication.');
      }
    }

    return {
      'recommendations': recommendations,
      'environmentalData': envData,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}