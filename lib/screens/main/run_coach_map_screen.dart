import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import '../../models/pinned_location.dart';
import '../../models/run_coach_models.dart';
import '../../models/air_quality.dart';
import '../../services/run_coach_service.dart';
import '../../services/database_service.dart';
import '../../services/air_quality_api_service.dart';
import '../../widgets/add_location_dialog.dart';
import '../../widgets/run_coach_widgets.dart';
import '../../widgets/pollution_visualizer.dart';
import '../../services/run_coach_tile_provider.dart';

class RunCoachMapScreen extends StatefulWidget {
  const RunCoachMapScreen({Key? key}) : super(key: key);

  @override
  State<RunCoachMapScreen> createState() => _RunCoachMapScreenState();
}

class _RunCoachMapScreenState extends State<RunCoachMapScreen> {
  GoogleMapController? _mapController;
  final Location _location = Location();
  final RunCoachService _runCoachService = RunCoachService();
  
  LatLng _currentLocation = const LatLng(29.7174, -95.4018); // Default: Houston
  List<PinnedLocation> _pinnedLocations = [];
  Map<String, AirQualityData> _locationAirQuality = {};
  Map<String, HealthRiskAssessment> _locationRiskAssessments = {};
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<TileOverlay> _tileOverlays = {};
  
  bool _isLoading = true;
  bool _showRoutes = false;
  bool _showTimeWindows = false;
  RunRoute? _selectedRoute;
  List<TimeWindow> _optimalTimes = [];
  
  // UI State
  bool _isBottomSheetVisible = false;
  PinnedLocation? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _getCurrentLocation();
      await _loadPinnedLocations();
      await _loadAirQualityForLocations();
      _createMarkersAndOverlays();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing Run Coach map data: $e');
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

  Future<void> _loadPinnedLocations() async {
    _pinnedLocations = await DatabaseService().getPinnedLocations();
  }

  Future<void> _loadAirQualityForLocations() async {
    _locationAirQuality.clear();
    _locationRiskAssessments.clear();

    for (final location in _pinnedLocations) {
      try {
        // Try to get existing air quality data
        final existingData = await DatabaseService().getAirQualityData();
        final locationSpecificData = existingData.where((data) =>
          (data.latitude - location.latitude).abs() < 0.01 &&
          (data.longitude - location.longitude).abs() < 0.01
        ).toList();

        AirQualityData airQualityData;
        if (locationSpecificData.isNotEmpty) {
          airQualityData = locationSpecificData.first;
        } else {
          // Generate sample data for development
          airQualityData = _generateSampleAirQualityData(location);
          await DatabaseService().saveAirQualityData(airQualityData);
        }
        
        _locationAirQuality[location.id] = airQualityData;

        // Get health risk assessment for this location
        final riskAssessment = await _runCoachService.getHealthRiskAssessment(
          currentAqi: airQualityData.metrics.universalAqi?.toDouble() ?? 
                      (100 - airQualityData.metrics.overallScore),
        );
        _locationRiskAssessments[location.id] = riskAssessment;
        
      } catch (e) {
        debugPrint('Error loading data for location ${location.name}: $e');
      }
    }
  }

