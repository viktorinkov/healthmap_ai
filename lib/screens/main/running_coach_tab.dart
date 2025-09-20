import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/running_routes_service.dart';
import '../../services/api_service.dart';
import '../../widgets/route_detail_screen.dart';
import '../../widgets/route_comparison_screen.dart';

class RunningCoachTab extends StatefulWidget {
  const RunningCoachTab({Key? key}) : super(key: key);

  @override
  State<RunningCoachTab> createState() => _RunningCoachTabState();
}

class _RunningCoachTabState extends State<RunningCoachTab> {
  List<dynamic> _userRoutes = [];
  bool _isLoadingRoutes = false;
  bool _isGeneratingRoutes = false;
  bool _isInsertingSampleRoutes = false;
  Position? _currentPosition;
  bool _locationServicesEnabled = false;
  LocationPermission _locationPermission = LocationPermission.denied;

  @override
  void initState() {
    super.initState();
    _loadUserRoutes();
    _getCurrentLocation();
  }

  bool get _isLocationAvailable {
    return _locationServicesEnabled &&
           _locationPermission != LocationPermission.denied &&
           _locationPermission != LocationPermission.deniedForever &&
           _currentPosition != null;
  }

  String get _locationStatusMessage {
    if (!_locationServicesEnabled) {
      return 'Please enable location services in settings';
    }
    if (_locationPermission == LocationPermission.denied) {
      return 'Location permission denied. Please grant permission';
    }
    if (_locationPermission == LocationPermission.deniedForever) {
      return 'Location permission permanently denied. Please enable in app settings';
    }
    if (_currentPosition == null) {
      return 'Getting location...';
    }
    return 'Location ready';
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      setState(() {
        _locationServicesEnabled = serviceEnabled;
      });

      if (!serviceEnabled) {
        return;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      setState(() {
        _locationPermission = permission;
      });

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        setState(() {
          _locationPermission = permission;
        });
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      // Handle location error silently
    }
  }

