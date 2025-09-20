import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'welcome_screen.dart';
import 'health_conditions_screen.dart';
import 'age_group_screen.dart';
import 'lifestyle_risks_screen.dart';
import 'domestic_risks_screen.dart';
import 'summary_screen.dart';
import '../../models/user_health_profile.dart';
import '../../services/database_service.dart';
import '../../services/api_service.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({Key? key}) : super(key: key);

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final OnboardingData _data = OnboardingData();

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      const WelcomeScreen(),
      const HealthConditionsScreen(),
      const AgeGroupScreen(),
      const LifestyleRisksScreen(),
      const DomesticRisksScreen(),
      const SummaryScreen(),
    ]);
  }

  void _nextPage() {
    if (_currentPage < _screens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    try {
      final profile = UserHealthProfile(
        id: 'user_profile',
        conditions: _data.conditions,
        ageGroup: _data.ageGroup!,
        isPregnant: _data.isPregnant,
        lifestyleRisks: _data.lifestyleRisks,
        domesticRisks: _data.domesticRisks,
        lastUpdated: DateTime.now(),
      );

      // Save profile locally for offline access
      await DatabaseService().saveUserHealthProfile(profile);

      // Convert profile to backend format and save to backend
      if (ApiService.isAuthenticated) {
        final profileData = {
          'age': _data.ageGroup == AgeGroup.child
            ? 8
            : _data.ageGroup == AgeGroup.adult
              ? 35
              : 70,
          'has_respiratory_condition': _data.conditions.contains(HealthCondition.asthma) ||
                                        _data.conditions.contains(HealthCondition.copd) ||
                                        _data.conditions.contains(HealthCondition.lungDisease),
          'has_heart_condition': _data.conditions.contains(HealthCondition.heartDisease),
          'has_allergies': false,
          'is_elderly': _data.ageGroup == AgeGroup.olderAdult,
          'is_child': _data.ageGroup == AgeGroup.child,
          'is_pregnant': _data.isPregnant,
          'exercises_outdoors': _data.lifestyleRisks.contains(LifestyleRisk.athlete) ||
                                _data.lifestyleRisks.contains(LifestyleRisk.outdoorWorker),
          'medications': _data.conditions.isNotEmpty ? 'Multiple health conditions requiring medication' : null,
          'notes': 'Profile created through onboarding flow'
        };

        await ApiService.updateMedicalProfile(profileData);
        await ApiService.completeOnboarding();
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete onboarding: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _data,
      child: Scaffold(
        body: Column(
          children: [
            // Progress indicator
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: (_currentPage + 1) / _screens.length,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step ${_currentPage + 1} of ${_screens.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: _screens,
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  if (_currentPage < _screens.length - 1)
                    ElevatedButton(
                      onPressed: _nextPage,
                      child: const Text('Next'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _completeOnboarding,
                      child: const Text('Complete'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData extends ChangeNotifier {
  List<HealthCondition> _conditions = [];
  AgeGroup? _ageGroup;
  bool _isPregnant = false;
  List<LifestyleRisk> _lifestyleRisks = [];
  List<DomesticRisk> _domesticRisks = [];

  List<HealthCondition> get conditions => _conditions;
  AgeGroup? get ageGroup => _ageGroup;
  bool get isPregnant => _isPregnant;
  List<LifestyleRisk> get lifestyleRisks => _lifestyleRisks;
  List<DomesticRisk> get domesticRisks => _domesticRisks;

  void updateConditions(List<HealthCondition> conditions) {
    _conditions = conditions;
    notifyListeners();
  }

  void updateAgeGroup(AgeGroup ageGroup) {
    _ageGroup = ageGroup;
    notifyListeners();
  }

  void updatePregnancy(bool isPregnant) {
    _isPregnant = isPregnant;
    notifyListeners();
  }


  void updateLifestyleRisks(List<LifestyleRisk> risks) {
    _lifestyleRisks = risks;
    notifyListeners();
  }

  void updateDomesticRisks(List<DomesticRisk> risks) {
    _domesticRisks = risks;
    notifyListeners();
  }
}