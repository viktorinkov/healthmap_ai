import 'package:flutter/material.dart';
import '../models/run_coach_models.dart';

class RouteDetailsCard extends StatelessWidget {
  final RunRoute route;
  final VoidCallback onNavigatePressed;

  const RouteDetailsCard({
    Key? key,
    required this.route,
    required this.onNavigatePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended Route',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Route metrics grid
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.straighten,
                    label: 'Distance',
                    value: '${route.distanceKm.toStringAsFixed(1)} km',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.timer,
                    label: 'Duration',
                    value: '${route.durationMin.toInt()} min',
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.terrain,
                    label: 'Elevation',
                    value: '+${route.elevationGainM.toInt()}m',
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Air quality info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getAqiColor(route.avgAqi).withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.air,
                    color: _getAqiColor(route.avgAqi),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Air Quality',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          'Avg AQI: ${route.avgAqi.toInt()} (${_getAqiLabel(route.avgAqi)})',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Max: ${route.maxAqi.toInt()}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      Text(
                        'Exposure: ${(route.exposureScore * 100).toInt()}%',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
            // Additional route features
            Wrap(
              children: [
                _RouteFeature(
                  icon: Icons.park,
                  label: 'Green spaces',
                  value: '${(route.greenCoverage * 100).toInt()}%',
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _RouteFeature(
                  icon: Icons.security,
                  label: 'Safety score',
                  value: '${(route.safetyScore * 100).toInt()}%',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAqiColor(double aqi) {
    if (aqi <= 50) return Colors.green;
    if (aqi <= 100) return Colors.yellow[700]!;
    if (aqi <= 150) return Colors.orange;
    if (aqi <= 200) return Colors.red;
    return Colors.purple;
  }

  String _getAqiLabel(double aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    return 'Very Unhealthy';
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RouteFeature extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _RouteFeature({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Text('$label: ', style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class OptimalTimesCard extends StatelessWidget {
  final List<TimeWindow> timeWindows;
  final Function(TimeWindow) onTimeSelected;

  const OptimalTimesCard({
    Key? key,
    required this.timeWindows,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Best Times to Run',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Based on air quality forecasts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(180),
              ),
            ),
            const SizedBox(height: 16),
            
            // Time window list
            ...timeWindows.map((window) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TimeWindowTile(
                window: window,
                onTap: () => onTimeSelected(window),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _TimeWindowTile extends StatelessWidget {
  final TimeWindow window;
  final VoidCallback onTap;

  const _TimeWindowTile({
    required this.window,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final qualityColor = _getQualityColor(window.quality);
    
    return Material(
      color: qualityColor.withAlpha(26),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                color: qualityColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      window.timeRange,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'AQI: ${window.avgAqi.toInt()} - ${window.quality}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: qualityColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(window.confidence * 100).toInt()}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getQualityColor(String quality) {
    switch (quality) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.yellow[700]!;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class HealthRiskCard extends StatelessWidget {
  final HealthRiskAssessment assessment;

  const HealthRiskCard({
    Key? key,
    required this.assessment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final riskColor = _getRiskColor(assessment.currentRiskLevel);
    final budget = assessment.exposureBudget;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal Health Risk',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Risk level indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: riskColor.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                children: [
                  Icon(
                    Icons.favorite,
                    color: riskColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Risk Level: ${assessment.riskLevelDisplay}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: riskColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Threshold: ${assessment.personalThreshold.toInt()} AQI',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Exposure budget
            Text(
              'Weekly Exposure Budget',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            // Progress bar
            LinearProgressIndicator(
              value: (budget['usage_percentage'] as double) / 100,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                (budget['usage_percentage'] as double) > 80
                    ? Colors.orange
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${budget['usage_percentage'].toInt()}% used',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${budget['remaining_budget'].toInt()} remaining',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel) {
      case 'very_low':
        return Colors.green;
      case 'low':
        return Colors.lightGreen;
      case 'moderate':
        return Colors.yellow[700]!;
      case 'high':
        return Colors.orange;
      case 'very_high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}