// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_health_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserHealthProfile _$UserHealthProfileFromJson(Map<String, dynamic> json) =>
    UserHealthProfile(
      id: json['id'] as String,
      conditions: (json['conditions'] as List<dynamic>)
          .map((e) => $enumDecode(_$HealthConditionEnumMap, e))
          .toList(),
      ageGroup: $enumDecode(_$AgeGroupEnumMap, json['ageGroup']),
      isPregnant: json['isPregnant'] as bool? ?? false,
      sensitivityLevel: (json['sensitivityLevel'] as num?)?.toInt() ?? 3,
      lifestyleRisks: (json['lifestyleRisks'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$LifestyleRiskEnumMap, e))
              .toList() ??
          const [],
      domesticRisks: (json['domesticRisks'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$DomesticRiskEnumMap, e))
              .toList() ??
          const [],
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );

Map<String, dynamic> _$UserHealthProfileToJson(UserHealthProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conditions':
          instance.conditions.map((e) => _$HealthConditionEnumMap[e]!).toList(),
      'ageGroup': _$AgeGroupEnumMap[instance.ageGroup]!,
      'isPregnant': instance.isPregnant,
      'sensitivityLevel': instance.sensitivityLevel,
      'lifestyleRisks': instance.lifestyleRisks
          .map((e) => _$LifestyleRiskEnumMap[e]!)
          .toList(),
      'domesticRisks':
          instance.domesticRisks.map((e) => _$DomesticRiskEnumMap[e]!).toList(),
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

const _$HealthConditionEnumMap = {
  HealthCondition.asthma: 'asthma',
  HealthCondition.copd: 'copd',
  HealthCondition.heartDisease: 'heart_disease',
  HealthCondition.diabetes: 'diabetes',
  HealthCondition.lungDisease: 'lung_disease',
};

const _$AgeGroupEnumMap = {
  AgeGroup.child: 'child',
  AgeGroup.adult: 'adult',
  AgeGroup.olderAdult: 'older_adult',
};

const _$LifestyleRiskEnumMap = {
  LifestyleRisk.outdoorWorker: 'outdoor_worker',
  LifestyleRisk.athlete: 'athlete',
  LifestyleRisk.smoker: 'smoker',
  LifestyleRisk.frequentCommuter: 'frequent_commuter',
};

const _$DomesticRiskEnumMap = {
  DomesticRisk.oldBuilding: 'old_building',
  DomesticRisk.poorVentilation: 'poor_ventilation',
  DomesticRisk.basementDwelling: 'basement_dwelling',
  DomesticRisk.industrialArea: 'industrial_area',
  DomesticRisk.highTrafficArea: 'high_traffic_area',
};
