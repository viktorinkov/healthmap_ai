import 'package:flutter/material.dart';
import '../../models/user_health_profile.dart';
import '../../models/air_quality.dart';
import '../../models/pinned_location.dart';
import '../../services/database_service.dart';
import '../../services/gemini_service.dart';

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

  Future<void> _loadCurrentLocationAirQuality() async {
    // Generate sample current location air quality data
    // In a real app, this would use GPS and real API data
    _currentLocationAirQuality = _generateCurrentLocationAirQualityData();
  }

  AirQualityData _generateCurrentLocationAirQualityData() {
    // Generate realistic current location air quality data
    final random = DateTime.now().millisecond;
    final baseVariation = (random % 100) / 100.0;

    // Base values for current location (Houston-like values)
    final baseValues = {'pm25': 12.0, 'pm10': 25.0, 'o3': 42.0, 'no2': 24.0};

    final pm25 = (baseValues['pm25']! * (1 + (baseVariation - 0.5) * 0.4)).clamp(5.0, 35.0);
    final pm10 = (baseValues['pm10']! * (1 + (baseVariation - 0.5) * 0.4)).clamp(10.0, 60.0);
    final o3 = (baseValues['o3']! * (1 + (baseVariation - 0.5) * 0.3)).clamp(20.0, 80.0);
    final no2 = (baseValues['no2']! * (1 + (baseVariation - 0.5) * 0.4)).clamp(10.0, 50.0);

    // Optional pollutants
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
      universalAqi: null,
    );

    final status = AirQualityStatusExtension.fromScore(metrics.overallScore);

    return AirQualityData(
      id: 'current_location_${DateTime.now().millisecondsSinceEpoch}',
      locationName: 'Current Location',
      latitude: 29.7604, // Houston coordinates as default
      longitude: -95.3698,
      timestamp: DateTime.now().subtract(Duration(minutes: random % 30)),
      metrics: metrics,
      status: status,
      statusReason: _generateStatusReason(metrics, status),
    );
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
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ),
        ),
      );
    }

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Here & Now Risk',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Current location air quality',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(_currentLocationAirQuality!.status),
              ],
            ),
            const SizedBox(height: 16),
            _buildUniversalAqi(_currentLocationAirQuality!),
            const SizedBox(height: 12),
            _buildPollutantGrid(_currentLocationAirQuality!.metrics),
            const SizedBox(height: 12),
            _buildHealthRecommendationTags(_currentLocationAirQuality!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPinnedLocationsSummary() {
    return _pinnedLocations.map((location) {
      final airQuality = _locationAirQuality[location.id];
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildLocationCard(location, airQuality),
      );
    }).toList();
  }

  Widget _buildLocationCard(PinnedLocation location, AirQualityData? airQuality) {
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
                Text(
                  location.type.icon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (airQuality != null) _buildStatusBadge(airQuality.status),
              ],
            ),
            if (airQuality != null) ...[
              const SizedBox(height: 16),
              _buildUniversalAqi(airQuality),
              const SizedBox(height: 12),
              _buildPollutantGrid(airQuality.metrics),
              const SizedBox(height: 12),
              _buildHealthRecommendationTags(airQuality),
            ] else ...[
              const SizedBox(height: 12),
              Text(
                'Air quality data not available',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(AirQualityStatus status) {
    Color color;
    switch (status) {
      case AirQualityStatus.good:
        color = Colors.green;
        break;
      case AirQualityStatus.caution:
        color = Colors.orange;
        break;
      case AirQualityStatus.avoid:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.displayName.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildUniversalAqi(AirQualityData airQuality) {
    final aqi = airQuality.metrics.universalAqi ?? (100 - airQuality.metrics.overallScore).round();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.air, size: 20),
          const SizedBox(width: 8),
          Text(
            'Universal AQI: ',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            aqi.toString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPollutantGrid(AirQualityMetrics metrics) {
    final pollutants = [
      _PollutantInfo('PM2.5', metrics.pm25, 'μg/m³'),
      _PollutantInfo('PM10', metrics.pm10, 'μg/m³'),
      _PollutantInfo('O₃', metrics.o3, 'ppb'),
      _PollutantInfo('NO₂', metrics.no2, 'ppb'),
      if (metrics.co != null) _PollutantInfo('CO', metrics.co!, 'ppb'),
      if (metrics.so2 != null) _PollutantInfo('SO₂', metrics.so2!, 'ppb'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pollutants',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pollutants.map((pollutant) => _buildPollutantChip(pollutant)).toList(),
        ),
      ],
    );
  }

  Widget _buildPollutantChip(_PollutantInfo pollutant) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${pollutant.name}: ${pollutant.value.toStringAsFixed(1)} ${pollutant.unit}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  Widget _buildHealthRecommendationTags(AirQualityData airQuality) {
    // Generate sample health recommendations based on user profile
    final tags = _generateSampleHealthTags(airQuality);

    if (tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Recommendations',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) => _buildHealthTag(tag)).toList(),
        ),
      ],
    );
  }

  List<HealthRecommendationTag> _generateSampleHealthTags(AirQualityData airQuality) {
    final tags = <HealthRecommendationTag>[];

    // Generate tags based on user profile
    if (_userProfile?.conditions.contains(HealthCondition.asthma) == true) {
      tags.add(HealthRecommendationTag(
        population: HealthPopulation.lungDisease,
        recommendation: airQuality.status == AirQualityStatus.good ? 'Safe for outdoor activities' : 'Consider staying indoors',
        level: airQuality.status == AirQualityStatus.good ? HealthAdviceLevel.safe : HealthAdviceLevel.caution,
      ));
    }

    if (_userProfile?.ageGroup == AgeGroup.child) {
      tags.add(HealthRecommendationTag(
        population: HealthPopulation.children,
        recommendation: airQuality.status == AirQualityStatus.good ? 'Good for outdoor play' : 'Limit outdoor activities',
        level: airQuality.status == AirQualityStatus.good ? HealthAdviceLevel.safe : HealthAdviceLevel.caution,
      ));
    }

    if (_userProfile?.lifestyleRisks.contains(LifestyleRisk.athlete) == true) {
      tags.add(HealthRecommendationTag(
        population: HealthPopulation.athletes,
        recommendation: airQuality.status == AirQualityStatus.good ? 'Safe for training' : 'Consider indoor workouts',
        level: airQuality.status == AirQualityStatus.good ? HealthAdviceLevel.safe : HealthAdviceLevel.caution,
      ));
    }

    // Always add general population recommendation
    tags.add(HealthRecommendationTag(
      population: HealthPopulation.general,
      recommendation: airQuality.status == AirQualityStatus.good
        ? 'Good air quality for everyone'
        : 'Sensitive individuals should limit outdoor exposure',
      level: airQuality.status == AirQualityStatus.good ? HealthAdviceLevel.safe : HealthAdviceLevel.caution,
    ));

    return tags;
  }

  Widget _buildHealthTag(HealthRecommendationTag tag) {
    Color color;
    switch (tag.level) {
      case HealthAdviceLevel.safe:
        color = Colors.green;
        break;
      case HealthAdviceLevel.caution:
        color = Colors.orange;
        break;
      case HealthAdviceLevel.avoid:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag.population.icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              tag.recommendation,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
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
                const Icon(Icons.lightbulb, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Personalized Recommendations',
                  style: Theme.of(context).textTheme.titleLarge,
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

class _PollutantInfo {
  final String name;
  final double value;
  final String unit;

  _PollutantInfo(this.name, this.value, this.unit);
}