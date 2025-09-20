import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'onboarding_flow.dart';
import '../../models/user_health_profile.dart';

class HealthConditionsScreen extends StatelessWidget {
  const HealthConditionsScreen({Key? key}) : super(key: key);

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
                'Health Conditions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Do you have any of these health conditions? This helps us provide more accurate recommendations.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: HealthCondition.values.map((condition) {
                    final isSelected = data.conditions.contains(condition);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          final updatedConditions = List<HealthCondition>.from(data.conditions);
                          if (value == true) {
                            updatedConditions.add(condition);
                          } else {
                            updatedConditions.remove(condition);
                          }
                          data.updateConditions(updatedConditions);
                        },
                        title: Text(condition.displayName),
                        subtitle: Text(_getConditionDescription(condition)),
                        secondary: Icon(
                          _getConditionIcon(condition),
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Select all that apply. This information helps us adjust air quality thresholds for your specific health needs.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getConditionDescription(HealthCondition condition) {
    switch (condition) {
      case HealthCondition.asthma:
        return 'Chronic respiratory condition affecting airways';
      case HealthCondition.copd:
        return 'Chronic obstructive pulmonary disease';
      case HealthCondition.heartDisease:
        return 'Cardiovascular conditions and heart problems';
      case HealthCondition.diabetes:
        return 'Type 1 or Type 2 diabetes';
      case HealthCondition.lungDisease:
        return 'Other lung or respiratory diseases';
    }
  }

  IconData _getConditionIcon(HealthCondition condition) {
    switch (condition) {
      case HealthCondition.asthma:
        return Icons.air;
      case HealthCondition.copd:
        return Icons.health_and_safety;
      case HealthCondition.heartDisease:
        return Icons.favorite;
      case HealthCondition.diabetes:
        return Icons.medication;
      case HealthCondition.lungDisease:
        return Icons.healing;
    }
  }
}