  AirQualityData _generateSampleAirQualityData(PinnedLocation location) {
    // Generate realistic air quality data based on location type
    final random = DateTime.now().millisecond + location.hashCode;
    final baseVariation = (random % 100) / 100.0;

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

    final latVariation = (location.latitude % 1) * 0.3;
    final lngVariation = (location.longitude.abs() % 1) * 0.2;

    final pm25 = (baseValues['pm25']! * (1 + (baseVariation - 0.5) * 0.4 + latVariation)).clamp(5.0, 35.0);
    final pm10 = (baseValues['pm10']! * (1 + (baseVariation - 0.5) * 0.4 + lngVariation)).clamp(10.0, 60.0);
    final o3 = (baseValues['o3']! * (1 + (baseVariation - 0.5) * 0.3 + latVariation)).clamp(20.0, 80.0);
    final no2 = (baseValues['no2']! * (1 + (baseVariation - 0.5) * 0.4 + lngVariation)).clamp(10.0, 50.0);

    final metrics = AirQualityMetrics(
      pm25: pm25,
      pm10: pm10,
      o3: o3,
      no2: no2,
      co: random % 3 == 0 ? (200 + (baseVariation * 300)).clamp(100.0, 800.0) : null,
      so2: random % 4 == 0 ? (5 + (baseVariation * 15)).clamp(2.0, 25.0) : null,
      wildfireIndex: (baseVariation * 30).clamp(0.0, 40.0),
      universalAqi: null,
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

  void _addPollutionZoneMarkers(Set<Marker> markers) {
    // Add markers for known pollution zones in Houston
    final pollutionZones = [
      {'name': 'I-610 West', 'lat': 29.7304, 'lon': -95.4248, 'severity': 'high'},
      {'name': 'US-59', 'lat': 29.7404, 'lon': -95.3648, 'severity': 'high'},
      {'name': 'Industrial Area', 'lat': 29.6904, 'lon': -95.4148, 'severity': 'high'},
      {'name': 'Medical Center', 'lat': 29.7074, 'lon': -95.4018, 'severity': 'moderate'},
      {'name': 'Rice University', 'lat': 29.7174, 'lon': -95.4018, 'severity': 'low'},
      {'name': 'Hermann Park', 'lat': 29.7274, 'lon': -95.3918, 'severity': 'low'},
    ];
    
    for (final zone in pollutionZones) {
      final severity = zone['severity'] as String;
      double hue;
      String snippet;
      
      switch (severity) {
        case 'high':
          hue = BitmapDescriptor.hueRed;
          snippet = 'High pollution area - Avoid during peak hours';
          break;
        case 'moderate':
          hue = BitmapDescriptor.hueOrange;
          snippet = 'Moderate pollution - Limit outdoor activity';
          break;
        case 'low':
        default:
          hue = BitmapDescriptor.hueGreen;
          snippet = 'Clean air zone - Good for outdoor exercise';
      }
      
      markers.add(
        Marker(
          markerId: MarkerId('pollution_zone_${zone['name']}'),
          position: LatLng(zone['lat'] as double, zone['lon'] as double),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: zone['name'] as String,
            snippet: snippet,
          ),
          alpha: 0.7, // Slightly transparent to distinguish from pinned locations
        ),
      );
    }
  }

  void _createMarkersAndOverlays() {
    Set<Marker> markers = {};
    Set<TileOverlay> tileOverlays = {};

    // Add air quality heatmap overlay using our custom backend
    // TEMPORARILY DISABLED FOR PERFORMANCE
    // tileOverlays.add(
    //   TileOverlay(
    //     tileOverlayId: const TileOverlayId('run_coach_air_quality_heatmap'),
    //     tileProvider: RunCoachHeatmapTileProvider(),
    //     transparency: 0.3,
    //     fadeIn: true,
    //   ),
    // );

    // Add static pollution zone markers (replacing heatmap for performance)
    _addPollutionZoneMarkers(markers);
    
    // Add pinned location markers with Run Coach specific styling
    for (final location in _pinnedLocations) {
      final airQuality = _locationAirQuality[location.id];
      final riskAssessment = _locationRiskAssessments[location.id];
      
      Color markerColor = BitmapDescriptor.hueViolet;
      if (airQuality != null) {
        switch (airQuality.status) {
          case AirQualityStatus.good:
            markerColor = BitmapDescriptor.hueGreen;
            break;
          case AirQualityStatus.caution:
            markerColor = BitmapDescriptor.hueOrange;
            break;
          case AirQualityStatus.avoid:
            markerColor = BitmapDescriptor.hueRed;
            break;
        }
      }

      markers.add(
        Marker(
          markerId: MarkerId('run_coach_pin_${location.id}'),
          position: LatLng(location.latitude, location.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          infoWindow: InfoWindow(
            title: '${location.type.icon} ${location.name}',
            snippet: riskAssessment != null 
              ? 'Risk: ${riskAssessment.riskLevelDisplay}'
              : 'Tap for quick assessment',
            onTap: () => _showQuickRiskAssessment(location),
          ),
          onTap: () => _onPinnedLocationTapped(location),
        ),
      );
    }

    setState(() {
      _markers = markers;
      _tileOverlays = tileOverlays;
    });
  }

  void _onPinnedLocationTapped(PinnedLocation location) {
    setState(() {
      _selectedLocation = location;
      _isBottomSheetVisible = true;
    });
    _showLocationBottomSheet(location);
  }

  void _showLocationBottomSheet(PinnedLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0.2,
        maxChildSize: 0.7,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _buildLocationDetails(location),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      setState(() {
        _isBottomSheetVisible = false;
        _selectedLocation = null;
      });
    });
  }

