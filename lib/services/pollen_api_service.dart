import 'package:flutter/foundation.dart';
import '../models/pollen_data.dart';
import 'api_service.dart';

/// Google Maps Pollen API Service (via Backend)
///
/// Implementation that uses the backend server to fetch pollen data
/// from Google's Pollen API
class PollenApiService {

  // Cache for pollen data with 6-hour validity (pollen data changes less frequently)
  static final Map<String, PollenForecast> _pollenCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidity = Duration(hours: 6);

  /// Get pollen forecast for a specific location (up to 5 days) from backend
  static Future<PollenForecast?> getPollenForecast(
    double latitude,
    double longitude, {
    int days = 5,
    String? languageCode = 'en',
    bool plantsDescription = true,
    int? pageSize,
    String? pageToken,
  }) async {
    final cacheKey = 'pollen_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}_$days';

    // Check cache first (6-hour validity for pollen data)
    if (_isCacheValid(cacheKey)) {
      debugPrint('Returning cached pollen data for $cacheKey');
      return _pollenCache[cacheKey];
    }

    try {
      final data = await ApiService.getBackendPollenForecast(
        latitude: latitude,
        longitude: longitude,
        days: days,
      );

      debugPrint('Backend Pollen API Response received successfully');
      final forecast = _parsePollenResponse(data);

      if (forecast != null) {
        // Cache the result
        _updateCache(cacheKey, forecast);
        debugPrint('Cached new pollen data for $cacheKey with ${forecast.dailyInfo.length} days');
      }

      return forecast;
    } catch (e) {
      debugPrint('Exception fetching pollen data from backend: $e');
      // Try to return from cache on exception
      if (_pollenCache.containsKey(cacheKey)) {
        debugPrint('Returning stale pollen data from cache due to exception.');
        return _pollenCache[cacheKey];
      }
      return null;
    }
  }

  /// Parse the API response into our PollenForecast model
  /// Based on the response format from Google's API documentation
  static PollenForecast? _parsePollenResponse(Map<String, dynamic> data) {
    try {
      final regionCode = data['regionCode'] as String? ?? '';
      final dailyInfoList = data['dailyInfo'] as List<dynamic>?;

      if (dailyInfoList == null || dailyInfoList.isEmpty) {
        debugPrint('No daily pollen info in response');
        return null;
      }

      final List<PollenDailyInfo> dailyInfo = [];
      for (final dayData in dailyInfoList) {
        final parsedDay = _parseDailyInfo(dayData as Map<String, dynamic>);
        if (parsedDay != null) {
          dailyInfo.add(parsedDay);
        }
      }

      if (dailyInfo.isEmpty) {
        debugPrint('No valid daily pollen info parsed');
        return null;
      }

      return PollenForecast(
        regionCode: regionCode,
        dailyInfo: dailyInfo,
      );
    } catch (e) {
      debugPrint('Error parsing pollen response: $e');
      return null;
    }
  }

  /// Parse daily pollen information according to Google API response format
  static PollenDailyInfo? _parseDailyInfo(Map<String, dynamic> dayData) {
    try {
      // Parse date according to Google API format: {year: 2023, month: 7, day: 11}
      final dateMap = dayData['date'] as Map<String, dynamic>?;
      if (dateMap == null) {
        debugPrint('No date found in daily info');
        return null;
      }

      final year = dateMap['year'] as int?;
      final month = dateMap['month'] as int?;
      final day = dateMap['day'] as int?;

      if (year == null || month == null || day == null) {
        debugPrint('Invalid date components in daily info');
        return null;
      }

      final date = DateTime(year, month, day);

      // Parse pollen type info (GRASS, TREE, WEED)
      final pollenTypeInfoList = dayData['pollenTypeInfo'] as List<dynamic>? ?? [];
      final List<PollenTypeInfo> pollenTypeInfo = [];

      for (final typeData in pollenTypeInfoList) {
        final parsedType = _parsePollenTypeInfo(typeData as Map<String, dynamic>);
        if (parsedType != null) {
          pollenTypeInfo.add(parsedType);
        }
      }

      // Parse plant info (specific plants like BIRCH, OAK, etc.)
      final plantInfoList = dayData['plantInfo'] as List<dynamic>? ?? [];
      final List<PlantInfo> plantInfo = [];

      for (final plantData in plantInfoList) {
        final parsedPlant = _parsePlantInfo(plantData as Map<String, dynamic>);
        if (parsedPlant != null) {
          plantInfo.add(parsedPlant);
        }
      }

      return PollenDailyInfo(
        date: date,
        pollenTypeInfo: pollenTypeInfo,
        plantInfo: plantInfo,
      );
    } catch (e) {
      debugPrint('Error parsing daily pollen info: $e');
      return null;
    }
  }

