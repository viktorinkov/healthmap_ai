import 'package:flutter/material.dart';
import '../models/environmental_health_scores.dart';

class EnvironmentalHealthCard extends StatelessWidget {
  final EnvironmentalHealthScores scores;

  const EnvironmentalHealthCard({
    Key? key,
    required this.scores,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildOverallScore(context),
            const SizedBox(height: 20),
            _buildScoreBreakdown(context),
            const SizedBox(height: 20),
            _buildRecommendations(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.eco, size: 24),
        const SizedBox(width: 8),
        Text(
          'Environmental Health Report',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOverallScore(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getScoreColor(scores.overall.level).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getScoreColor(scores.overall.level),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getScoreColor(scores.overall.level),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                scores.overall.score.round().toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall: ${scores.overall.level.displayName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(scores.overall.level),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${scores.overall.level.icon} ${_getOverallDescription()}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBreakdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Breakdown',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildScoreRow(
          context,
          'Air Quality',
          scores.airQuality.score,
          scores.airQuality.level,
          scores.airQuality.primaryConcern,
          Icons.air,
        ),
        _buildScoreRow(
          context,
          'Weather',
          scores.meteorology.score,
          scores.meteorology.level,
          scores.meteorology.primaryConcern,
          Icons.wb_sunny,
        ),
        _buildScoreRow(
          context,
          'Wildfire Risk',
          scores.wildfire.score,
          scores.wildfire.level,
          scores.wildfire.riskDescription,
          Icons.local_fire_department,
        ),
        _buildScoreRow(
          context,
          'Pollen Levels',
          scores.aeroallergens.score,
          scores.aeroallergens.level,
          scores.aeroallergens.dominantAllergen,
          Icons.grass,
        ),
        _buildScoreRow(
          context,
          'Indoor Environment',
          scores.indoorEnvironment.score,
          scores.indoorEnvironment.level,
          scores.indoorEnvironment.primaryConcern,
          Icons.home,
        ),
      ],
    );
  }

  Widget _buildScoreRow(
    BuildContext context,
    String label,
    double score,
    ScoreLevel level,
    String description,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _getScoreColor(level)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getScoreColor(level),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${score.round()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline, size: 20),
            const SizedBox(width: 8),
            Text(
              'Recommendations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...scores.overall.recommendations.map((rec) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, right: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  rec,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 12),
        _buildActivityRecommendations(context),
      ],
    );
  }

  Widget _buildActivityRecommendations(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildActivityRow(
            context,
            'Outdoor Activities',
            scores.overall.safeForOutdoorActivity,
            Icons.directions_walk,
          ),
          const SizedBox(height: 8),
          _buildActivityRow(
            context,
            'Exercise/Sports',
            scores.overall.safeForExercise,
            Icons.fitness_center,
          ),
          const SizedBox(height: 8),
          _buildActivityRow(
            context,
            'Windows Open',
            scores.overall.windowsRecommendation,
            Icons.window,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(
    BuildContext context,
    String activity,
    bool recommended,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: recommended ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            activity,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Icon(
          recommended ? Icons.check_circle : Icons.cancel,
          size: 16,
          color: recommended ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Color _getScoreColor(ScoreLevel level) {
    switch (level) {
      case ScoreLevel.excellent:
        return Colors.green;
      case ScoreLevel.good:
        return Colors.lightGreen;
      case ScoreLevel.moderate:
        return Colors.orange;
      case ScoreLevel.poor:
        return Colors.red;
      case ScoreLevel.hazardous:
        return Colors.purple;
    }
  }

  String _getOverallDescription() {
    if (scores.overall.safeForOutdoorActivity && scores.overall.safeForExercise) {
      return 'Conditions are favorable for all activities';
    } else if (scores.overall.safeForOutdoorActivity) {
      return 'Light outdoor activities recommended';
    } else {
      return 'Consider staying indoors';
    }
  }
}