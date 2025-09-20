import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'onboarding_flow.dart';
import '../../models/user_health_profile.dart';

class DomesticRisksScreen extends StatelessWidget {
  const DomesticRisksScreen({Key? key}) : super(key: key);

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
                'Home Environment',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These environmental factors at home can affect indoor air quality and your overall exposure.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  children: DomesticRisk.values.map((risk) {
                    final isSelected = data.domesticRisks.contains(risk);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          final updatedRisks = List<DomesticRisk>.from(data.domesticRisks);
                          if (value == true) {
                            updatedRisks.add(risk);
                          } else {
                            updatedRisks.remove(risk);
                          }
                          data.updateDomesticRisks(updatedRisks);
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
                  'Your home environment affects indoor air quality. These factors help us provide comprehensive recommendations.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getRiskDisplayName(DomesticRisk risk) {
    switch (risk) {
      case DomesticRisk.oldBuilding:
        return 'Older Building (Pre-1980)';
      case DomesticRisk.poorVentilation:
        return 'Poor Ventilation';
      case DomesticRisk.basementDwelling:
        return 'Basement Living Space';
      case DomesticRisk.industrialArea:
        return 'Near Industrial Area';
      case DomesticRisk.highTrafficArea:
        return 'High Traffic Area';
    }
  }

  String _getRiskDescription(DomesticRisk risk) {
    switch (risk) {
      case DomesticRisk.oldBuilding:
        return 'Older buildings may have asbestos, lead paint, or poor insulation';
      case DomesticRisk.poorVentilation:
        return 'Limited air circulation, no exhaust fans, or sealed windows';
      case DomesticRisk.basementDwelling:
        return 'Living in or spending significant time in basement areas';
      case DomesticRisk.industrialArea:
        return 'Located near factories, refineries, or industrial facilities';
      case DomesticRisk.highTrafficArea:
        return 'Near busy roads, highways, or major traffic intersections';
    }
  }

  IconData _getRiskIcon(DomesticRisk risk) {
    switch (risk) {
      case DomesticRisk.oldBuilding:
        return Icons.home_repair_service;
      case DomesticRisk.poorVentilation:
        return Icons.air;
      case DomesticRisk.basementDwelling:
        return Icons.stairs;
      case DomesticRisk.industrialArea:
        return Icons.factory;
      case DomesticRisk.highTrafficArea:
        return Icons.traffic;
    }
  }
}