  /// Parse pollen type info (GRASS, TREE, WEED) according to Google API format
  static PollenTypeInfo? _parsePollenTypeInfo(Map<String, dynamic> typeData) {
    try {
      final codeStr = typeData['code'] as String?;
      final displayName = typeData['displayName'] as String? ?? '';
      final inSeason = typeData['inSeason'] as bool? ?? false;

      if (codeStr == null) {
        debugPrint('No code found in pollen type info');
        return null;
      }

      // Map API codes to our PollenType enum
      PollenType? code;
      switch (codeStr.toUpperCase()) {
        case 'GRASS':
          code = PollenType.grass;
          break;
        case 'TREE':
          code = PollenType.tree;
          break;
        case 'WEED':
          code = PollenType.weed;
          break;
        default:
          debugPrint('Unknown pollen type code: $codeStr');
          return null;
      }

      // Parse index info
      final indexInfoData = typeData['indexInfo'] as Map<String, dynamic>?;
      PollenIndexInfo? indexInfo;
      if (indexInfoData != null) {
        indexInfo = _parseIndexInfo(indexInfoData);
      }

      // Parse health recommendation (can be array of strings or object)
      final healthRecData = typeData['healthRecommendations'];
      PollenHealthRecommendation? healthRecommendation;
      if (healthRecData != null) {
        healthRecommendation = _parseHealthRecommendation(healthRecData);
      }

      return PollenTypeInfo(
        code: code,
        displayName: displayName,
        inSeason: inSeason,
        indexInfo: indexInfo,
        healthRecommendation: healthRecommendation,
      );
    } catch (e) {
      debugPrint('Error parsing pollen type info: $e');
      return null;
    }
  }

  /// Parse plant info (specific plants like BIRCH, OAK, etc.) according to Google API format
  static PlantInfo? _parsePlantInfo(Map<String, dynamic> plantData) {
    try {
      final codeStr = plantData['code'] as String?;
      final displayName = plantData['displayName'] as String? ?? '';
      final inSeason = plantData['inSeason'] as bool? ?? false;

      if (codeStr == null) {
        debugPrint('No code found in plant info');
        return null;
      }

      // Map API codes to our PlantType enum
      PlantType? code;
      switch (codeStr.toUpperCase()) {
        case 'ALDER':
          code = PlantType.alder;
          break;
        case 'BIRCH':
          code = PlantType.birch;
          break;
        case 'CYPRESS':
          code = PlantType.cypress;
          break;
        case 'ELM':
          code = PlantType.elm;
          break;
        case 'HAZEL':
          code = PlantType.hazel;
          break;
        case 'OAK':
          code = PlantType.oak;
          break;
        case 'PINE':
          code = PlantType.pine;
          break;
        case 'PLANE':
          code = PlantType.plane;
          break;
        case 'POPLAR':
          code = PlantType.poplar;
          break;
        case 'ASH':
          code = PlantType.ash;
          break;
        case 'COTTONWOOD':
          code = PlantType.cottonwood;
          break;
        case 'GRAMINALES':
          code = PlantType.graminales;
          break;
        case 'RAGWEED':
          code = PlantType.ragweed;
          break;
        case 'MUGWORT':
          code = PlantType.mugwort;
          break;
        case 'OLIVE':
          code = PlantType.olive;
          break;
        case 'JUNIPER':
          code = PlantType.juniper;
          break;
        case 'CHENOPOD':
          code = PlantType.chenopod;
          break;
        default:
          debugPrint('Unknown plant type code: $codeStr');
          // Return null for unknown plant types or create a fallback
          return null;
      }

      // Parse index info
      final indexInfoData = plantData['indexInfo'] as Map<String, dynamic>?;
      PollenIndexInfo? indexInfo;
      if (indexInfoData != null) {
        indexInfo = _parseIndexInfo(indexInfoData);
      }

      // Parse plant description
      final descriptionData = plantData['plantDescription'] as Map<String, dynamic>?;
      PlantDescription? plantDescription;
      if (descriptionData != null) {
        plantDescription = _parsePlantDescription(descriptionData);
      }

      return PlantInfo(
        code: code,
        displayName: displayName,
        inSeason: inSeason,
        indexInfo: indexInfo,
        plantDescription: plantDescription,
      );
    } catch (e) {
      debugPrint('Error parsing plant info: $e');
      return null;
    }
  }

  /// Parse index info (Universal Pollen Index) according to Google API format
  static PollenIndexInfo? _parseIndexInfo(Map<String, dynamic> indexData) {
    try {
      final value = indexData['value'] as int? ?? 0;
      final indexDescription = indexData['indexDescription'] as String? ?? '';

      // Parse category according to Google API format
      final categoryStr = indexData['category'] as String?;
      PollenIndexCategory category = PollenIndexCategory.none;

      if (categoryStr != null) {
        switch (categoryStr) {
          case 'None':
            category = PollenIndexCategory.none;
            break;
          case 'Very Low':
            category = PollenIndexCategory.veryLow;
            break;
          case 'Low':
            category = PollenIndexCategory.low;
            break;
          case 'Moderate':
            category = PollenIndexCategory.moderate;
            break;
          case 'High':
            category = PollenIndexCategory.high;
            break;
          case 'Very High':
            category = PollenIndexCategory.veryHigh;
            break;
          default:
            debugPrint('Unknown pollen index category: $categoryStr');
            category = PollenIndexCategory.none;
        }
      }

      // Parse color
      final colorData = indexData['color'] as Map<String, dynamic>?;
      Color? color;
      if (colorData != null) {
        color = _parseColor(colorData);
      }

      return PollenIndexInfo(
        value: value,
        category: category,
        indexDescription: indexDescription,
        color: color,
      );
    } catch (e) {
      debugPrint('Error parsing index info: $e');
      return null;
    }
  }

