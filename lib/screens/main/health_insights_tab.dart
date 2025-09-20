import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/health_insights_service.dart';
import '../../services/unified_health_service.dart';
import '../../models/user_health_profile.dart';
import '../../services/database_service.dart';

class HealthInsightsTab extends StatefulWidget {
  const HealthInsightsTab({Key? key}) : super(key: key);

  @override
  State<HealthInsightsTab> createState() => _HealthInsightsTabState();
}

class _HealthInsightsTabState extends State<HealthInsightsTab> {
  bool _isLoading = true;
  String? _error;
  
  // Health metrics data
  Map<String, dynamic>? _heartRateData;
  Map<String, dynamic>? _activityData;
  Map<String, dynamic>? _healthSummary;
  Map<String, dynamic>? _dailyInsights;
  Map<String, dynamic>? _unifiedInsights;
  
  UserHealthProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load user profile
      _userProfile = await DatabaseService().getUserHealthProfile('user_profile');
      
      // For demo purposes, using a sample user ID
      const userId = 'user_001';
      
      // Fetch health data using static methods with longer ranges for meaningful data
      _heartRateData = await HealthInsightsService.getHeartRateData(
        userId: userId,
        startDate: '2025-08-01',  // Start from August to catch our sample data
        endDate: '2025-09-30'     // End date covers current period
      );
      _activityData = await HealthInsightsService.getActivityData(
        userId: userId, 
        days: 60  // Look back 60 days to catch sample data
      );
      _healthSummary = await HealthInsightsService.getHealthSummary(
        userId: userId,
        days: 60  // Look back 60 days to catch sample data
      );
      
      // For daily insights, we need air quality data
      final airQualityData = {'status': 'good', 'aqi': 50, 'pm25': 10.5};
      if (_userProfile != null) {
        _dailyInsights = await HealthInsightsService.getDailyHealthSummary(
          userId: userId,
          airQualityData: airQualityData,
          userProfile: _userProfile!,
        );
      }
      
      // Get unified insights
      _unifiedInsights = await UnifiedHealthService.getUnifiedRecommendation(
        userId: userId,
        currentLocation: {'latitude': 29.7604, 'longitude': -95.3698},
      );
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load health data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Insights'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHealthData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadHealthData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildHealthScoreCard(),
                      const SizedBox(height: 16),
                      _buildDailyInsightsCard(),
                      const SizedBox(height: 16),
                      _buildHeartRateCard(),
                      const SizedBox(height: 16),
                      _buildActivityCard(),
                      const SizedBox(height: 16),
                      _buildUnifiedInsightsCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Health Data',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadHealthData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    // Calculate health score from available data
    final summary = _healthSummary?['summary'] ?? {};
    final avgSteps = (double.tryParse(summary['avg_steps']?.toString() ?? '0') ?? 0.0).round();
    final avgHeartRate = (double.tryParse(summary['avg_heart_rate']?.toString() ?? '70') ?? 70.0).round();
    final avgSpo2 = (double.tryParse(summary['avg_spo2']?.toString() ?? '98') ?? 98.0).round();
    
    // Simple health score calculation based on available metrics
    int healthScore = 50; // Base score
    if (avgSteps >= 10000) healthScore += 30;
    else if (avgSteps >= 7500) healthScore += 20;
    else if (avgSteps >= 5000) healthScore += 10;
    
    if (avgHeartRate >= 60 && avgHeartRate <= 100) healthScore += 15;
    if (avgSpo2 >= 95) healthScore += 5;
    
