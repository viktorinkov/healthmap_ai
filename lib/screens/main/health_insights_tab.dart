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
  final HealthInsightsService _healthService = HealthInsightsService();
  final UnifiedHealthService _unifiedService = UnifiedHealthService();
  
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
      
      // Fetch all health data in parallel
      final results = await Future.wait([
        _healthService.getHeartRateData(userId),
        _healthService.getActivityData(userId),
        _healthService.getHealthSummary(userId),
        _healthService.getDailyInsights(userId),
        _unifiedService.getUnifiedHealthInsights(userId),
      ]);
      
      setState(() {
        _heartRateData = results[0];
        _activityData = results[1];
        _healthSummary = results[2];
        _dailyInsights = results[3];
        _unifiedInsights = results[4];
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
    final healthScore = _healthSummary?['health_score'] ?? 0;
    final trend = _healthSummary?['trend'] ?? 'stable';
    
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
    final insights = _dailyInsights?['insights'] as List<dynamic>? ?? [];
    final generatedAt = _dailyInsights?['generated_at'] ?? DateTime.now().toIso8601String();
    
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
    final currentHr = _heartRateData?['current_heart_rate'] ?? 0;
    final avgHr = _heartRateData?['average_heart_rate'] ?? 0;
    final restingHr = _heartRateData?['resting_heart_rate'] ?? 0;
    
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
    final steps = _activityData?['steps'] ?? 0;
    final calories = _activityData?['calories'] ?? 0;
    final activeMinutes = _activityData?['active_minutes'] ?? 0;
    
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
                _buildMetricColumn('Steps', steps.toString(), '', Colors.blue),
                _buildMetricColumn('Calories', calories.toString(), 'cal', Colors.orange),
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