  Widget _buildLocationDetails(PinnedLocation location) {
    final airQuality = _locationAirQuality[location.id];
    final riskAssessment = _locationRiskAssessments[location.id];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location header
          Row(
            children: [
              Text(
                location.type.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      location.address ?? location.type.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Quick action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _performQuickRiskAssessment(location),
                  icon: const Icon(Icons.health_and_safety),
                  label: const Text('Quick Risk Check'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _getRouteRecommendation(location),
                  icon: const Icon(Icons.route),
                  label: const Text('Get Route'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Risk assessment display
          if (riskAssessment != null) ...[
            _buildRiskAssessmentCard(riskAssessment),
            const SizedBox(height: 16),
          ],

          // Air quality display
          if (airQuality != null) ...[
            _buildAirQualityCard(airQuality),
            const SizedBox(height: 16),
          ],

          // Optimal times section
          if (_optimalTimes.isNotEmpty) ...[
            Text(
              'Best Times for Outdoor Activity (6-12h)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildOptimalTimesList(),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskAssessmentCard(HealthRiskAssessment assessment) {
    final riskColor = _getRiskColor(assessment.currentRiskLevel);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: riskColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Health Risk Assessment',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Risk Level: ${assessment.riskLevelDisplay}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: riskColor,
                ),
              ),
              Text(
                'Threshold: ${assessment.personalThreshold.toInt()} AQI',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAirQualityCard(AirQualityData airQuality) {
    final statusColor = _getStatusColor(airQuality.status);
    final aqi = airQuality.metrics.universalAqi ?? (100 - airQuality.metrics.overallScore).round();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.air, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Air Quality',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AQI: $aqi',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  airQuality.status.displayName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptimalTimesList() {
    return Column(
      children: _optimalTimes.take(3).map((window) {
        final qualityColor = _getQualityColor(window.quality);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: qualityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: qualityColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, color: qualityColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  window.timeRange,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'AQI: ${window.avgAqi.toInt()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _performQuickRiskAssessment(PinnedLocation location) async {
    _showQuickRiskAssessment(location);
  }

  void _showQuickRiskAssessment(PinnedLocation location) {
    final airQuality = _locationAirQuality[location.id];
    final riskAssessment = _locationRiskAssessments[location.id];
    
    if (airQuality == null || riskAssessment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Loading assessment data...'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => QuickRiskAssessmentDialog(
        location: location,
        airQuality: airQuality,
        riskAssessment: riskAssessment,
        onGetRoute: () => _getRouteRecommendation(location),
        onGetOptimalTimes: () => _getOptimalTimes(location),
      ),
    );
  }

  Future<void> _getRouteRecommendation(PinnedLocation location) async {
    try {
      final route = await _runCoachService.getRouteRecommendation(
        location: LatLng(location.latitude, location.longitude),
        distanceKm: 5.0,
        prioritizeParks: true,
        avoidTraffic: true,
      );

      setState(() {
        _selectedRoute = route.route;
        _showRoutes = true;
      });

      _updateRouteOverlay(route.route);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Route recommendation loaded!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading route: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _getOptimalTimes(PinnedLocation location) async {
    try {
      final times = await _runCoachService.getOptimalTimes(
        location: LatLng(location.latitude, location.longitude),
        durationMinutes: 45,
        lookaheadHours: 12,
      );

      setState(() {
        _optimalTimes = times;
        _showTimeWindows = true;
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close the dialog
        _showLocationBottomSheet(location); // Refresh the bottom sheet
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading optimal times: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _updateRouteOverlay(RunRoute route) {
    Set<Polyline> polylines = {};
    
    if (route.geometry.isNotEmpty) {
      final routePoints = route.geometry
          .map((point) => LatLng(point[0], point[1]))
          .toList();
          
      polylines.add(
        Polyline(
          polylineId: const PolylineId('run_coach_recommended_route'),
          points: routePoints,
          color: Theme.of(context).colorScheme.primary,
          width: 5,
          patterns: [],
        ),
      );
    }

    setState(() {
      _polylines = polylines;
    });
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'very_low':
        return Colors.green;
      case 'low':
        return Colors.lightGreen;
      case 'moderate':
        return Colors.yellow.shade700;
      case 'high':
        return Colors.orange;
      case 'very_high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(AirQualityStatus status) {
    switch (status) {
      case AirQualityStatus.good:
        return Colors.green;
      case AirQualityStatus.caution:
        return Colors.orange;
      case AirQualityStatus.avoid:
        return Colors.red;
    }
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.yellow.shade700;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
          _loadAirQualityForLocations().then((_) {
            _createMarkersAndOverlays();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Run Coach Map'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Coach Map'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(
              _showRoutes ? Icons.route : Icons.route_outlined,
              color: _showRoutes ? Theme.of(context).colorScheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                _showRoutes = !_showRoutes;
                if (!_showRoutes) {
                  _polylines.clear();
                } else if (_selectedRoute != null) {
                  _updateRouteOverlay(_selectedRoute!);
                }
              });
            },
            tooltip: 'Toggle Routes',
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showMapLegend,
            tooltip: 'Map Legend',
          ),
          IconButton(
            icon: const Icon(Icons.bubble_chart),
            onPressed: () => _showPollutionVisualizer(),
            tooltip: '3D Pollution View',
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 14.0,  // Higher zoom for better performance
        ),
        markers: _markers,
        polylines: _polylines,
        tileOverlays: _tileOverlays,
        onTap: _onMapTapped,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
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

  void _showPollutionVisualizer() {
    showDialog(
      context: context,
      builder: (context) => PollutionVisualizerDialog(
        latitude: _currentLocation.latitude,
        longitude: _currentLocation.longitude,
      ),
    );
  }

  void _showMapLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Coach Map Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Air Quality Heatmap:'),
            const SizedBox(height: 8),
            _buildLegendItem(Colors.green, 'Good (0-50)', 'Safe for outdoor activities'),
            _buildLegendItem(Colors.yellow.shade700, 'Moderate (51-100)', 'Acceptable for most people'),
            _buildLegendItem(Colors.orange, 'Unhealthy for Sensitive (101-150)', 'Sensitive groups may be affected'),
            _buildLegendItem(Colors.red, 'Unhealthy (151+)', 'Everyone may experience health effects'),
            const Divider(),
            const Text('Pin Colors:'),
            const SizedBox(height: 8),
            _buildLegendItem(Colors.green, 'Good Air Quality', 'Safe for exercise'),
            _buildLegendItem(Colors.orange, 'Caution', 'Monitor conditions'),
            _buildLegendItem(Colors.red, 'Avoid', 'Poor conditions'),
            _buildLegendItem(Colors.purple, 'No Data', 'Tap for assessment'),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RunCoachAirQualityTileProvider extends TileProvider {
  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    if (zoom == null) return const Tile(256, 256, null);

    try {
      final tileUrl = AirQualityApiService.getHeatmapTileUrl(zoom, x, y);
      final response = await http.get(Uri.parse(tileUrl));

      if (response.statusCode == 200) {
        return Tile(256, 256, response.bodyBytes);
      } else {
        return const Tile(256, 256, null);
      }
    } catch (e) {
      debugPrint('Error loading Run Coach air quality tile: $e');
      return const Tile(256, 256, null);
    }
  }
}

class QuickRiskAssessmentDialog extends StatelessWidget {
  final PinnedLocation location;
  final AirQualityData airQuality;
  final HealthRiskAssessment riskAssessment;
  final VoidCallback onGetRoute;
  final VoidCallback onGetOptimalTimes;

  const QuickRiskAssessmentDialog({
    Key? key,
    required this.location,
    required this.airQuality,
    required this.riskAssessment,
    required this.onGetRoute,
    required this.onGetOptimalTimes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(riskAssessment.currentRiskLevel);
    final aqi = airQuality.metrics.universalAqi ?? (100 - airQuality.metrics.overallScore).round();
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    location.type.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '6-12 Hour Outlook',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Risk assessment
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: riskColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Risk Level: ${riskAssessment.riskLevelDisplay}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: riskColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current AQI: $aqi',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Threshold: ${riskAssessment.personalThreshold.toInt()}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Recommendation text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommendation:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getRecommendationText(riskAssessment.currentRiskLevel),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onGetOptimalTimes();
                      },
                      icon: const Icon(Icons.access_time),
                      label: const Text('Best Times'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onGetRoute();
                      },
                      icon: const Icon(Icons.route),
                      label: const Text('Get Route'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'very_low':
        return Colors.green;
      case 'low':
        return Colors.lightGreen;
      case 'moderate':
        return Colors.yellow.shade700;
      case 'high':
        return Colors.orange;
      case 'very_high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getRecommendationText(String riskLevel) {
    switch (riskLevel) {
      case 'very_low':
        return 'Excellent conditions for outdoor exercise. All activity levels are safe.';
      case 'low':
        return 'Good conditions for outdoor activities. Proceed with your planned exercise.';
      case 'moderate':
        return 'Acceptable for most people. Sensitive individuals may want to reduce intensity.';
      case 'high':
        return 'Consider indoor alternatives. If exercising outdoors, reduce intensity and duration.';
      case 'very_high':
        return 'Avoid outdoor exercise. Choose indoor activities or wait for better conditions.';
      default:
        return 'Unable to determine risk level. Please check back later.';
    }
  }
}