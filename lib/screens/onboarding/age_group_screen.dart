import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'onboarding_flow.dart';
import '../../models/user_health_profile.dart';

class AgeGroupScreen extends StatelessWidget {
  const AgeGroupScreen({Key? key}) : super(key: key);

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
                'Age Group',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Age affects air quality sensitivity. Children and older adults are typically more vulnerable to air pollution.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: AgeGroup.values.map((ageGroup) {
                    final isSelected = data.ageGroup == ageGroup;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: RadioListTile<AgeGroup>(
                        value: ageGroup,
                        groupValue: data.ageGroup,
                        onChanged: (AgeGroup? value) {
                          if (value != null) {
                            data.updateAgeGroup(value);
                          }
                        },
                        title: Text(ageGroup.displayName),
                        subtitle: Text(_getAgeGroupDescription(ageGroup)),
                        secondary: Icon(
                          _getAgeGroupIcon(ageGroup),
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (data.ageGroup == AgeGroup.adult)
                Card(
                  color: Colors.pink[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pregnant_woman, color: Colors.pink[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Pregnancy Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.pink[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          value: data.isPregnant,
                          onChanged: (bool? value) {
                            data.updatePregnancy(value ?? false);
                          },
                          title: const Text('I am currently pregnant'),
                          subtitle: const Text('Pregnancy increases sensitivity to air pollutants'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
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
                  'Age-based recommendations help us provide more accurate health guidance.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getAgeGroupDescription(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'Under 18 years old - developing respiratory systems are more sensitive';
      case AgeGroup.adult:
        return '18-64 years old - generally less sensitive to air pollution';
      case AgeGroup.olderAdult:
        return '65+ years old - may have increased sensitivity due to age-related changes';
    }
  }

  IconData _getAgeGroupIcon(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return Icons.child_care;
      case AgeGroup.adult:
        return Icons.person;
      case AgeGroup.olderAdult:
        return Icons.elderly;
    }
  }
}