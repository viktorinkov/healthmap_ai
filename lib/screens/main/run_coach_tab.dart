import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import '../../services/run_coach_service.dart';
import '../../models/run_coach_models.dart';
import '../../widgets/run_coach_widgets.dart';

class RunCoachTab extends StatefulWidget {
  const RunCoachTab({Key? key}) : super(key: key);

  @override
  _RunCoachTabState createState() => _RunCoachTabState();
}

class _RunCoachTabState extends State<RunCoachTab> {
  final RunCoachService _runCoachService = RunCoachService();

  bool _isLoading = false;
  RunRoute? _recommendedRoute;
  List<TimeWindow> _optimalTimes = [];
  HealthRiskAssessment? _riskAssessment;
  PollutionHeatmap? _pollutionHeatmap;

  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};

  // User preferences
  double _preferredDistance = 5.0; // km
  bool _prioritizeParks = true;
  bool _avoidTraffic = true;

  // Debouncing timer to prevent excessive API calls
  Timer? _debounceTimer;
  
  @override
  void initState() {
    super.initState();
    print('🚀 RunCoachTab: initState() called');
    // Don't auto-load - let user trigger manually
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debouncedReload() {
    print('⏱️ RunCoachTab: _debouncedReload() called');
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      print('🔄 RunCoachTab: Debounce timer fired, calling _loadRecommendations()');
      _loadRecommendations();
    });
  }
  
  Future<void> _loadRecommendations() async {
    print('📥 RunCoachTab: _loadRecommendations() started, _isLoading=$_isLoading');

    if (_isLoading) {
      print('⚠️ RunCoachTab: Already loading, skipping...');
      return; // Prevent multiple concurrent calls
    }

    print('🔄 RunCoachTab: Setting loading state to true');
    setState(() => _isLoading = true);

    try {
      // Get current location (mock for now)
      final location = const LatLng(29.7174, -95.4018); // Rice University, Houston, Texas
      print('📍 RunCoachTab: Using location: $location');

      print('🌐 RunCoachTab: Starting parallel API calls (batch 1)...');
      final stopwatch1 = Stopwatch()..start();

      // Make API calls in parallel instead of sequential
      final results = await Future.wait([
        _runCoachService.getRouteRecommendation(
          location: location,
          distanceKm: _preferredDistance,
          prioritizeParks: _prioritizeParks,
          avoidTraffic: _avoidTraffic,
        ).then((result) {
          print('✅ RunCoachTab: getRouteRecommendation completed');
          return result;
        }),
        _runCoachService.getPollutionHeatmap(
          location: location,
          radiusKm: 10,
        ).then((result) {
          print('✅ RunCoachTab: getPollutionHeatmap completed');
          return result;
        }),
      ]);

      stopwatch1.stop();
      print('⏱️ RunCoachTab: Batch 1 completed in ${stopwatch1.elapsedMilliseconds}ms');

      final recommendations = results[0] as RouteRecommendation;
      final heatmap = results[1] as PollutionHeatmap;
      print('📊 RunCoachTab: Route duration: ${recommendations.route.durationMin}min, AQI: ${recommendations.route.avgAqi}');

      print('🌐 RunCoachTab: Starting parallel API calls (batch 2)...');
      final stopwatch2 = Stopwatch()..start();

      // Get dependent API calls after the main route is available
      final dependentResults = await Future.wait([
        _runCoachService.getOptimalTimes(
          location: location,
          durationMinutes: recommendations.route.durationMin.toInt(),
        ).then((result) {
          print('✅ RunCoachTab: getOptimalTimes completed');
          return result;
        }),
        _runCoachService.getHealthRiskAssessment(
          currentAqi: recommendations.route.avgAqi,
        ).then((result) {
          print('✅ RunCoachTab: getHealthRiskAssessment completed');
          return result;
        }),
      ]);

      stopwatch2.stop();
      print('⏱️ RunCoachTab: Batch 2 completed in ${stopwatch2.elapsedMilliseconds}ms');

      final times = dependentResults[0] as List<TimeWindow>;
      final risk = dependentResults[1] as HealthRiskAssessment;
      print('📅 RunCoachTab: Got ${times.length} optimal times, risk level: ${risk.currentRiskLevel}');

      // Update state incrementally to avoid massive rebuilds
      if (mounted) {
        print('🎨 RunCoachTab: Updating UI state (first batch)...');
        setState(() {
          _recommendedRoute = recommendations.route;
          _pollutionHeatmap = heatmap;
        });

        print('🗺️ RunCoachTab: Updating map...');
        // Update map separately
        _updateMap();

        print('🎨 RunCoachTab: Updating UI state (second batch)...');
        // Update other data
        setState(() {
          _optimalTimes = times;
          _riskAssessment = risk;
        });

        print('✅ RunCoachTab: All data loaded successfully!');
      } else {
        print('⚠️ RunCoachTab: Widget not mounted, skipping UI updates');
      }

    } catch (e) {
      print('❌ RunCoachTab: Error loading recommendations: $e');
      print('📱 RunCoachTab: Stack trace: ${StackTrace.current}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recommendations: $e')),
        );
      }
    } finally {
      if (mounted) {
        print('🏁 RunCoachTab: Setting loading state to false');
        setState(() => _isLoading = false);
      } else {
        print('⚠️ RunCoachTab: Widget not mounted, skipping loading state update');
      }
    }
  }
  
  void _updateMap() {
    print('🗺️ RunCoachTab: _updateMap() called');

    if (_recommendedRoute == null) {
      print('⚠️ RunCoachTab: _recommendedRoute is null, skipping map update');
      return;
    }

    print('🎯 RunCoachTab: Route has ${_recommendedRoute!.geometry.length} points and ${_recommendedRoute!.segments.length} segments');

    // Create new sets to avoid triggering listeners during build
    final newPolylines = <Polyline>{};
    final newMarkers = <Marker>{};
    
    // Add route polyline
    final routePoints = _recommendedRoute!.geometry
        .map((point) => LatLng(point[0], point[1]))
        .toList();

    newPolylines.add(
      Polyline(
        polylineId: const PolylineId('recommended_route'),
        points: routePoints,
        color: Theme.of(context).colorScheme.primary,
        width: 5,
        patterns: [], // Solid line for main route
      ),
    );

    // Add start/end markers
    if (routePoints.isNotEmpty) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: routePoints.first,
          infoWindow: const InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      newMarkers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: routePoints.last,
          infoWindow: const InfoWindow(title: 'End'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Add segment markers for high pollution areas
    for (var i = 0; i < _recommendedRoute!.segments.length; i++) {
      final segment = _recommendedRoute!.segments[i];
      if (segment.aqi > 100) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('warning_$i'),
            position: LatLng(segment.startPoint[0], segment.startPoint[1]),
            infoWindow: InfoWindow(
              title: 'High Pollution',
              snippet: 'AQI: ${segment.aqi.toInt()}, ${segment.recommendedPace}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          ),
        );
      }
    }

    // Update state once with all changes
    print('🔄 RunCoachTab: Updating map state with ${newPolylines.length} polylines and ${newMarkers.length} markers');
    setState(() {
      _polylines = newPolylines;
      _markers = newMarkers;
    });
    print('✅ RunCoachTab: Map update completed');
  }
  
  @override
  Widget build(BuildContext context) {
    print('🎨 RunCoachTab: build() called, _isLoading=$_isLoading');

    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading AI Run Coach...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : _recommendedRoute == null
              ? _buildInitialState()
              : _buildRouteResults(),
    );
  }

  Widget _buildInitialState() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        SliverToBoxAdapter(
          child: _buildPreferences(),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () {
                _loadRecommendations();
              },
              icon: const Icon(Icons.route),
              label: const Text('Generate AI-Optimized Route'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 60),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRouteResults() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(),
        ),
        SliverToBoxAdapter(
          child: _buildMap(),
        ),
        SliverToBoxAdapter(
          child: _buildRouteDetails(),
        ),
        SliverToBoxAdapter(
          child: _buildOptimalTimes(),
        ),
        SliverToBoxAdapter(
          child: _buildHealthRisk(),
        ),
        SliverToBoxAdapter(
          child: _buildPreferences(),
        ),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Run Coach',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Optimized routes for cleaner air and better health',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMap() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _recommendedRoute != null && _recommendedRoute!.geometry.isNotEmpty
                ? LatLng(_recommendedRoute!.geometry.first[0], _recommendedRoute!.geometry.first[1])
                : const LatLng(29.7174, -95.4018), // Rice University, Houston, Texas
            zoom: 14,
          ),
          polylines: _polylines,
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
      ),
    );
  }
  
  Widget _buildRouteDetails() {
    if (_recommendedRoute == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          RouteDetailsCard(
            route: _recommendedRoute!,
            onNavigatePressed: () {
              // TODO: Launch navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigation feature coming soon')),
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : () {
              _debouncedReload();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Generate New Route'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOptimalTimes() {
    if (_optimalTimes.isEmpty) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: OptimalTimesCard(
        timeWindows: _optimalTimes,
        onTimeSelected: (window) {
          // TODO: Schedule run
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected time: ${window.start.hour}:${window.start.minute.toString().padLeft(2, '0')}'),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildHealthRisk() {
    if (_riskAssessment == null) return const SizedBox();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: HealthRiskCard(
        assessment: _riskAssessment!,
      ),
    );
  }
  
  Widget _buildPreferences() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Preferences',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Distance slider
          Row(
            children: [
              Icon(Icons.straighten, 
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Distance: ${_preferredDistance.toStringAsFixed(1)} km'),
              const Spacer(),
            ],
          ),
          Slider(
            value: _preferredDistance,
            min: 1,
            max: 15,
            divisions: 14,
            label: '${_preferredDistance.toStringAsFixed(1)} km',
            onChanged: (value) {
              setState(() => _preferredDistance = value);
            },
            onChangeEnd: (value) {
              _debouncedReload();
            },
          ),
          
          // Preferences switches
          SwitchListTile(
            title: const Text('Prioritize Parks & Green Spaces'),
            subtitle: const Text('Routes through parks when possible'),
            value: _prioritizeParks,
            onChanged: (value) {
              setState(() => _prioritizeParks = value);
              _debouncedReload();
            },
            secondary: const Icon(Icons.park),
          ),
          
          SwitchListTile(
            title: const Text('Avoid High Traffic Areas'),
            subtitle: const Text('Safer routes away from busy roads'),
            value: _avoidTraffic,
            onChanged: (value) {
              setState(() => _avoidTraffic = value);
              _debouncedReload();
            },
            secondary: const Icon(Icons.traffic),
          ),
        ],
      ),
    );
  }
}