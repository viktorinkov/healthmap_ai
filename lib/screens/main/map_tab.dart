import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../models/air_quality.dart';
import '../../models/neighborhood.dart';
import '../../models/pinned_location.dart';
import '../../services/fake_data_service.dart';
import '../../services/database_service.dart';
import '../../widgets/add_location_dialog.dart';
import '../../widgets/pinned_location_sheet.dart';
import '../../widgets/neighborhood_report_sheet.dart';

class MapTab extends StatefulWidget {
  const MapTab({Key? key}) : super(key: key);

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  GoogleMapController? _mapController;
  final Location _location = Location();
  LatLng _currentLocation = const LatLng(29.7174, -95.4018); // Rice University, Houston
  List<Neighborhood> _neighborhoods = [];
  List<PinnedLocation> _pinnedLocations = [];
  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
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

      // Load neighborhoods data
      _neighborhoods = FakeDataService.generateHoustonNeighborhoods();
      await DatabaseService().saveNeighborhoods(_neighborhoods);

      // Load pinned locations
      _pinnedLocations = await DatabaseService().getPinnedLocations();

      // Create markers and polygons
      _createMarkersAndPolygons();

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

  void _createMarkersAndPolygons() {
    Set<Marker> markers = {};
    Set<Polygon> polygons = {};

    // Create polygons for neighborhoods (air quality visualization)
    for (final neighborhood in _neighborhoods) {
      final status = neighborhood.status;
      final color = _getStatusColor(status);

      // Create polygon points around neighborhood center
      final polygonPoints = _generateNeighborhoodPolygon(
        LatLng(neighborhood.latitude, neighborhood.longitude),
        neighborhood.name,
      );

      polygons.add(
        Polygon(
          polygonId: PolygonId('neighborhood_${neighborhood.id}'),
          points: polygonPoints,
          fillColor: color.withValues(alpha: 0.3),
          strokeColor: color.withValues(alpha: 0.8),
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () => _showNeighborhoodReport(neighborhood),
        ),
      );
    }

    // Add pinned location markers (modern Material 3 style)
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
      _polygons = polygons;
    });
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


  List<LatLng> _generateNeighborhoodPolygon(LatLng center, String neighborhoodName) {
    // Generate approximate neighborhood boundaries
    // In a real app, you'd use actual neighborhood boundary data
    final double radius = _getNeighborhoodRadius(neighborhoodName);
    final List<LatLng> points = [];

    // Create a roughly circular polygon with some variation
    const int numPoints = 8;
    for (int i = 0; i < numPoints; i++) {
      final double angle = (i * 2 * 3.14159) / numPoints;
      final double variation = 0.7 + (0.6 * ((i % 3) / 3.0)); // Add some irregularity
      final double adjustedRadius = radius * variation;

      final double lat = center.latitude + (adjustedRadius * 0.009 * (angle > 3.14159 ? -1 : 1) * (1 + 0.3 * (i % 2)));
      final double lng = center.longitude + (adjustedRadius * 0.012 * (angle > 1.57 && angle < 4.71 ? -1 : 1) * (1 + 0.2 * ((i + 1) % 2)));

      points.add(LatLng(lat, lng));
    }

    return points;
  }

  double _getNeighborhoodRadius(String name) {
    // Different neighborhoods have different sizes
    switch (name.toLowerCase()) {
      case 'rice village':
      case 'museum district':
        return 0.8; // Smaller dense areas
      case 'river oaks':
      case 'memorial':
        return 1.5; // Larger residential areas
      case 'downtown':
      case 'galleria':
        return 2.0; // Large commercial areas
      default:
        return 1.0; // Default size
    }
  }

  void _showNeighborhoodReport(Neighborhood neighborhood) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NeighborhoodReportSheet(neighborhood: neighborhood),
    );
  }

  void _showPinnedLocationDetails(PinnedLocation location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PinnedLocationSheet(
        location: location,
        onDeleted: () {
          setState(() {
            _pinnedLocations.removeWhere((l) => l.id == location.id);
          });
          _createMarkersAndPolygons();
        },
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
          _createMarkersAndPolygons();
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
        polygons: _polygons,
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
        title: const Text('Map Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(Colors.green, 'Good', 'Safe for all activities'),
            _buildLegendItem(Colors.orange, 'Caution', 'Sensitive individuals should limit outdoor activities'),
            _buildLegendItem(Colors.red, 'Avoid', 'Everyone should avoid prolonged outdoor exposure'),
            const Divider(),
            _buildLegendItem(Colors.purple, 'Pinned Location', 'Your saved locations (home, work, etc.)'),
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
}

class NeighborhoodDetailsSheet extends StatelessWidget {
  final Neighborhood neighborhood;

  const NeighborhoodDetailsSheet({Key? key, required this.neighborhood}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '#${neighborhood.ranking}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  neighborhood.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Status', neighborhood.status.displayName),
          _buildDetailRow('Health Score', '${neighborhood.healthScore.toInt()}/100'),
          _buildDetailRow('ZIP Codes', neighborhood.zipCodes.join(', ')),
          const SizedBox(height: 12),
          Text(
            'Assessment:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(neighborhood.statusReason),
          if (neighborhood.currentAirQuality != null) ...[
            const SizedBox(height: 16),
            Text(
              'Current Air Quality:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _buildAirQualityMetrics(neighborhood.currentAirQuality!.metrics),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildAirQualityMetrics(AirQualityMetrics metrics) {
    return Column(
      children: [
        _buildMetricRow('PM2.5', metrics.pm25, 'μg/m³'),
        _buildMetricRow('PM10', metrics.pm10, 'μg/m³'),
        _buildMetricRow('Ozone', metrics.o3, 'ppb'),
        _buildMetricRow('NO2', metrics.no2, 'ppb'),
        _buildMetricRow('Wildfire', metrics.wildfireIndex, '/100'),
        _buildMetricRow('Radon', metrics.radon, 'pCi/L'),
      ],
    );
  }

  Widget _buildMetricRow(String name, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name),
          Text('${value.toStringAsFixed(1)} $unit'),
        ],
      ),
    );
  }
}