    healthScore = healthScore.clamp(0, 100);
    final trend = 'stable'; // Default trend
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Overall Health Score',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: healthScore / 100,
                      strokeWidth: 12,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getHealthScoreColor(healthScore),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$healthScore',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getHealthScoreColor(healthScore),
                        ),
                      ),
                      Text(
                        'out of 100',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTrendIndicator(trend),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyInsightsCard() {
    final insight = _dailyInsights?['insight'] ?? 'No insights available. Make sure both backends are running.';
    final insights = insight is String ? [insight] : (insight is List ? insight : [insight.toString()]);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Health Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Powered by Gemini AI',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            if (insights.isEmpty)
              Text(
                'No insights available. Make sure both backends are running.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...insights.map((insight) => _buildInsightItem(insight)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(dynamic insight) {
    IconData icon;
    Color color;
    
    // Determine icon and color based on insight type
    if (insight.toString().toLowerCase().contains('heart') || 
        insight.toString().toLowerCase().contains('cardiovascular')) {
      icon = Icons.favorite;
      color = Colors.red;
    } else if (insight.toString().toLowerCase().contains('activity') || 
               insight.toString().toLowerCase().contains('exercise')) {
      icon = Icons.directions_run;
      color = Colors.blue;
    } else if (insight.toString().toLowerCase().contains('sleep') || 
               insight.toString().toLowerCase().contains('rest')) {
      icon = Icons.bedtime;
      color = Colors.indigo;
    } else if (insight.toString().toLowerCase().contains('stress') || 
               insight.toString().toLowerCase().contains('recovery')) {
      icon = Icons.spa;
      color = Colors.green;
    } else {
      icon = Icons.lightbulb_outline;
      color = Theme.of(context).colorScheme.primary;
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateCard() {
    final heartRateList = _heartRateData?['data'] as List<dynamic>? ?? [];
    
    int currentHr = 0;
    int avgHr = 0;
    int restingHr = 0;
    
    if (heartRateList.isNotEmpty) {
      // Current HR is the most recent reading
      currentHr = (double.tryParse(heartRateList.first['heart_rate']?.toString() ?? '0') ?? 0.0).round();
      
      // Calculate average HR from all readings
      final hrValues = heartRateList
          .map((e) => double.tryParse(e['heart_rate']?.toString() ?? '0') ?? 0.0)
          .where((hr) => hr > 0)
          .toList();
      
      if (hrValues.isNotEmpty) {
        avgHr = (hrValues.reduce((a, b) => a + b) / hrValues.length).round();
        
        // Estimate resting HR as the lowest 20% of readings
        hrValues.sort();
        final restingCount = (hrValues.length * 0.2).ceil();
        if (restingCount > 0) {
          final restingValues = hrValues.take(restingCount);
          restingHr = (restingValues.reduce((a, b) => a + b) / restingValues.length).round();
        }
      }
    }
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Heart Rate',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('Current', '$currentHr', 'bpm', Colors.red),
                _buildMetricColumn('Average', '$avgHr', 'bpm', Colors.orange),
                _buildMetricColumn('Resting', '$restingHr', 'bpm', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    final activityList = _activityData?['data'] as List<dynamic>? ?? [];
    
    int totalSteps = 0;
    int totalCalories = 0;
    double totalDistance = 0.0;
    
    if (activityList.isNotEmpty) {
      // Calculate totals from recent activity data
      for (final activity in activityList) {
        totalSteps += ((activity['steps'] ?? 0) as num).round();
        totalCalories += ((activity['calories'] ?? 0) as num).round();
        totalDistance += ((activity['distance'] ?? 0.0) as num).toDouble();
      }
      
      // Get averages per day
      final days = activityList.length;
      if (days > 0) {
        totalSteps = (totalSteps / days).round();
        totalCalories = (totalCalories / days).round();
        totalDistance = totalDistance / days;
      }
    }
    
    // Estimate active minutes based on steps (rough calculation)
    final activeMinutes = (totalSteps / 120).round(); // ~120 steps per minute of activity
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions_run, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('Steps', totalSteps.toString(), '', Colors.blue),
                _buildMetricColumn('Calories', totalCalories.toString(), 'cal', Colors.orange),
                _buildMetricColumn('Active', activeMinutes.toString(), 'min', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedInsightsCard() {
    final recommendation = _unifiedInsights?['recommendation'] ?? 
        'Connect both backends to see unified health and environmental insights.';
    final confidence = _unifiedInsights?['confidence'] ?? 0.0;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.integration_instructions, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Unified Health & Environment',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                recommendation,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            if (confidence > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Confidence: ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: confidence,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(confidence * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (unit.isNotEmpty)
          Text(
            unit,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildTrendIndicator(String trend) {
    IconData icon;
    Color color;
    String text;
    
    switch (trend.toLowerCase()) {
      case 'improving':
        icon = Icons.trending_up;
        color = Colors.green;
        text = 'Health Improving';
        break;
      case 'declining':
        icon = Icons.trending_down;
        color = Colors.red;
        text = 'Needs Attention';
        break;
      default:
        icon = Icons.trending_flat;
        color = Colors.orange;
        text = 'Stable';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}