  Future<void> _loadUserRoutes() async {
    if (!ApiService.isAuthenticated) return;

    setState(() {
      _isLoadingRoutes = true;
    });

    try {
      final routes = await RunningRoutesService.getUserRoutes(includeWaypoints: false);
      setState(() {
        _userRoutes = routes;
        _isLoadingRoutes = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRoutes = false;
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

  Future<void> _insertSampleRoutes() async {
    if (!ApiService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to add sample routes'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isInsertingSampleRoutes = true;
    });

    try {
      // Create sample routes for Houston area

      // Sample route 1: Hermann Park Loop
      await RunningRoutesService.createRoute(
        name: 'Hermann Park Loop',
        description: 'Scenic route through Hermann Park with tree cover and moderate pollution exposure',
        distanceKm: 3.2,
        durationMinutes: 24,
        difficulty: 'easy',
        routeType: 'loop',
        waypoints: [
          {'latitude': 29.7109, 'longitude': -95.3890, 'order': 0},
          {'latitude': 29.7120, 'longitude': -95.3885, 'order': 1},
          {'latitude': 29.7130, 'longitude': -95.3870, 'order': 2},
          {'latitude': 29.7135, 'longitude': -95.3850, 'order': 3},
          {'latitude': 29.7125, 'longitude': -95.3840, 'order': 4},
          {'latitude': 29.7109, 'longitude': -95.3890, 'order': 5},
        ],
      );

      // Sample route 2: Buffalo Bayou Trail
      await RunningRoutesService.createRoute(
        name: 'Buffalo Bayou Trail',
        description: 'Waterfront trail with good air quality and scenic views',
        distanceKm: 5.0,
        durationMinutes: 35,
        difficulty: 'moderate',
        routeType: 'out_and_back',
        waypoints: [
          {'latitude': 29.7633, 'longitude': -95.3632, 'order': 0},
          {'latitude': 29.7640, 'longitude': -95.3580, 'order': 1},
          {'latitude': 29.7650, 'longitude': -95.3520, 'order': 2},
          {'latitude': 29.7655, 'longitude': -95.3460, 'order': 3},
          {'latitude': 29.7650, 'longitude': -95.3520, 'order': 4},
          {'latitude': 29.7640, 'longitude': -95.3580, 'order': 5},
          {'latitude': 29.7633, 'longitude': -95.3632, 'order': 6},
        ],
      );

      // Sample route 3: Memorial Park Inner Loop
      await RunningRoutesService.createRoute(
        name: 'Memorial Park Inner Loop',
        description: 'Popular running trail through Memorial Park with good tree coverage',
        distanceKm: 4.8,
        durationMinutes: 32,
        difficulty: 'moderate',
        routeType: 'loop',
        waypoints: [
          {'latitude': 29.7654, 'longitude': -95.4426, 'order': 0},
          {'latitude': 29.7670, 'longitude': -95.4410, 'order': 1},
          {'latitude': 29.7690, 'longitude': -95.4380, 'order': 2},
          {'latitude': 29.7705, 'longitude': -95.4350, 'order': 3},
          {'latitude': 29.7690, 'longitude': -95.4320, 'order': 4},
          {'latitude': 29.7670, 'longitude': -95.4340, 'order': 5},
          {'latitude': 29.7654, 'longitude': -95.4426, 'order': 6},
        ],
      );

      await _loadUserRoutes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sample Houston running routes added successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add sample routes: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isInsertingSampleRoutes = false;
      });
    }
  }

  Future<void> _generateExampleRoutes() async {
    if (!_isLocationAvailable || !ApiService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!_isLocationAvailable
            ? _locationStatusMessage
            : 'Please sign in to generate routes'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingRoutes = true;
    });

    try {
      await RunningRoutesService.generateExampleRoutes(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
      await _loadUserRoutes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Example routes generated successfully!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate routes: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isGeneratingRoutes = false;
      });
    }
  }

  Future<void> _optimizeRoute(int routeId, String routeName) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Optimizing Route',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Using AI to find cleaner air paths...',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final result = await RunningRoutesService.optimizeRoute(
        routeId: routeId,
        optimizationType: 'pollution',
      );

      Navigator.of(context).pop(); // Close loading dialog
      await _loadUserRoutes(); // Reload routes

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            final optimizationResult = result['optimization_result'];
            final improvement = optimizationResult['actual_improvement'];
            final healthBenefits = optimizationResult['health_specific_benefits'] ?? '';
            final riskAssessment = optimizationResult['pollution_risk_assessment'] ?? '';
            final reasoning = optimizationResult['optimization_reasoning'] ?? '';

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 600),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Route Optimized!',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Text(
                          'Air pollution exposure reduced by $improvement%',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (healthBenefits.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Health Benefits',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    healthBenefits,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              Row(
                                children: [
                                  Icon(
                                    Icons.route,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Optimization Details',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  reasoning,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              if (riskAssessment.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Risk Assessment',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    riskAssessment,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => RouteComparisonScreen(
                                      originalRouteId: routeId,
                                      optimizedRouteId: result['optimized_route_id'],
                                      routeName: routeName,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Compare Routes'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => RouteDetailScreen(
                                      routeId: result['optimized_route_id'],
                                      routeName: '$routeName (Optimized)',
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View Optimized'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
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

  void _viewRouteOnMap(int routeId, String routeName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RouteDetailScreen(
          routeId: routeId,
          routeName: routeName,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Coach'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserRoutes,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            if (ApiService.isAuthenticated) ...[
              _buildMyRoutesCard(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.directions_run,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI-Powered Running Coach',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Get personalized running routes optimized for clean air. Our AI analyzes pollution data to find the healthiest paths and suggests the best times to run.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                ),
              ),
              if (!ApiService.isAuthenticated) ...[
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () {
                    // Navigate to login
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: const Text('Sign in to unlock AI features'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyRoutesCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.route,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'My Running Routes',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (_userRoutes.isEmpty && !_isLoadingRoutes)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton.icon(
                        onPressed: _isInsertingSampleRoutes ? null : _insertSampleRoutes,
                        icon: _isInsertingSampleRoutes
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : const Icon(Icons.add_location, size: 18),
                        label: Text(_isInsertingSampleRoutes ? 'Adding...' : 'Insert Sample Routes'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isGeneratingRoutes ? null : _generateExampleRoutes,
                        icon: _isGeneratingRoutes
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_isGeneratingRoutes ? 'Generating...' : 'AI Generate'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingRoutes)
              const Center(child: CircularProgressIndicator())
            else if (_userRoutes.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No routes yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Generate AI-optimized routes for your location',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._userRoutes.map((route) => _buildRouteItem(route)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteItem(dynamic route) {
    final bool isOptimized = route['name']?.toString().contains('Optimized') ?? false;
    final difficulty = route['difficulty'] ?? 'moderate';
    final difficultyColor = difficulty == 'easy' ? Colors.green
      : difficulty == 'moderate' ? Colors.orange
      : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: isOptimized ? Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isOptimized)
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
                        Expanded(
                          child: Text(
                            route['name'] ?? 'Unnamed Route',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (route['description'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        route['description'],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
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
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.straighten,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${route['distance_km']} km',
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
                '${route['duration_minutes'] ?? (route['distance_km'] * 6).round()} min',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                route['route_type']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'LOOP',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isOptimized)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _optimizeRoute(route['id'], route['name']),
                icon: const Icon(Icons.auto_fix_high, size: 16),
                label: const Text('Optimize Route'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _viewRouteOnMap(route['id'], route['name']),
              icon: const Icon(Icons.map, size: 16),
              label: const Text('View on Map'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}