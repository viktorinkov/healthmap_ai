import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'onboarding_flow.dart';

class SensitivityScreen extends StatelessWidget {
  const SensitivityScreen({Key? key}) : super(key: key);

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
                'Sensitivity Level',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How sensitive are you to air quality changes? This helps us customize your recommendations.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Less Sensitive'),
                                Text(
                                  '${data.sensitivityLevel}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const Text('More Sensitive'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Slider(
                              value: data.sensitivityLevel.toDouble(),
                              min: 1,
                              max: 5,
                              divisions: 4,
                              onChanged: (double value) {
                                data.updateSensitivityLevel(value.round());
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _getSensitivityDescription(data.sensitivityLevel),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildSensitivityExample(
                            context,
                            1,
                            'Rarely Affected',
                            'You hardly notice air quality changes and can exercise outdoors even on moderate air quality days.',
                            Icons.fitness_center,
                            Colors.green,
                          ),
                          _buildSensitivityExample(
                            context,
                            2,
                            'Mildly Sensitive',
                            'You occasionally notice poor air quality, especially during heavy pollution or wildfire events.',
                            Icons.sentiment_satisfied,
                            Colors.lightGreen,
                          ),
                          _buildSensitivityExample(
                            context,
                            3,
                            'Moderately Sensitive',
                            'You notice air quality changes and may adjust outdoor activities based on conditions.',
                            Icons.sentiment_neutral,
                            Colors.orange,
                          ),
                          _buildSensitivityExample(
                            context,
                            4,
                            'Quite Sensitive',
                            'You frequently notice air quality changes and need to be careful about outdoor activities.',
                            Icons.sentiment_dissatisfied,
                            Colors.deepOrange,
                          ),
                          _buildSensitivityExample(
                            context,
                            5,
                            'Very Sensitive',
                            'You are highly sensitive to air pollution and need to carefully monitor conditions daily.',
                            Icons.warning,
                            Colors.red,
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  'Your sensitivity level affects the thresholds we use for recommendations. You can change this later in settings.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensitivityExample(
    BuildContext context,
    int level,
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Consumer<OnboardingData>(
      builder: (context, data, child) {
        final isSelected = data.sensitivityLevel == level;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? color.withOpacity(0.1) : null,
          child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(
              '$level. $title',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(description),
            onTap: () {
              data.updateSensitivityLevel(level);
            },
          ),
        );
      },
    );
  }

  String _getSensitivityDescription(int level) {
    switch (level) {
      case 1:
        return 'You rarely notice air quality changes and are comfortable exercising outdoors in most conditions.';
      case 2:
        return 'You occasionally notice poor air quality, especially during severe pollution events.';
      case 3:
        return 'You notice air quality changes and may adjust outdoor activities based on conditions.';
      case 4:
        return 'You frequently notice air quality changes and need to be careful about outdoor activities.';
      case 5:
        return 'You are highly sensitive to air pollution and need to carefully monitor conditions daily.';
      default:
        return '';
    }
  }
}