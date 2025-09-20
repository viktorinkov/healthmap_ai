import 'package:json_annotation/json_annotation.dart';

part 'user_health_profile.g.dart';

@JsonSerializable()
class UserHealthProfile {
  final String id;
  final List<HealthCondition> conditions;
  final AgeGroup ageGroup;
  final bool isPregnant;
  final int sensitivityLevel; // 1-5, higher = more sensitive
  final List<LifestyleRisk> lifestyleRisks;
  final List<DomesticRisk> domesticRisks;
  final DateTime lastUpdated;

  const UserHealthProfile({
    required this.id,
    required this.conditions,
    required this.ageGroup,
    this.isPregnant = false,
    this.sensitivityLevel = 3,
    this.lifestyleRisks = const [],
    this.domesticRisks = const [],
    required this.lastUpdated,
  });

  factory UserHealthProfile.fromJson(Map<String, dynamic> json) => _$UserHealthProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserHealthProfileToJson(this);

  double get riskMultiplier {
    double multiplier = 1.0;

    // Age-based adjustments
    if (ageGroup == AgeGroup.child || ageGroup == AgeGroup.olderAdult) {
      multiplier += 0.3;
    }

    // Pregnancy adjustment
    if (isPregnant) {
      multiplier += 0.4;
    }

    // Health condition adjustments
    for (var condition in conditions) {
      switch (condition) {
        case HealthCondition.asthma:
          multiplier += 0.5;
          break;
        case HealthCondition.copd:
          multiplier += 0.6;
          break;
        case HealthCondition.heartDisease:
          multiplier += 0.4;
          break;
        case HealthCondition.diabetes:
          multiplier += 0.2;
          break;
        case HealthCondition.lungDisease:
          multiplier += 0.5;
          break;
      }
    }

    // Sensitivity level adjustment
    multiplier += (sensitivityLevel - 3) * 0.1;

    return multiplier.clamp(1.0, 3.0);
  }
}

enum HealthCondition {
  @JsonValue('asthma')
  asthma,
  @JsonValue('copd')
  copd,
  @JsonValue('heart_disease')
  heartDisease,
  @JsonValue('diabetes')
  diabetes,
  @JsonValue('lung_disease')
  lungDisease,
}

enum AgeGroup {
  @JsonValue('child')
  child,
  @JsonValue('adult')
  adult,
  @JsonValue('older_adult')
  olderAdult,
}

enum LifestyleRisk {
  @JsonValue('outdoor_worker')
  outdoorWorker,
  @JsonValue('athlete')
  athlete,
  @JsonValue('smoker')
  smoker,
  @JsonValue('frequent_commuter')
  frequentCommuter,
}

enum DomesticRisk {
  @JsonValue('old_building')
  oldBuilding,
  @JsonValue('poor_ventilation')
  poorVentilation,
  @JsonValue('basement_dwelling')
  basementDwelling,
  @JsonValue('industrial_area')
  industrialArea,
  @JsonValue('high_traffic_area')
  highTrafficArea,
}

extension HealthConditionExtension on HealthCondition {
  String get displayName {
    switch (this) {
      case HealthCondition.asthma:
        return 'Asthma';
      case HealthCondition.copd:
        return 'COPD';
      case HealthCondition.heartDisease:
        return 'Heart Disease';
      case HealthCondition.diabetes:
        return 'Diabetes';
      case HealthCondition.lungDisease:
        return 'Lung Disease';
    }
  }
}

extension AgeGroupExtension on AgeGroup {
  String get displayName {
    switch (this) {
      case AgeGroup.child:
        return 'Child (under 18)';
      case AgeGroup.adult:
        return 'Adult (18-64)';
      case AgeGroup.olderAdult:
        return 'Older Adult (65+)';
    }
  }
}