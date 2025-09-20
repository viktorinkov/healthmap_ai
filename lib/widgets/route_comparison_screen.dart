import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/running_routes_service.dart';

class RouteComparisonScreen extends StatefulWidget {
  final int originalRouteId;
  final int optimizedRouteId;
  final String routeName;

  const RouteComparisonScreen({
    Key? key,
    required this.originalRouteId,
    required this.optimizedRouteId,
    required this.routeName,
  }) : super(key: key);

  @override
  State<RouteComparisonScreen> createState() => _RouteComparisonScreenState();
}

class _RouteComparisonScreenState extends State<RouteComparisonScreen> {
  GoogleMapController? _mapController;
  Map<String, dynamic>? _originalRouteData;
  Map<String, dynamic>? _optimizedRouteData;
  bool _isLoading = true;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng? _centerPoint;
  bool _showOriginal = true;
  bool _showOptimized = true;

  @override
  void initState() {
    super.initState();
    _loadRouteData();
  }

  Future<void> _loadRouteData() async {
    try {
      final originalRoute = RunningRoutesService.getRoute(widget.originalRouteId);
      final optimizedRoute = RunningRoutesService.getRoute(widget.optimizedRouteId);

      final results = await Future.wait([originalRoute, optimizedRoute]);

      setState(() {
        _originalRouteData = results[0];
        _optimizedRouteData = results[1];
        _isLoading = false;
      });
      _createRouteVisualization();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load routes: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _createRouteVisualization() {
    if (_originalRouteData == null || _optimizedRouteData == null) return;

    final Set<Polyline> polylines = {};
    final Set<Marker> markers = {};
    final List<LatLng> allPoints = [];

    // Create original route polyline
    if (_showOriginal && _originalRouteData!['waypoints'] != null) {
      final originalWaypoints = _originalRouteData!['waypoints'] as List;
      if (originalWaypoints.isNotEmpty) {
        final List<LatLng> originalPoints = originalWaypoints.map((waypoint) {
          return LatLng(
            waypoint['latitude'] as double,
            waypoint['longitude'] as double,
          );
        }).toList();

        allPoints.addAll(originalPoints);

        polylines.add(Polyline(
          polylineId: const PolylineId('original_route'),
          points: originalPoints,
          color: Colors.red.withValues(alpha: 0.8),
          width: 4,
          patterns: [PatternItem.dash(10), PatternItem.gap(5)],
        ));

        // Original route start marker
        markers.add(Marker(
          markerId: const MarkerId('original_start'),
          position: originalPoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(
            title: 'Original Route Start',
            snippet: 'Starting point of original route',
          ),
        ));
      }
    }

    // Create optimized route polyline
    if (_showOptimized && _optimizedRouteData!['waypoints'] != null) {
      final optimizedWaypoints = _optimizedRouteData!['waypoints'] as List;
      if (optimizedWaypoints.isNotEmpty) {
        final List<LatLng> optimizedPoints = optimizedWaypoints.map((waypoint) {
          return LatLng(
            waypoint['latitude'] as double,
            waypoint['longitude'] as double,
          );
        }).toList();

        allPoints.addAll(optimizedPoints);

        polylines.add(Polyline(
          polylineId: const PolylineId('optimized_route'),
          points: optimizedPoints,
          color: Colors.green.withValues(alpha: 0.8),
          width: 4,
        ));

        // Optimized route start marker
        markers.add(Marker(
          markerId: const MarkerId('optimized_start'),
          position: optimizedPoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Optimized Route Start',
            snippet: 'Starting point of optimized route',
          ),
        ));
      }
    }

    // Calculate center point
    if (allPoints.isNotEmpty) {
      final double centerLat = allPoints.map((p) => p.latitude).reduce((a, b) => a + b) / allPoints.length;
      final double centerLng = allPoints.map((p) => p.longitude).reduce((a, b) => a + b) / allPoints.length;
      _centerPoint = LatLng(centerLat, centerLng);
    }

    setState(() {
      _polylines = polylines;
      _markers = markers;
    });

    // Fit camera to show both routes
    if (allPoints.isNotEmpty) {
      _fitCameraToRoutes(allPoints);
    }
  }

  void _fitCameraToRoutes(List<LatLng> points) {
    if (_mapController == null || points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Comparison'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                if (value == 'toggle_original') {
                  _showOriginal = !_showOriginal;
                } else if (value == 'toggle_optimized') {
                  _showOptimized = !_showOptimized;
                }
              });
              _createRouteVisualization();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_original',
                child: Row(
                  children: [
                    Icon(
                      _showOriginal ? Icons.visibility : Icons.visibility_off,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    const Text('Original Route'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_optimized',
                child: Row(
                  children: [
                    Icon(
                      _showOptimized ? Icons.visibility : Icons.visibility_off,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    const Text('Optimized Route'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Comparison stats card
                _buildComparisonCard(),
                // Legend
                _buildLegend(),
                // Map
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _centerPoint ?? const LatLng(29.7604, -95.3698),
                      zoom: 14,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      if (_polylines.isNotEmpty) {
                        // Delay to ensure map is ready
                        Future.delayed(const Duration(milliseconds: 500), () {
                          final allPoints = <LatLng>[];
                          for (final polyline in _polylines) {
                            allPoints.addAll(polyline.points);
                          }
                          if (allPoints.isNotEmpty) {
                            _fitCameraToRoutes(allPoints);
                          }
                        });
                      }
                    },
                    polylines: _polylines,
                    markers: _markers,
                    mapType: MapType.normal,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildComparisonCard() {
    if (_originalRouteData == null || _optimizedRouteData == null) {
      return const SizedBox.shrink();
    }

    final originalDistance = _originalRouteData!['distance_km']?.toString() ?? '0';
    final optimizedDistance = _optimizedRouteData!['distance_km']?.toString() ?? '0';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.routeName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Route',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$originalDistance km',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optimized Route',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$optimizedDistance km',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_showOriginal)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Original', style: TextStyle(fontSize: 12)),
              ],
            ),
          if (_showOptimized)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Optimized', style: TextStyle(fontSize: 12)),
              ],
            ),
        ],
      ),
    );
  }
}