import 'package:flutter/material.dart';
import '../../models/user_health_profile.dart';
import '../../models/air_quality.dart';
import '../../services/database_service.dart';
import '../../services/fake_data_service.dart';
import '../../services/gemini_service.dart';

class RecommendationsTab extends StatefulWidget {
  const RecommendationsTab({Key? key}) : super(key: key);

  @override
  State<RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<RecommendationsTab> {
  UserHealthProfile? _userProfile;
  List<AirQualityData> _recentAirQuality = [];
  List<String> _recommendations = [];
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

      // Load recent air quality data
      _recentAirQuality = await DatabaseService().getAirQualityData();

      // If no data, generate some fake data for Houston
      if (_recentAirQuality.isEmpty) {
        _recentAirQuality = FakeDataService.generateRecentAirQualityHistory(
          'Houston',
          29.7604,
          -95.3698,
          7,
        );

        // Save to database
        for (final data in _recentAirQuality) {
          await DatabaseService().saveAirQualityData(data);
        }
      }

      // Generate recommendations
      await _generateRecommendations();

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

  Future<void> _generateRecommendations() async {
    if (_userProfile == null || _recentAirQuality.isEmpty) return;

    setState(() {
      _isGeneratingRecommendations = true;
    });

    try {
      // Try to use Gemini AI first, fallback to basic recommendations
      if (GeminiService.isConfigured) {
        _recommendations = await GeminiService.generateHealthRecommendations(
          userProfile: _userProfile!,
          recentAirQuality: _recentAirQuality,
          location: 'Houston',
        );
      } else {
        // Fallback to basic recommendations if no API key
        _recommendations = _generateBasicRecommendations();
        _recommendations.insert(0, '💡 Add Gemini API key to .env for AI-powered recommendations');
      }
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
      _recommendations = _generateBasicRecommendations();
      _recommendations.insert(0, '⚠️ Using basic recommendations (Gemini API unavailable)');
    }

    setState(() {
      _isGeneratingRecommendations = false;
    });
  }

  List<String> _generateBasicRecommendations() {
    final recommendations = <String>[];
    final currentAirQuality = _recentAirQuality.first;
    final metrics = currentAirQuality.metrics;
    final status = currentAirQuality.status;
    final riskMultiplier = _userProfile?.riskMultiplier ?? 1.0;

    // General status-based recommendations
    switch (status) {
      case AirQualityStatus.good:
        recommendations.add('✅ Air quality is good today! Perfect for outdoor activities and exercise.');
        if (riskMultiplier > 1.5) {
          recommendations.add('🏃‍♀️ Even with your sensitivities, outdoor exercise is safe today.');
        }
        break;

      case AirQualityStatus.caution:
        recommendations.add('⚠️ Air quality is moderate. Limit prolonged outdoor activities.');
        if (_userProfile?.conditions.contains(HealthCondition.asthma) == true) {
          recommendations.add('💨 Keep your inhaler handy and consider indoor alternatives for exercise.');
        }
        if (riskMultiplier > 2.0) {
          recommendations.add('🏠 Consider staying indoors for extended periods today.');
        }
        break;

      case AirQualityStatus.avoid:
        recommendations.add('🚨 Poor air quality detected. Avoid outdoor activities and keep windows closed.');
        recommendations.add('😷 Wear a mask if you must go outside.');
        if (_userProfile?.conditions.contains(HealthCondition.copd) == true) {
          recommendations.add('🫁 Monitor your symptoms closely and have rescue medications ready.');
        }
        break;
    }

    // Specific pollutant recommendations
    if (metrics.pm25 > 15) {
      recommendations.add('🌪️ High PM2.5 levels detected. Use air purifiers indoors and avoid outdoor exercise.');
    }

    if (metrics.o3 > 50) {
      recommendations.add('☀️ Elevated ozone levels. Exercise early morning or late evening when ozone is lower.');
    }

    if (metrics.wildfireIndex > 25) {
      recommendations.add('🔥 Wildfire smoke detected. Keep windows and doors closed, use air purifiers.');
    }

    if (metrics.radon > 2.5) {
      recommendations.add('🏠 Elevated radon levels. Ensure good ventilation in lower levels of your home.');
    }

    // Health condition specific recommendations
    if (_userProfile?.conditions.contains(HealthCondition.heartDisease) == true) {
      recommendations.add('❤️ With heart conditions, avoid strenuous outdoor activities when air quality is poor.');
    }

    if (_userProfile?.isPregnant == true) {
      recommendations.add('🤱 During pregnancy, take extra precautions and limit exposure to poor air quality.');
    }

    if (_userProfile?.ageGroup == AgeGroup.child) {
      recommendations.add('👶 Children are more sensitive to air pollution. Consider indoor play activities.');
    }

    if (_userProfile?.ageGroup == AgeGroup.olderAdult) {
      recommendations.add('👵 Older adults should be extra cautious during poor air quality days.');
    }

    // Lifestyle recommendations
    if (_userProfile?.lifestyleRisks.contains(LifestyleRisk.outdoorWorker) == true) {
      if (status != AirQualityStatus.good) {
        recommendations.add('👷‍♂️ As an outdoor worker, take frequent breaks indoors and wear protective equipment.');
      }
    }

    if (_userProfile?.lifestyleRisks.contains(LifestyleRisk.athlete) == true) {
      if (status == AirQualityStatus.caution) {
        recommendations.add('🏃‍♀️ Consider indoor workouts or reduce exercise intensity today.');
      } else if (status == AirQualityStatus.avoid) {
        recommendations.add('🏋️‍♂️ Move your workout indoors today for your health and performance.');
      }
    }

    // General health tips
    recommendations.add('💧 Stay hydrated and maintain good indoor air quality with plants or purifiers.');

    if (status != AirQualityStatus.good) {
      recommendations.add('🌡️ Check air quality again this evening as conditions may improve.');
    }

    return recommendations;
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
        title: const Text('Daily Recommendations'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateRecommendations,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCurrentStatusCard(),
            const SizedBox(height: 16),
            _buildRecommendationsSection(),
            const SizedBox(height: 16),
            _buildAirQualityTrendCard(),
            const SizedBox(height: 16),
            _buildHealthTipsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    if (_recentAirQuality.isEmpty) return const SizedBox.shrink();

    final current = _recentAirQuality.first;
    final status = current.status;
    final color = _getStatusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
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
                ),
                const Spacer(),
                Text(
                  _formatTime(current.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              current.locationName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(current.statusReason),
            const SizedBox(height: 12),
            _buildQuickMetrics(current.metrics),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetrics(AirQualityMetrics metrics) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildMetricItem('PM2.5', metrics.pm25.toInt().toString()),
        _buildMetricItem('PM10', metrics.pm10.toInt().toString()),
        _buildMetricItem('O3', metrics.o3.toInt().toString()),
        _buildMetricItem('Score', (100 - metrics.overallScore).toInt().toString()),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationsSection() {
    return Card(
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
              ..._recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  recommendation,
                  style: const TextStyle(fontSize: 16),
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAirQualityTrendCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '7-Day Air Quality Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _recentAirQuality.length,
                itemBuilder: (context, index) {
                  final data = _recentAirQuality[index];
                  final score = 100 - data.metrics.overallScore;
                  return Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Container(
                          height: 60,
                          width: 40,
                          decoration: BoxDecoration(
                            color: _getStatusColor(data.status).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _getStatusColor(data.status)),
                          ),
                          child: Center(
                            child: Text(
                              score.toInt().toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatShortDate(data.timestamp),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTipsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'General Health Tips',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('🌱 Keep indoor plants to naturally purify air'),
            const SizedBox(height: 8),
            const Text('🚗 Avoid exercising near busy roads during peak traffic'),
            const SizedBox(height: 8),
            const Text('🌅 Best outdoor exercise times: early morning or evening'),
            const SizedBox(height: 8),
            const Text('🏠 Use exhaust fans when cooking to improve indoor air quality'),
            const SizedBox(height: 8),
            const Text('💨 Change HVAC filters regularly for better air filtration'),
          ],
        ),
      ),
    );
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

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  String _formatShortDate(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}';
  }
}