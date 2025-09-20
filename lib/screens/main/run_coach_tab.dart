import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  
  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }
  
  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);
    
    try {
      // Get current location (mock for now)
      final location = const LatLng(37.7749, -122.4194); // San Francisco
      
      // Get recommendations
      final recommendations = await _runCoachService.getRouteRecommendation(
        location: location,
        distanceKm: _preferredDistance,
        prioritizeParks: _prioritizeParks,
        avoidTraffic: _avoidTraffic,
      );
      
      // Get optimal times
      final times = await _runCoachService.getOptimalTimes(
        location: location,
        durationMinutes: recommendations.route.durationMin.toInt(),
      );
      
      // Get risk assessment
      final risk = await _runCoachService.getHealthRiskAssessment(
        currentAqi: recommendations.route.avgAqi,
      );
      
      // Get pollution heatmap
      final heatmap = await _runCoachService.getPollutionHeatmap(
        location: location,
        radiusKm: 10,
      );
      
      setState(() {
        _recommendedRoute = recommendations.route;
        _optimalTimes = times;
        _riskAssessment = risk;
        _pollutionHeatmap = heatmap;
        _updateMap();
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading recommendations: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _updateMap() {
    if (_recommendedRoute == null) return;
    
    // Clear existing overlays
    _polylines.clear();
    _markers.clear();
    
    // Add route polyline
    final routePoints = _recommendedRoute!.geometry
        .map((point) => LatLng(point[0], point[1]))
        .toList();
        
    _polylines.add(
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
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: routePoints.first,
          infoWindow: const InfoWindow(title: 'Start'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
      
      _markers.add(
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
        _markers.add(
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
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
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
            ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                : const LatLng(37.7749, -122.4194),
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
      child: RouteDetailsCard(
        route: _recommendedRoute!,
        onNavigatePressed: () {
          // TODO: Launch navigation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navigation feature coming soon')),
          );
        },
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
              _loadRecommendations();
            },
          ),
          
          // Preferences switches
          SwitchListTile(
            title: const Text('Prioritize Parks & Green Spaces'),
            subtitle: const Text('Routes through parks when possible'),
            value: _prioritizeParks,
            onChanged: (value) {
              setState(() => _prioritizeParks = value);
              _loadRecommendations();
            },
            secondary: const Icon(Icons.park),
          ),
          
          SwitchListTile(
            title: const Text('Avoid High Traffic Areas'),
            subtitle: const Text('Safer routes away from busy roads'),
            value: _avoidTraffic,
            onChanged: (value) {
              setState(() => _avoidTraffic = value);
              _loadRecommendations();
            },
            secondary: const Icon(Icons.traffic),
          ),
        ],
      ),
    );
  }
}