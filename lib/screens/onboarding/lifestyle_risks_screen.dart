import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'onboarding_flow.dart';
import '../../models/user_health_profile.dart';

class LifestyleRisksScreen extends StatelessWidget {
  const LifestyleRisksScreen({Key? key}) : super(key: key);

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
                'Lifestyle Factors',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These lifestyle factors can increase your exposure to air pollutants.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: LifestyleRisk.values.map((risk) {
                    final isSelected = data.lifestyleRisks.contains(risk);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          final updatedRisks = List<LifestyleRisk>.from(data.lifestyleRisks);
                          if (value == true) {
                            updatedRisks.add(risk);
                          } else {
                            updatedRisks.remove(risk);
                          }
                          data.updateLifestyleRisks(updatedRisks);
                        },
                        title: Text(_getRiskDisplayName(risk)),
                        subtitle: Text(_getRiskDescription(risk)),
                        secondary: Icon(
                          _getRiskIcon(risk),
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
                  'Select all that apply. These factors help us understand your potential exposure levels.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRiskDisplayName(LifestyleRisk risk) {
    switch (risk) {
      case LifestyleRisk.outdoorWorker:
        return 'Outdoor Worker';
      case LifestyleRisk.athlete:
        return 'Regular Athlete/Exerciser';
      case LifestyleRisk.smoker:
        return 'Smoker or Exposed to Smoke';
      case LifestyleRisk.frequentCommuter:
        return 'Frequent Commuter';
    }
  }

  String _getRiskDescription(LifestyleRisk risk) {
    switch (risk) {
      case LifestyleRisk.outdoorWorker:
        return 'Construction, landscaping, delivery, or other outdoor work';
      case LifestyleRisk.athlete:
        return 'Regular outdoor exercise or sports activities';
      case LifestyleRisk.smoker:
        return 'Current smoker or regularly exposed to secondhand smoke';
      case LifestyleRisk.frequentCommuter:
        return 'Long daily commutes in traffic or public transportation';
    }
  }

  IconData _getRiskIcon(LifestyleRisk risk) {
    switch (risk) {
      case LifestyleRisk.outdoorWorker:
        return Icons.construction;
      case LifestyleRisk.athlete:
        return Icons.fitness_center;
      case LifestyleRisk.smoker:
        return Icons.smoking_rooms;
      case LifestyleRisk.frequentCommuter:
        return Icons.commute;
    }
  }
}