import 'package:flutter/material.dart';
import 'package:location/location.dart';
import '../../models/user_health_profile.dart';
import '../../models/air_quality.dart';
import '../../models/pinned_location.dart';
import '../../services/database_service.dart';
import '../../services/gemini_service.dart';
import '../../services/unified_air_quality_service.dart';
import '../../services/air_quality_api_service.dart';
import '../../widgets/unified_location_card.dart';

class RecommendationsTab extends StatefulWidget {
  const RecommendationsTab({Key? key}) : super(key: key);

  @override
  State<RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<RecommendationsTab> {
  UserHealthProfile? _userProfile;
  List<PinnedLocation> _pinnedLocations = [];
  Map<String, AirQualityData> _locationAirQuality = {};
  AirQualityData? _currentLocationAirQuality;
  List<String> _personalizedRecommendations = [];
  bool _isLoading = true;
  bool _isGeneratingRecommendations = false;
  bool _isLoadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load user profile
      _userProfile = await DatabaseService().getUserHealthProfile('user_profile');

      // Load pinned locations
      _pinnedLocations = await DatabaseService().getPinnedLocations();

      // Load air quality data for each pinned location
      await _loadAirQualityForLocations();

      // Load current location air quality data
      await _loadCurrentLocationAirQuality();

      // Generate personalized recommendations
      await _generatePersonalizedRecommendations();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAirQualityForLocations() async {
    _locationAirQuality = await UnifiedAirQualityService.getAirQualityForAllLocations(
      _pinnedLocations,
      userProfile: _userProfile,
    );
  }

  Future<void> _loadCurrentLocationAirQuality() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    try {
      // Get current location
      final location = Location();

      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          // Location service not available
          setState(() {
            _currentLocationAirQuality = null;
            _isLoadingCurrentLocation = false;
          });
          return;
        }
      }

