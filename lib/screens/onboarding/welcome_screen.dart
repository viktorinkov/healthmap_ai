import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.air,
            size: 120,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to HealthMap AI',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your personalized air quality companion',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            'To provide you with personalized health recommendations, we need to learn about your health profile and sensitivities.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.privacy_tip,
                  color: Colors.blue[700],
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Privacy First',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All your health data is stored securely on your device and never shared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'This will take just a few minutes to complete.',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}