  /// Parse color information according to Google API format
  static Color? _parseColor(Map<String, dynamic> colorData) {
    try {
      final red = (colorData['red'] as num?)?.toDouble() ?? 0.0;
      final green = (colorData['green'] as num?)?.toDouble() ?? 0.0;
      final blue = (colorData['blue'] as num?)?.toDouble() ?? 0.0;
      final alpha = (colorData['alpha'] as num?)?.toDouble();

      return Color(
        red: red,
        green: green,
        blue: blue,
        alpha: alpha,
      );
    } catch (e) {
      debugPrint('Error parsing color: $e');
      return null;
    }
  }

  /// Parse health recommendation according to Google API format
  /// Google API returns an array of strings, not an object
  static PollenHealthRecommendation? _parseHealthRecommendation(dynamic healthData) {
    try {
      if (healthData is List) {
        // Google API returns health recommendations as an array of strings
        final recommendations = healthData.cast<String>();
        final generalRecommendation = recommendations.isNotEmpty 
            ? recommendations.join(' ') 
            : 'No recommendations available';
        
        return PollenHealthRecommendation(
          generalPopulation: generalRecommendation,
        );
      } else if (healthData is Map<String, dynamic>) {
        // Fallback for object format (if API changes)
        final generalPopulation = healthData['generalPopulation'] as String? ?? 'No recommendations available';
        final elderly = healthData['elderly'] as String?;
        final lungDiseaseAtRisk = healthData['lungDiseaseAtRisk'] as String?;
        final heartDiseaseAtRisk = healthData['heartDiseaseAtRisk'] as String?;
        final athletes = healthData['athletes'] as String?;
        final pregnantWomen = healthData['pregnantWomen'] as String?;
        final children = healthData['children'] as String?;

        return PollenHealthRecommendation(
          generalPopulation: generalPopulation,
          elderly: elderly,
          lungDiseaseAtRisk: lungDiseaseAtRisk,
          heartDiseaseAtRisk: heartDiseaseAtRisk,
          athletes: athletes,
          pregnantWomen: pregnantWomen,
          children: children,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing health recommendation: $e');
      return null;
    }
  }

  /// Parse plant description according to Google API format
  static PlantDescription? _parsePlantDescription(Map<String, dynamic> descData) {
    try {
      return PlantDescription(
        type: descData['type'] as String?,
        family: descData['family'] as String?,
        season: descData['season'] as String?,
        specialShapes: descData['specialShapes'] as String?,
        specialColors: descData['specialColors'] as String?,
        crossReaction: descData['crossReaction'] as String?,
        picture: descData['picture'] as String?,
        pictureCloseup: descData['pictureCloseup'] as String?,
      );
    } catch (e) {
      debugPrint('Error parsing plant description: $e');
      return null;
    }
  }

  /// Get the heatmap tile URL for pollen visualization
  /// Note: This method is not available through the backend and requires direct API key access
  /// Reference: https://developers.google.com/maps/documentation/pollen/heatmap-tiles
  static String? getPollenHeatmapTileUrl(PollenType pollenType, int zoom, int x, int y) {
    // This functionality would need to be implemented in the backend if needed
    // For now, return null to indicate heatmap tiles are not available
    debugPrint('Pollen heatmap tiles are not available through backend implementation');
    return null;
  }

  /// Get today's pollen forecast for quick access
  static PollenDailyInfo? getTodaysPollen(PollenForecast forecast) {
    final today = DateTime.now();
    try {
      return forecast.dailyInfo.firstWhere(
        (day) =>
          day.date.year == today.year &&
          day.date.month == today.month &&
          day.date.day == today.day,
      );
    } catch (e) {
      // If today's data isn't available, return the first available day
      return forecast.dailyInfo.isNotEmpty ? forecast.dailyInfo.first : null;
    }
  }

  /// Check if cache is valid for a given key
  static bool _isCacheValid(String key) {
    if (!_pollenCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now();

    return now.difference(timestamp) < _cacheValidity;
  }

  /// Update the cache with new data
  static void _updateCache(String key, PollenForecast forecast) {
    _pollenCache[key] = forecast;
    _cacheTimestamps[key] = DateTime.now();

    // Clean up old cache entries to prevent memory leaks
    _cleanupOldCacheEntries();
  }

  /// Clean up old cache entries to prevent memory leaks
  static void _cleanupOldCacheEntries() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheValidity) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _pollenCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      debugPrint('Cleaned up ${keysToRemove.length} old pollen cache entries');
    }
  }

  /// Clear all cached pollen data
  static void clearCache() {
    _pollenCache.clear();
    _cacheTimestamps.clear();
    debugPrint('Cleared all pollen cache data');
  }
}