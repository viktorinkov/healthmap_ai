import 'package:flutter/material.dart';
import '../../models/user_health_profile.dart';
import '../../services/database_service.dart';
import '../../widgets/sensitive_health_data_card.dart';
import '../onboarding/onboarding_flow.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserHealthProfile? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _userProfile =
          await DatabaseService().getUserHealthProfile('user_profile');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_userProfile == null) {
      return _buildOnboardingRequired();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileSummaryCard(),
          const SizedBox(height: 16),
          _buildRiskCalculationCard(),
          const SizedBox(height: 16),
          _buildAgeCard(),
          const SizedBox(height: 16),
          _buildHealthConditionsCard(),
          const SizedBox(height: 16),
          _buildLifestyleFactorsCard(),
          const SizedBox(height: 16),
          _buildHomeEnvironmentCard(),
          const SizedBox(height: 16),
          const SensitiveHealthDataCard(),
          const SizedBox(height: 16),
          _buildSettingsCard(),
        ],
      ),
    );
  }

  Widget _buildOnboardingRequired() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Complete Your Profile',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Set up your health profile to get personalized air quality recommendations.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => const OnboardingFlow(),
                        ),
                      )
                      .then((_) => _loadData());
                },
                child: const Text('Set Up Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard() {
    final riskMultiplier = _userProfile!.riskMultiplier;
    final riskLevel = _getRiskLevel(riskMultiplier);
    final riskColor = _getRiskColor(riskLevel);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Health Profile',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: ${_formatDate(_userProfile!.lastUpdated)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: riskColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.assessment, color: riskColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sensitivity Level: ${riskLevel.toUpperCase()}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                        Text(
                          'Risk multiplier: ${riskMultiplier.toStringAsFixed(1)}x',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getAgeIcon(_userProfile!.ageGroup),
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Age Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cake, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Age Group: ${_userProfile!.ageGroup.displayName}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getAgeGroupDescription(_userProfile!.ageGroup),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCalculationCard() {
    final riskMultiplier = _userProfile!.riskMultiplier;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Risk Sensitivity Calculation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'How we calculate your risk sensitivity:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your risk sensitivity score (${riskMultiplier.toStringAsFixed(1)}x) is calculated based on multiple factors that increase your vulnerability to air pollution. We start with a baseline of 1.0x and add risk factors: age-related vulnerabilities (+0.3x for children and older adults), pregnancy status (+0.4x), and specific health conditions (asthma/lung disease +0.5x, COPD +0.6x, heart disease +0.4x, diabetes +0.2x). This personalized multiplier helps us provide more accurate air quality recommendations tailored to your individual health profile.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthConditionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Health Conditions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_userProfile!.conditions.isEmpty)
              const Text('No health conditions reported')
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _userProfile!.conditions.map((condition) {
                  return Chip(
                    label: Text(condition.displayName),
                    backgroundColor: Colors.red[50],
                  );
                }).toList(),
              ),
            if (_userProfile!.isPregnant) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.pink[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pregnant_woman,
                        color: Colors.pink[700], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Pregnant',
                      style: TextStyle(color: Colors.pink[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLifestyleFactorsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fitness_center, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Lifestyle Factors',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_userProfile!.lifestyleRisks.isEmpty)
              const Text('No lifestyle risk factors')
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _userProfile!.lifestyleRisks.map((risk) {
                  return Chip(
                    label: Text(_getLifestyleRiskName(risk)),
                    backgroundColor: Colors.green[50],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeEnvironmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.home, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Home Environment',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_userProfile!.domesticRisks.isEmpty)
              const Text('No environmental risk factors')
            else
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _userProfile!.domesticRisks.map((risk) {
                  return Chip(
                    label: Text(_getDomesticRiskName(risk)),
                    backgroundColor: Colors.purple[50],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit),
              title: const Text('Edit Health Profile'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _editProfile,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info),
              title: const Text('About'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                _showAboutDialog();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Clear All Data',
                  style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showClearDataDialog,
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const OnboardingFlow(),
          ),
        )
        .then((_) => _loadData());
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About HealthMap AI'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'HealthMap AI helps you monitor air quality and make informed decisions about your health.'),
            SizedBox(height: 12),
            Text('Features:'),
            Text('• Personalized air quality recommendations'),
            Text('• Real-time air quality monitoring'),
            Text('• Location-based health alerts'),
            Text('• Health condition-specific guidance'),
            SizedBox(height: 12),
            Text('Version 1.0.0'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your health profile data, saved locations, and preferences. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseService().clearAllData();
              Navigator.of(context).pop();
              _loadData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );
  }

  String _getRiskLevel(double multiplier) {
    if (multiplier <= 1.2) return 'low';
    if (multiplier <= 1.5) return 'moderate';
    if (multiplier <= 2.0) return 'high';
    return 'very high';
  }

  Color _getRiskColor(String level) {
    switch (level) {
      case 'low':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'very high':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getLifestyleRiskName(LifestyleRisk risk) {
    switch (risk) {
      case LifestyleRisk.outdoorWorker:
        return 'Outdoor Work';
      case LifestyleRisk.athlete:
        return 'Athlete';
      case LifestyleRisk.smoker:
        return 'Smoker';
      case LifestyleRisk.frequentCommuter:
        return 'Commuter';
    }
  }

  String _getDomesticRiskName(DomesticRisk risk) {
    switch (risk) {
      case DomesticRisk.oldBuilding:
        return 'Old Building';
      case DomesticRisk.poorVentilation:
        return 'Poor Ventilation';
      case DomesticRisk.basementDwelling:
        return 'Basement Living';
      case DomesticRisk.industrialArea:
        return 'Industrial Area';
      case DomesticRisk.highTrafficArea:
        return 'High Traffic';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _getAgeIcon(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return Icons.child_care;
      case AgeGroup.adult:
        return Icons.person;
      case AgeGroup.olderAdult:
        return Icons.elderly;
    }
  }

  String _getAgeGroupDescription(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.child:
        return 'Children have developing respiratory systems that are more vulnerable to air pollution.';
      case AgeGroup.adult:
        return 'Adults typically have the strongest defense against air pollution effects.';
      case AgeGroup.olderAdult:
        return 'Older adults may have reduced immune function and increased sensitivity to air quality.';
    }
  }
}