      // Check location permissions
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          // Permission denied
          setState(() {
            _currentLocationAirQuality = null;
            _isLoadingCurrentLocation = false;
          });
          return;
        }
      }

      // Get current location
      LocationData locationData = await location.getLocation();

      if (locationData.latitude != null && locationData.longitude != null) {
        // Fetch current air quality data from Google API
        debugPrint('Fetching air quality for: ${locationData.latitude}, ${locationData.longitude}');
        final airQualityData = await AirQualityApiService.getAirQuality(
          locationData.latitude!,
          locationData.longitude!,
          locationName: 'Current Location',
        );

        if (airQualityData == null) {
          // API returned error or no data
          setState(() {
            _currentLocationAirQuality = null;
            _isLoadingCurrentLocation = false;
          });
          return;
        }

        // Add personalized health recommendations if user profile exists
        final airQualityWithRecommendations = _userProfile != null
            ? airQualityData.copyWith(
                healthRecommendations: _mergeHealthRecommendations(
                  airQualityData.healthRecommendations,
                  UnifiedAirQualityService.generateHealthRecommendations(
                    airQualityData,
                    _userProfile!,
                  ),
                ),
              )
            : airQualityData;

        setState(() {
          _currentLocationAirQuality = airQualityWithRecommendations;
          _isLoadingCurrentLocation = false;
        });
      } else {
        // Unable to get location coordinates
        setState(() {
          _currentLocationAirQuality = null;
          _isLoadingCurrentLocation = false;
        });
      }
    } catch (e) {
      // Error occurred while fetching current location air quality
      debugPrint('Error loading current location air quality: $e');
      setState(() {
        _currentLocationAirQuality = null;
        _isLoadingCurrentLocation = false;
      });
    }
  }

  List<HealthRecommendationTag> _mergeHealthRecommendations(
    List<HealthRecommendationTag>? googleRecommendations,
    List<HealthRecommendationTag> personalizedRecommendations,
  ) {
    final merged = <HealthRecommendationTag>[];

    // Add Google API recommendations first (these are research-backed)
    if (googleRecommendations != null) {
      merged.addAll(googleRecommendations);
    }

    // Add personalized recommendations that don't conflict
    for (final personalizedRec in personalizedRecommendations) {
      // Check if we already have a recommendation for this population
      final hasExisting = merged.any((existing) =>
        existing.population == personalizedRec.population);

      if (!hasExisting) {
        merged.add(personalizedRec);
      }
    }

    return merged;
  }

  Future<void> _generatePersonalizedRecommendations() async {
    if (_userProfile == null) return;

    setState(() {
      _isGeneratingRecommendations = true;
    });

    try {
      // Generate recommendations based on pinned locations
      _personalizedRecommendations = _generatePinnedLocationRecommendations();

      // Try to enhance with Gemini AI if available
      if (GeminiService.isConfigured && _locationAirQuality.isNotEmpty) {
        try {
          final enhancedRecommendations = await GeminiService.generateHealthRecommendations(
            userProfile: _userProfile!,
            recentAirQuality: _locationAirQuality.values.toList(),
            location: _pinnedLocations.isNotEmpty ? _pinnedLocations.first.name : 'Current Location',
          );
          _personalizedRecommendations.addAll(enhancedRecommendations);
        } catch (e) {
          debugPrint('Error with Gemini recommendations: $e');
        }
      }
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      _personalizedRecommendations = ['Unable to generate recommendations at this time.'];
    }

    setState(() {
      _isGeneratingRecommendations = false;
    });
  }


  List<String> _generatePinnedLocationRecommendations() {
    final recommendations = <String>[];

    if (_pinnedLocations.isEmpty) {
      recommendations.add('📌 Add locations you visit frequently to get personalized air quality insights.');
      recommendations.add('🏠 Pin your home, work, gym, or other important places.');
      recommendations.add('💡 Use the map tab to add your first pinned location.');
      return recommendations;
    }

    if (_locationAirQuality.isEmpty) {
      recommendations.add('📊 Loading air quality data for your pinned locations...');
      return recommendations;
    }

    // Analyze air quality across all pinned locations
    final worstLocation = _findWorstAirQualityLocation();
    final bestLocation = _findBestAirQualityLocation();

    if (worstLocation != null && bestLocation != null) {
      final worstData = _locationAirQuality[worstLocation.id]!;
      final bestData = _locationAirQuality[bestLocation.id]!;

      recommendations.add('🏆 Best air quality: ${bestLocation.name} (${bestData.status.displayName})');
      recommendations.add('⚠️ Worst air quality: ${worstLocation.name} (${worstData.status.displayName})');

      // Generate health-based recommendations
      recommendations.addAll(_generateHealthBasedRecommendations(worstData));
    }

    return recommendations;
  }

  PinnedLocation? _findWorstAirQualityLocation() {
    if (_locationAirQuality.isEmpty) return null;

    String? worstId;
    double worstScore = -1;

    _locationAirQuality.forEach((id, data) {
      if (data.metrics.overallScore > worstScore) {
        worstScore = data.metrics.overallScore;
        worstId = id;
      }
    });

    return worstId != null ? _pinnedLocations.firstWhere((loc) => loc.id == worstId) : null;
  }

  PinnedLocation? _findBestAirQualityLocation() {
    if (_locationAirQuality.isEmpty) return null;

    String? bestId;
    double bestScore = double.infinity;

    _locationAirQuality.forEach((id, data) {
      if (data.metrics.overallScore < bestScore) {
        bestScore = data.metrics.overallScore;
        bestId = id;
      }
    });

    return bestId != null ? _pinnedLocations.firstWhere((loc) => loc.id == bestId) : null;
  }

  List<String> _generateHealthBasedRecommendations(AirQualityData airQuality) {
    final recommendations = <String>[];
    final status = airQuality.status;

    // Health condition specific recommendations
    if (_userProfile?.conditions.contains(HealthCondition.asthma) == true) {
      if (status != AirQualityStatus.good) {
        recommendations.add('💨 Keep your inhaler handy due to poor air quality.');
      }
    }

    if (_userProfile?.conditions.contains(HealthCondition.heartDisease) == true) {
      if (status == AirQualityStatus.avoid) {
        recommendations.add('❤️ Avoid strenuous outdoor activities due to your heart condition.');
      }
    }

    if (_userProfile?.isPregnant == true) {
      if (status != AirQualityStatus.good) {
        recommendations.add('🤱 Take extra precautions during pregnancy - limit outdoor exposure.');
      }
    }

    if (_userProfile?.ageGroup == AgeGroup.child) {
      recommendations.add('👶 Children should avoid prolonged outdoor activities when air quality is poor.');
    }

    if (_userProfile?.ageGroup == AgeGroup.olderAdult) {
      recommendations.add('👵 Older adults should be extra cautious during poor air quality days.');
    }

    // Lifestyle recommendations
    if (_userProfile?.lifestyleRisks.contains(LifestyleRisk.athlete) == true) {
      if (status == AirQualityStatus.caution) {
        recommendations.add('🏃‍♀️ Consider indoor workouts today.');
      } else if (status == AirQualityStatus.avoid) {
        recommendations.add('🏋️‍♂️ Move your workout indoors for your health and performance.');
      }
    }

    return recommendations;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Air Quality Summary'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Quality Summary'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHereAndNowRiskCard(),
            const SizedBox(height: 16),
            if (_pinnedLocations.isNotEmpty) ..._buildPinnedLocationsSummary(),
            if (_pinnedLocations.isNotEmpty) const SizedBox(height: 16),
            _buildPersonalizedRecommendationsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHereAndNowRiskCard() {
    if (_isLoadingCurrentLocation) {
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
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Here & Now Risk',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Getting your location...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentLocationAirQuality == null) {
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
                children: [
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Here & Now Risk',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.location_off,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Location data unavailable',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please enable location services or check permissions',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadCurrentLocationAirQuality,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return UnifiedLocationCard(
      airQuality: _currentLocationAirQuality,
      isCurrentLocation: true,
      onRefresh: _loadData,
    );
  }

  List<Widget> _buildPinnedLocationsSummary() {
    return _pinnedLocations.map((location) {
      final airQuality = _locationAirQuality[location.id];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: UnifiedLocationCard(
          location: location,
          airQuality: airQuality,
          showFullDetails: false,
          onRefresh: _loadData,
        ),
      );
    }).toList();
  }









  Widget _buildPersonalizedRecommendationsSection() {
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
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Personalized\nRecommendations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isGeneratingRecommendations)
              const Center(child: CircularProgressIndicator())
            else
              ..._personalizedRecommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  recommendation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }


}

