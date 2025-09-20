import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'onboarding_flow.dart';
import '../../models/user_health_profile.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingData>(
      builder: (context, data, child) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Profile Summary',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Review your health profile. You can change these settings anytime in the app.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: [
                    _buildSummaryCard(
                      context,
                      'Age Group',
                      data.ageGroup?.displayName ?? 'Not specified',
                      Icons.person,
                      Colors.blue,
                      subtitle: data.isPregnant ? 'Currently pregnant' : null,
                    ),
                    _buildSummaryCard(
                      context,
                      'Health Conditions',
                      data.conditions.isEmpty
                          ? 'None selected'
                          : data.conditions.map((c) => c.displayName).join(', '),
                      Icons.health_and_safety,
                      Colors.red,
                    ),
                    _buildSummaryCard(
                      context,
                      'Lifestyle Factors',
                      data.lifestyleRisks.isEmpty
                          ? 'None selected'
                          : data.lifestyleRisks.map((r) => _getLifestyleRiskName(r)).join(', '),
                      Icons.fitness_center,
                      Colors.green,
                    ),
                    _buildSummaryCard(
                      context,
                      'Home Environment',
                      data.domesticRisks.isEmpty
                          ? 'No risk factors'
                          : data.domesticRisks.map((r) => _getDomesticRiskName(r)).join(', '),
                      Icons.home,
                      Colors.purple,
                    ),
                    const SizedBox(height: 20),
                    _buildRiskAssessment(context, data),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[700],
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Setup Complete!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your personalized air quality recommendations are ready.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.pink[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAssessment(BuildContext context, OnboardingData data) {
    final profile = UserHealthProfile(
      id: 'temp',
      conditions: data.conditions,
      ageGroup: data.ageGroup ?? AgeGroup.adult,
      isPregnant: data.isPregnant,
      lifestyleRisks: data.lifestyleRisks,
      domesticRisks: data.domesticRisks,
      lastUpdated: DateTime.now(),
    );

    final riskMultiplier = profile.riskMultiplier;
    final riskLevel = _getRiskLevel(riskMultiplier);
    final riskColor = _getRiskColor(riskLevel);

    return Card(
      color: riskColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assessment, color: riskColor),
                const SizedBox(width: 8),
                Text(
                  'Your Risk Assessment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: riskColor,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Overall Sensitivity: ${riskLevel.toUpperCase()}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: riskColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getRiskDescription(riskLevel, riskMultiplier),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }


  String _getLifestyleRiskName(LifestyleRisk risk) {
    switch (risk) {
      case LifestyleRisk.outdoorWorker: return 'Outdoor Work';
      case LifestyleRisk.athlete: return 'Athlete';
      case LifestyleRisk.smoker: return 'Smoker';
      case LifestyleRisk.frequentCommuter: return 'Commuter';
    }
  }

  String _getDomesticRiskName(DomesticRisk risk) {
    switch (risk) {
      case DomesticRisk.oldBuilding: return 'Old Building';
      case DomesticRisk.poorVentilation: return 'Poor Ventilation';
      case DomesticRisk.basementDwelling: return 'Basement Living';
      case DomesticRisk.industrialArea: return 'Industrial Area';
      case DomesticRisk.highTrafficArea: return 'High Traffic';
    }
  }

  String _getRiskLevel(double multiplier) {
    if (multiplier <= 1.2) return 'low';
    if (multiplier <= 1.5) return 'moderate';
    if (multiplier <= 2.0) return 'high';
    return 'very high';
  }

  Color _getRiskColor(String level) {
    switch (level) {
      case 'low': return Colors.green;
      case 'moderate': return Colors.orange;
      case 'high': return Colors.red;
      case 'very high': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getRiskDescription(String level, double multiplier) {
    switch (level) {
      case 'low':
        return 'You have low sensitivity to air pollution. Standard air quality guidelines apply to you.';
      case 'moderate':
        return 'You have moderate sensitivity. We\'ll provide enhanced recommendations during poor air quality days.';
      case 'high':
        return 'You have high sensitivity to air pollution. We\'ll provide stricter thresholds and more protective recommendations.';
      case 'very high':
        return 'You have very high sensitivity. We\'ll provide the most protective recommendations and closely monitor air quality for you.';
      default:
        return 'We\'ll provide personalized recommendations based on your profile.';
    }
  }
}