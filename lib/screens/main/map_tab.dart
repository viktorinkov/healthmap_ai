import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import '../../models/pinned_location.dart';
import '../../models/air_quality.dart';
import '../../services/air_quality_api_service.dart';
import '../../services/database_service.dart';
import '../../widgets/add_location_dialog.dart';
import '../../widgets/pin_info_dialog.dart';

class MapTab extends StatefulWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  GoogleMapController? _mapController;
  final Location _location = Location();
  LatLng _currentLocation = const LatLng(29.7174, -95.4018); // Rice University, Houston
  List<PinnedLocation> _pinnedLocations = [];
  Map<String, AirQualityData> _locationAirQuality = {};
  Set<Marker> _markers = {};
  Set<TileOverlay> _tileOverlays = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Get current location
      await _getCurrentLocation();

      // Load pinned locations
      _pinnedLocations = await DatabaseService().getPinnedLocations();

      // Load air quality data for pinned locations
      await _loadAirQualityForLocations();

      // Create markers and heatmap overlay
      _createMarkersAndOverlays();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing map data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      LocationData locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _loadAirQualityForLocations() async {
    _locationAirQuality.clear();

    // Load air quality for each pinned location
    for (final location in _pinnedLocations) {
      // Try to find existing air quality data for this specific location
      final existingData = await DatabaseService().getAirQualityData();
      final locationSpecificData = existingData.where((data) =>
        data.locationName.toLowerCase().contains(location.name.toLowerCase()) ||
        (data.latitude - location.latitude).abs() < 0.01 &&
        (data.longitude - location.longitude).abs() < 0.01
      ).toList();

      if (locationSpecificData.isNotEmpty) {
        _locationAirQuality[location.id] = locationSpecificData.first;
      } else {
        // Generate sample air quality data for this location
        _locationAirQuality[location.id] = _generateSampleAirQualityData(location);
        // Save to database for future use
        await DatabaseService().saveAirQualityData(_locationAirQuality[location.id]!);
      }
    }
  }

  AirQualityData _generateSampleAirQualityData(PinnedLocation location) {
    // Generate realistic but varied air quality data based on location type and coordinates
    final random = DateTime.now().millisecond + location.hashCode;
    final baseVariation = (random % 100) / 100.0; // 0.0 to 1.0

    // Different base values based on location type
    Map<String, double> baseValues;
    switch (location.type) {
      case LocationType.home:
        baseValues = {'pm25': 8.0, 'pm10': 18.0, 'o3': 35.0, 'no2': 18.0};
        break;
      case LocationType.work:
        baseValues = {'pm25': 15.0, 'pm10': 30.0, 'o3': 50.0, 'no2': 30.0};
        break;
      case LocationType.gym:
        baseValues = {'pm25': 12.0, 'pm10': 25.0, 'o3': 45.0, 'no2': 25.0};
        break;
      case LocationType.school:
        baseValues = {'pm25': 10.0, 'pm10': 22.0, 'o3': 40.0, 'no2': 22.0};
        break;
      case LocationType.other:
      default:
        baseValues = {'pm25': 13.0, 'pm10': 27.0, 'o3': 47.0, 'no2': 27.0};
        break;
    }

    // Add variation based on location coordinates (simulate geographic differences)
    final latVariation = (location.latitude % 1) * 0.3; // 0.0 to 0.3
    final lngVariation = (location.longitude.abs() % 1) * 0.2; // 0.0 to 0.2

    final pm25 = (baseValues['pm25']! * (1 + (baseVariation - 0.5) * 0.4 + latVariation)).clamp(5.0, 35.0);
    final pm10 = (baseValues['pm10']! * (1 + (baseVariation - 0.5) * 0.4 + lngVariation)).clamp(10.0, 60.0);
    final o3 = (baseValues['o3']! * (1 + (baseVariation - 0.5) * 0.3 + latVariation)).clamp(20.0, 80.0);
    final no2 = (baseValues['no2']! * (1 + (baseVariation - 0.5) * 0.4 + lngVariation)).clamp(10.0, 50.0);

    // Optional pollutants with some variation
    final co = random % 3 == 0 ? (200 + (baseVariation * 300)).clamp(100.0, 800.0) : null;
    final so2 = random % 4 == 0 ? (5 + (baseVariation * 15)).clamp(2.0, 25.0) : null;

    final metrics = AirQualityMetrics(
      pm25: pm25,
      pm10: pm10,
      o3: o3,
      no2: no2,
      co: co,
      so2: so2,
      wildfireIndex: (baseVariation * 30).clamp(0.0, 40.0),
      radon: (1.5 + baseVariation * 2).clamp(1.0, 4.0),
      universalAqi: null, // Will be calculated
    );

    final status = AirQualityStatusExtension.fromScore(metrics.overallScore);

    return AirQualityData(
      id: '${location.id}_${DateTime.now().millisecondsSinceEpoch}',
      locationName: location.name,
      latitude: location.latitude,
      longitude: location.longitude,
      timestamp: DateTime.now().subtract(Duration(minutes: random % 120)),
      metrics: metrics,
      status: status,
      statusReason: _generateStatusReason(metrics, status),
    );
  }

  String _generateStatusReason(AirQualityMetrics metrics, AirQualityStatus status) {
    final concerns = <String>[];

    if (metrics.pm25 > 15) concerns.add('elevated PM2.5');
    if (metrics.pm10 > 30) concerns.add('elevated PM10');
    if (metrics.o3 > 50) concerns.add('high ozone');
    if (metrics.no2 > 30) concerns.add('elevated NO₂');
    if (metrics.co != null && metrics.co! > 500) concerns.add('carbon monoxide');
    if (metrics.so2 != null && metrics.so2! > 15) concerns.add('sulfur dioxide');

    switch (status) {
      case AirQualityStatus.good:
        return concerns.isEmpty
          ? 'All air quality metrics are within healthy ranges'
          : 'Generally good air quality with minor ${concerns.first} levels';
      case AirQualityStatus.caution:
        return concerns.isEmpty
          ? 'Moderate air quality - sensitive individuals should be cautious'
          : 'Moderate air quality due to ${concerns.take(2).join(' and ')}';
      case AirQualityStatus.avoid:
        return concerns.isEmpty
          ? 'Poor air quality - limit outdoor exposure'
          : 'Poor air quality due to ${concerns.take(2).join(' and ')} - avoid prolonged outdoor activities';
    }
  }

  void _createMarkersAndOverlays() {
    Set<Marker> markers = {};
    Set<TileOverlay> tileOverlays = {};

    // Create air quality heatmap overlay
    tileOverlays.add(
      TileOverlay(
        tileOverlayId: const TileOverlayId('air_quality_heatmap'),
        tileProvider: AirQualityTileProvider(),
        transparency: 0.3, // Make overlay semi-transparent
        fadeIn: true,
      ),
    );

    // Add pinned location markers
    for (final location in _pinnedLocations) {
      markers.add(
        Marker(
          markerId: MarkerId('pinned_${location.id}'),
          position: LatLng(location.latitude, location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: '${location.type.icon} ${location.name}',
            snippet: location.address ?? location.type.displayName,
            onTap: () => _showPinnedLocationDetails(location),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
      _tileOverlays = tileOverlays;
    });
  }


  void _showPinnedLocationDetails(PinnedLocation location) {
    showDialog(
      context: context,
      builder: (context) => PinInfoDialog(
        location: location,
        airQuality: _locationAirQuality[location.id],
      ),
    );
  }

  void _onMapTapped(LatLng position) {
    _showAddLocationDialog(position);
  }

  void _showAddLocationDialog(LatLng position) {
    showDialog(
      context: context,
      builder: (context) => AddLocationDialog(
        position: position,
        onLocationAdded: (location) {
          setState(() {
            _pinnedLocations.add(location);
          });
          _createMarkersAndOverlays();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Quality Map'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showMapLegend,
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 12.0,
        ),
        markers: _markers,
        tileOverlays: _tileOverlays,
        onTap: _onMapTapped,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(_currentLocation),
          );
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showMapLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Air Quality Heatmap'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Real-time air quality data from Google Maps'),
            const SizedBox(height: 16),
            _buildHeatmapLegendItem(Colors.green, 'Good (0-50)', 'Air quality is satisfactory'),
            _buildHeatmapLegendItem(Colors.yellow, 'Moderate (51-100)', 'Acceptable for most people'),
            _buildHeatmapLegendItem(Colors.orange, 'Unhealthy for Sensitive (101-150)', 'Sensitive groups may experience symptoms'),
            _buildHeatmapLegendItem(Colors.red, 'Unhealthy (151-200)', 'Everyone may experience health effects'),
            _buildHeatmapLegendItem(Colors.purple, 'Very Unhealthy (201-300)', 'Health alert for everyone'),
            const Divider(),
            _buildLegendItem(Colors.purple, 'Pinned Location', 'Your saved locations'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegendItem(Color color, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom tile provider for Google Air Quality API heatmap
/// Bounds the heatmap to the Houston metropolitan area
class AirQualityTileProvider extends TileProvider {
  // Houston metropolitan area bounds
  static const double _houstonNorthBound = 30.1;    // North Harris County
  static const double _houstonSouthBound = 29.4;    // South of Sugar Land
  static const double _houstonWestBound = -95.8;    // West of Katy
  static const double _houstonEastBound = -94.9;    // East of Baytown

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null) return const Tile(256, 256, null);

    // Check if this tile intersects with Houston area
    if (!_tileIntersectsHouston(x, y, zoom)) {
      return const Tile(256, 256, null); // Return empty tile outside Houston
    }

    try {
      final tileUrl = AirQualityApiService.getHeatmapTileUrl(zoom, x, y);
      final response = await http.get(Uri.parse(tileUrl));

      if (response.statusCode == 200) {
        return Tile(256, 256, response.bodyBytes);
      } else {
        // Return empty tile on error
        return const Tile(256, 256, null);
      }
    } catch (e) {
      debugPrint('Error loading air quality tile: $e');
      return const Tile(256, 256, null);
    }
  }

  /// Check if a tile intersects with the Houston metropolitan area
  bool _tileIntersectsHouston(int x, int y, int zoom) {
    // Convert tile coordinates to lat/lng bounds
    final tileBounds = _getTileBounds(x, y, zoom);

    // Check if tile overlaps with Houston bounds
    return tileBounds['north']! >= _houstonSouthBound &&
           tileBounds['south']! <= _houstonNorthBound &&
           tileBounds['east']! >= _houstonWestBound &&
           tileBounds['west']! <= _houstonEastBound;
  }

  /// Convert tile coordinates to lat/lng bounds
  Map<String, double> _getTileBounds(int x, int y, int zoom) {
    // Calculate bounds
    final north = _tile2lat(y, zoom);
    final south = _tile2lat(y + 1, zoom);
    final west = _tile2lng(x, zoom);
    final east = _tile2lng(x + 1, zoom);

    return {
      'north': north,
      'south': south,
      'west': west,
      'east': east,
    };
  }

  /// Convert tile Y coordinate to latitude
  double _tile2lat(int y, int zoom) {
    final n = 1 << zoom;
    final latRad = math.atan(_sinh(math.pi * (1 - 2 * y / n)));
    return latRad * 180.0 / math.pi;
  }

  /// Helper function for hyperbolic sine (sinh)
  double _sinh(double x) {
    return (math.exp(x) - math.exp(-x)) / 2;
  }

  /// Convert tile X coordinate to longitude
  double _tile2lng(int x, int zoom) {
    final n = 1 << zoom;
    return x / n * 360.0 - 180.0;
  }
}
