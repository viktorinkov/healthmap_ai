import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import '../../models/pinned_location.dart';
import '../../models/air_quality.dart';
import '../../models/user_health_profile.dart';
import '../../services/air_quality_api_service.dart';
import '../../services/database_service.dart';
import '../../services/gemini_service.dart';
import '../../services/unified_air_quality_service.dart';
import '../../widgets/add_location_dialog.dart';
import '../../widgets/unified_location_card.dart';

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
  UserHealthProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Set a maximum timeout for initialization
    try {
      await _doInitializeData().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Initialization timed out after 10 seconds, continuing with current data');
        },
      );
    } catch (e) {
      debugPrint('Initialization error: $e');
    }

    // Create markers and overlays with whatever data we have
    _createMarkersAndOverlays();

    // Ensure map is shown regardless of what happens
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _doInitializeData() async {
    try {
      // Get current location (critical for map display)
      await _getCurrentLocation().timeout(const Duration(seconds: 5));

      // Load user profile (non-critical)
      try {
        _userProfile = await DatabaseService().getUserHealthProfile('user_profile').timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Error loading user profile: $e');
        _userProfile = null; // Continue without profile
      }

      // Load pinned locations (non-critical)
      try {
        _pinnedLocations = await DatabaseService().getPinnedLocations().timeout(const Duration(seconds: 3));
        debugPrint('Loaded ${_pinnedLocations.length} pinned locations from database');
        for (final loc in _pinnedLocations) {
          debugPrint('  - ${loc.name}: ${loc.latitude}, ${loc.longitude}');
        }
      } catch (e) {
        debugPrint('Error loading pinned locations: $e');
        _pinnedLocations = []; // Continue with empty list
      }

      // Load air quality data for pinned locations (non-critical)
      if (_pinnedLocations.isNotEmpty) {
        try {
          await _loadAirQualityForLocations().timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('Error loading air quality data: $e');
          _locationAirQuality = {}; // Continue with empty map
        }
      } else {
        _locationAirQuality = {}; // No pins, no data needed
      }
    } catch (e) {
      debugPrint('Error in data initialization: $e');
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
    _locationAirQuality = await UnifiedAirQualityService.getAirQualityForAllLocations(
      _pinnedLocations,
      userProfile: _userProfile,
    );
  }



  void _createMarkersAndOverlays() {
    debugPrint('Creating markers for ${_pinnedLocations.length} pinned locations');

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
      debugPrint('Adding marker for ${location.name} at ${location.latitude}, ${location.longitude}');
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

    debugPrint('Total markers created: ${markers.length}');

    setState(() {
      _markers = markers;
      _tileOverlays = tileOverlays;
    });
  }


  void _showPinnedLocationDetails(PinnedLocation location) {
    final airQuality = _locationAirQuality[location.id];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: airQuality != null
                ? FutureBuilder<Map<String, dynamic>>(
                    future: GeminiService.generateIntelligentAirQualityAssessment(
                      metrics: airQuality.metrics,
                      locationName: location.name,
                      healthRecommendations: airQuality.healthRecommendations,
                    ),
                    builder: (context, snapshot) {
                      // Create modified air quality data with Gemini assessment
                      AirQualityData enhancedAirQuality = airQuality;

                      if (snapshot.hasData && snapshot.data != null) {
                        final statusString = snapshot.data!['status'] as String;
                        final justification = snapshot.data!['justification'] as String;

                        final geminiStatus = AirQualityStatus.values.firstWhere(
                          (s) => s.name == statusString,
                          orElse: () => airQuality.status,
                        );

                        // Create new air quality data with Gemini status and justification
                        enhancedAirQuality = airQuality.copyWith(
                          status: geminiStatus,
                          statusReason: justification.isNotEmpty ? justification : airQuality.statusReason,
                        );
                      }

                      String? geminiAssessment;
                      if (snapshot.hasData && snapshot.data != null) {
                        geminiAssessment = snapshot.data!['justification'] as String;
                      } else if (snapshot.connectionState == ConnectionState.waiting) {
                        geminiAssessment = 'Analyzing air quality data...';
                      }

                      return UnifiedLocationCard(
                        location: location,
                        airQuality: enhancedAirQuality,
                        showFullDetails: true,
                        hideDetailsButton: true,
                        geminiAssessment: geminiAssessment,
                      );
                    },
                  )
                : UnifiedLocationCard(
                    location: location,
                    airQuality: null,
                    showFullDetails: true,
                    hideDetailsButton: true,
                  ),
          ),
        ),
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
