import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RunCoachHeatmapTileProvider extends TileProvider {
  static const String _backendUrl = 'http://168.5.158.82:5001/api/run-coach';
  static const int _tileSize = 256;
  
  // Cache for tiles to avoid repeated API calls
  final Map<String, Uint8List> _tileCache = {};
  
  // Limit cache size to prevent memory issues
  static const int _maxCacheSize = 50;
  
  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null) return const Tile(_tileSize, _tileSize, null);
    
    // Create a unique cache key
    final cacheKey = '${zoom}_${x}_$y';
    
    // Check cache first
    if (_tileCache.containsKey(cacheKey)) {
      return Tile(_tileSize, _tileSize, _tileCache[cacheKey]!);
    }
    
    // Only render tiles at certain zoom levels for performance
    if (zoom < 10 || zoom > 16) {
      return Tile(_tileSize, _tileSize, _createTransparentTile());
    }
    
    try {
      // Convert tile coordinates to lat/lon bounds
      final bounds = _tileToBounds(x, y, zoom);
      
      // Fetch pollution data for this tile area
      final pollutionData = await _fetchPollutionData(
        bounds['north']!,
        bounds['south']!,
        bounds['west']!,
        bounds['east']!,
      );
      
      // Generate heatmap tile image
      final tileBytes = await _generateHeatmapTile(pollutionData);
      
      // Cache the tile with size limit
      if (_tileCache.length >= _maxCacheSize) {
        // Remove oldest entry
        _tileCache.remove(_tileCache.keys.first);
      }
      _tileCache[cacheKey] = tileBytes;
      
      return Tile(_tileSize, _tileSize, tileBytes);
    } catch (e) {
      print('Error generating heatmap tile: $e');
      // Return transparent tile on error
      return Tile(_tileSize, _tileSize, _createTransparentTile());
    }
  }
  
  /// Convert tile coordinates to latitude/longitude bounds
  Map<String, double> _tileToBounds(int x, int y, int zoom) {
    final n = math.pow(2.0, zoom);
    final west = x / n * 360.0 - 180.0;
    final east = (x + 1) / n * 360.0 - 180.0;
    
    final nw = math.atan(math.sinh(math.pi * (1 - 2 * y / n)));
    final north = nw * 180.0 / math.pi;
    
    final sw = math.atan(math.sinh(math.pi * (1 - 2 * (y + 1) / n)));
    final south = sw * 180.0 / math.pi;
    
    return {
      'north': north,
      'south': south,
      'west': west,
      'east': east,
    };
  }
  
  /// Fetch pollution data from backend
  Future<Map<String, dynamic>> _fetchPollutionData(
    double north,
    double south,
    double west,
    double east,
  ) async {
    try {
      // Calculate center and radius from bounds
      final centerLat = (north + south) / 2;
      final centerLon = (west + east) / 2;
      
      // Calculate approximate radius in km
      final latDiff = (north - south).abs();
      final lonDiff = (west - east).abs();
      final radiusKm = math.max(latDiff, lonDiff) * 111; // Approximate km per degree
      
      // Fetch pollution heatmap data
      final url = Uri.parse('$_backendUrl/pollution-heatmap').replace(
        queryParameters: {
          'lat': centerLat.toString(),
          'lon': centerLon.toString(),
          'radius_km': radiusKm.toString(),
          'pollutant': 'aqi',
        },
      );
      
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to fetch pollution data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching pollution data: $e');
      // Return empty data on error
      return {
        'values': [],
        'bounds': {
          'min_lat': south,
          'max_lat': north,
          'min_lon': west,
          'max_lon': east,
        },
      };
    }
  }
  
  /// Generate heatmap tile image from pollution data
  Future<Uint8List> _generateHeatmapTile(Map<String, dynamic> pollutionData) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _tileSize.toDouble(), _tileSize.toDouble()));
    
    // Get pollution values grid
    final values = pollutionData['values'] as List<dynamic>? ?? [];
    if (values.isEmpty) {
      return _createTransparentTile();
    }
    
    // Get bounds
    final bounds = pollutionData['bounds'] as Map<String, dynamic>?;
    if (bounds == null) {
      return _createTransparentTile();
    }
    
    final minLat = bounds['min_lat'] as double;
    final maxLat = bounds['max_lat'] as double;
    final minLon = bounds['min_lon'] as double;
    final maxLon = bounds['max_lon'] as double;
    
    // Draw pollution data as colored rectangles
    final gridHeight = values.length;
    final gridWidth = values.isNotEmpty ? (values[0] as List).length : 0;
    
    if (gridHeight == 0 || gridWidth == 0) {
      return _createTransparentTile();
    }
    
    final cellWidth = _tileSize.toDouble() / gridWidth;
    final cellHeight = _tileSize.toDouble() / gridHeight;
    
    for (int row = 0; row < gridHeight; row++) {
      final rowData = values[row] as List<dynamic>;
      for (int col = 0; col < gridWidth; col++) {
        final aqi = (rowData[col] as num).toDouble();
        final color = _getColorForAQI(aqi);
        
        final paint = Paint()
          ..color = color.withAlpha(180) // Semi-transparent
          ..style = PaintingStyle.fill;
        
        canvas.drawRect(
          Rect.fromLTWH(
            col * cellWidth,
            row * cellHeight,
            cellWidth,
            cellHeight,
          ),
          paint,
        );
      }
    }
    
    final picture = recorder.endRecording();
    final image = await picture.toImage(_tileSize, _tileSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
  
  /// Get color for AQI value
  Color _getColorForAQI(double aqi) {
    if (aqi <= 50) {
      return Colors.green; // Good
    } else if (aqi <= 100) {
      return Colors.yellow; // Moderate
    } else if (aqi <= 150) {
      return Colors.orange; // Unhealthy for sensitive groups
    } else if (aqi <= 200) {
      return Colors.red; // Unhealthy
    } else if (aqi <= 300) {
      return Colors.purple; // Very unhealthy
    } else {
      return Colors.brown; // Hazardous
    }
  }
  
  /// Create a transparent tile
  Uint8List _createTransparentTile() {
    final transparentPixels = Uint8List(_tileSize * _tileSize * 4);
    return transparentPixels;
  }
}