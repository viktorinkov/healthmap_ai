import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/running_routes_service.dart';
import '../services/api_service.dart';

class RouteDetailScreen extends StatefulWidget {
  final int routeId;
  final String routeName;

  const RouteDetailScreen({
    Key? key,
    required this.routeId,
    required this.routeName,
  }) : super(key: key);

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  GoogleMapController? _mapController;
  Map<String, dynamic>? _routeData;
  Map<String, dynamic>? _optimizedRouteData;
  bool _isLoading = true;
  bool _isOptimizing = false;
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
      final routeData = await RunningRoutesService.getRoute(widget.routeId);
      setState(() {
        _routeData = routeData;
        _isLoading = false;
      });

      // Check for optimized versions if this is not already optimized
      if (routeData['optimizations'] != null && (routeData['optimizations'] as List).isNotEmpty) {
        final latestOptimization = (routeData['optimizations'] as List).first;
        if (latestOptimization['optimized_route_id'] != null) {
          try {
            final optimizedData = await RunningRoutesService.getRoute(latestOptimization['optimized_route_id']);
            setState(() {
              _optimizedRouteData = optimizedData;
            });
          } catch (e) {
            print('Failed to load optimized route: $e');
          }
        }
      }

      _createRouteVisualization();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load route: $e'),
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
    if (_routeData == null || _routeData!['waypoints'] == null) return;

    final Set<Polyline> polylines = {};
    final Set<Marker> markers = {};
    final List<LatLng> allPoints = [];

    // Create original route polyline
    if (_showOriginal) {
      final waypoints = _routeData!['waypoints'] as List;
      if (waypoints.isNotEmpty) {
        final List<LatLng> originalPoints = waypoints.map((waypoint) {
          return LatLng(
            waypoint['latitude'] as double,
            waypoint['longitude'] as double,
          );
        }).toList();

        allPoints.addAll(originalPoints);

        // Determine styling based on whether an optimized version exists
        final bool hasOptimized = _optimizedRouteData != null;

        polylines.add(Polyline(
          polylineId: PolylineId('original_route_${widget.routeId}'),
          points: originalPoints,
          color: hasOptimized ? Colors.red.withValues(alpha: 0.8) : Theme.of(context).colorScheme.primary,
          width: 4,
          patterns: hasOptimized ? [PatternItem.dash(10), PatternItem.gap(5)] : [],
        ));

        // Original route markers
        markers.add(Marker(
          markerId: const MarkerId('original_start'),
          position: originalPoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(hasOptimized ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: hasOptimized ? 'Original Start' : 'Start',
            snippet: hasOptimized ? 'Starting point of original route' : 'Route starting point',
          ),
        ));

        if (!hasOptimized) {
          markers.add(Marker(
            markerId: const MarkerId('original_end'),
            position: originalPoints.last,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(
              title: 'End',
              snippet: 'Route ending point',
            ),
          ));
        }
      }
    }

    // Create optimized route polyline if available
    if (_showOptimized && _optimizedRouteData != null && _optimizedRouteData!['waypoints'] != null) {
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

        // Optimized route markers
        markers.add(Marker(
          markerId: const MarkerId('optimized_start'),
          position: optimizedPoints.first,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(
            title: 'Optimized Start',
            snippet: 'Starting point of optimized route',
          ),
        ));
      }
    }

    // Calculate center point from all points
    if (allPoints.isNotEmpty) {
      final double centerLat = allPoints.map((p) => p.latitude).reduce((a, b) => a + b) / allPoints.length;
      final double centerLng = allPoints.map((p) => p.longitude).reduce((a, b) => a + b) / allPoints.length;
      _centerPoint = LatLng(centerLat, centerLng);
    }

    setState(() {
      _polylines = polylines;
      _markers = markers;
    });

    // Fit camera to show all routes
    if (allPoints.isNotEmpty) {
      _fitCameraToRoute(allPoints);
    }
  }

  void _fitCameraToRoute(List<LatLng> points) {
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
        title: Text(widget.routeName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (_optimizedRouteData != null)
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
          if (_routeData != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showRouteInfo,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routeData == null
              ? const Center(
                  child: Text('Failed to load route data'),
                )
              : Column(
                  children: [
                    // Route stats card
                    _buildRouteStatsCard(),
                    // Legend (if both routes exist)
                    if (_optimizedRouteData != null) _buildLegend(),
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
                              _fitCameraToRoute(_polylines.first.points);
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
      floatingActionButton: _shouldShowOptimizeButton()
          ? FloatingActionButton.extended(
              onPressed: _isOptimizing ? null : _optimizeRoute,
              icon: _isOptimizing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : const Icon(Icons.auto_fix_high),
              label: Text(_isOptimizing ? 'Optimizing...' : 'Optimize Route'),
              backgroundColor: _isOptimizing
                  ? Theme.of(context).colorScheme.surfaceContainer
                  : Theme.of(context).colorScheme.primary,
            )
          : null,
    );
  }

  bool _shouldShowOptimizeButton() {
    // Show optimize button if:
    // 1. User is authenticated
    // 2. Route is not already optimized (doesn't contain "Optimized" in name)
    // 3. No optimized version exists yet
    return ApiService.isAuthenticated &&
           !(_routeData?['name']?.toString().contains('Optimized') ?? false) &&
           _optimizedRouteData == null;
  }

  Future<void> _optimizeRoute() async {
    if (!ApiService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to optimize routes'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isOptimizing = true;
    });

    try {
      final result = await RunningRoutesService.optimizeRoute(
        routeId: widget.routeId,
        optimizationType: 'pollution',
      );

      // Load the newly optimized route
      if (result['optimized_route_id'] != null) {
        final optimizedData = await RunningRoutesService.getRoute(result['optimized_route_id']);
        setState(() {
          _optimizedRouteData = optimizedData;
          _isOptimizing = false;
        });
        _createRouteVisualization();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Route optimized! Air pollution exposure reduced by ${result['optimization_result']['actual_improvement']}%'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isOptimizing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to optimize route: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Widget _buildRouteStatsCard() {
    if (_routeData == null) return const SizedBox.shrink();

    final distance = _routeData!['distance_km']?.toString() ?? '0';
    final duration = _routeData!['duration_minutes']?.toString() ?? 'N/A';
    final difficulty = _routeData!['difficulty']?.toString() ?? 'moderate';
    final routeType = _routeData!['route_type']?.toString().replaceAll('_', ' ') ?? 'loop';
    final isOptimized = _routeData!['name']?.toString().contains('Optimized') ?? false;

    final difficultyColor = difficulty == 'easy' ? Colors.green
        : difficulty == 'moderate' ? Colors.orange
        : Colors.red;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: isOptimized ? Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isOptimized) ...[
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI Optimized',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Expanded(
                child: Text(
                  _routeData!['name'] ?? 'Unnamed Route',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: difficultyColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: difficultyColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  difficulty,
                  style: TextStyle(
                    color: difficultyColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (_routeData!['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              _routeData!['description'],
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.straighten,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '$distance km',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.timer,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '$duration min',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                routeType.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
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

  void _showRouteInfo() {
    if (_routeData == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Route Information',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_routeData!['waypoints'] != null) ...[
              Text(
                'Route Points: ${(_routeData!['waypoints'] as List).length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            if (_routeData!['created_at'] != null) ...[
              Text(
                'Created: ${_routeData!['created_at']}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            Text(
              'Legend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Start Point'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('End Point'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Route Path'),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}