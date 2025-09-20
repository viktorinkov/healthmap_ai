// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pollen_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PollenForecast _$PollenForecastFromJson(Map<String, dynamic> json) =>
    PollenForecast(
      regionCode: json['regionCode'] as String,
      dailyInfo: (json['dailyInfo'] as List<dynamic>)
          .map((e) => PollenDailyInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PollenForecastToJson(PollenForecast instance) =>
    <String, dynamic>{
      'regionCode': instance.regionCode,
      'dailyInfo': instance.dailyInfo,
    };

PollenDailyInfo _$PollenDailyInfoFromJson(Map<String, dynamic> json) =>
    PollenDailyInfo(
      date: DateTime.parse(json['date'] as String),
      pollenTypeInfo: (json['pollenTypeInfo'] as List<dynamic>)
          .map((e) => PollenTypeInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      plantInfo: (json['plantInfo'] as List<dynamic>)
          .map((e) => PlantInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PollenDailyInfoToJson(PollenDailyInfo instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'pollenTypeInfo': instance.pollenTypeInfo,
      'plantInfo': instance.plantInfo,
    };

PollenTypeInfo _$PollenTypeInfoFromJson(Map<String, dynamic> json) =>
    PollenTypeInfo(
      code: $enumDecode(_$PollenTypeEnumMap, json['code']),
      displayName: json['displayName'] as String,
      inSeason: json['inSeason'] as bool,
      indexInfo: json['indexInfo'] == null
          ? null
          : PollenIndexInfo.fromJson(json['indexInfo'] as Map<String, dynamic>),
      healthRecommendation: json['healthRecommendation'] == null
          ? null
          : PollenHealthRecommendation.fromJson(
              json['healthRecommendation'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PollenTypeInfoToJson(PollenTypeInfo instance) =>
    <String, dynamic>{
      'code': _$PollenTypeEnumMap[instance.code]!,
      'displayName': instance.displayName,
      'inSeason': instance.inSeason,
      'indexInfo': instance.indexInfo,
      'healthRecommendation': instance.healthRecommendation,
    };

const _$PollenTypeEnumMap = {
  PollenType.grass: 'GRASS',
  PollenType.tree: 'TREE',
  PollenType.weed: 'WEED',
};

PollenIndexInfo _$PollenIndexInfoFromJson(Map<String, dynamic> json) =>
    PollenIndexInfo(
      value: (json['value'] as num).toInt(),
      category: $enumDecode(_$PollenIndexCategoryEnumMap, json['category']),
      indexDescription: json['indexDescription'] as String,
      color: json['color'] == null
          ? null
          : Color.fromJson(json['color'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PollenIndexInfoToJson(PollenIndexInfo instance) =>
    <String, dynamic>{
      'value': instance.value,
      'category': _$PollenIndexCategoryEnumMap[instance.category]!,
      'indexDescription': instance.indexDescription,
      'color': instance.color,
    };

const _$PollenIndexCategoryEnumMap = {
  PollenIndexCategory.none: 'UPI_CATEGORY_0',
  PollenIndexCategory.veryLow: 'UPI_CATEGORY_1',
  PollenIndexCategory.low: 'UPI_CATEGORY_2',
  PollenIndexCategory.moderate: 'UPI_CATEGORY_3',
  PollenIndexCategory.high: 'UPI_CATEGORY_4',
  PollenIndexCategory.veryHigh: 'UPI_CATEGORY_5',
};

Color _$ColorFromJson(Map<String, dynamic> json) => Color(
      red: (json['red'] as num).toDouble(),
      green: (json['green'] as num).toDouble(),
      blue: (json['blue'] as num).toDouble(),
      alpha: (json['alpha'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ColorToJson(Color instance) => <String, dynamic>{
      'red': instance.red,
      'green': instance.green,
      'blue': instance.blue,
      'alpha': instance.alpha,
    };

PollenHealthRecommendation _$PollenHealthRecommendationFromJson(
        Map<String, dynamic> json) =>
    PollenHealthRecommendation(
      generalPopulation: json['generalPopulation'] as String,
      elderly: json['elderly'] as String?,
      lungDiseaseAtRisk: json['lungDiseaseAtRisk'] as String?,
      heartDiseaseAtRisk: json['heartDiseaseAtRisk'] as String?,
      athletes: json['athletes'] as String?,
      pregnantWomen: json['pregnantWomen'] as String?,
      children: json['children'] as String?,
    );

Map<String, dynamic> _$PollenHealthRecommendationToJson(
        PollenHealthRecommendation instance) =>
    <String, dynamic>{
      'generalPopulation': instance.generalPopulation,
      'elderly': instance.elderly,
      'lungDiseaseAtRisk': instance.lungDiseaseAtRisk,
      'heartDiseaseAtRisk': instance.heartDiseaseAtRisk,
      'athletes': instance.athletes,
      'pregnantWomen': instance.pregnantWomen,
      'children': instance.children,
    };

PlantInfo _$PlantInfoFromJson(Map<String, dynamic> json) => PlantInfo(
      code: $enumDecode(_$PlantTypeEnumMap, json['code']),
      displayName: json['displayName'] as String,
      inSeason: json['inSeason'] as bool,
      indexInfo: json['indexInfo'] == null
          ? null
          : PollenIndexInfo.fromJson(json['indexInfo'] as Map<String, dynamic>),
      plantDescription: json['plantDescription'] == null
          ? null
          : PlantDescription.fromJson(
              json['plantDescription'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PlantInfoToJson(PlantInfo instance) => <String, dynamic>{
      'code': _$PlantTypeEnumMap[instance.code]!,
      'displayName': instance.displayName,
      'inSeason': instance.inSeason,
      'indexInfo': instance.indexInfo,
      'plantDescription': instance.plantDescription,
    };

const _$PlantTypeEnumMap = {
  PlantType.alder: 'ALDER',
  PlantType.birch: 'BIRCH',
  PlantType.cypress: 'CYPRESS',
  PlantType.elm: 'ELM',
  PlantType.hazel: 'HAZEL',
  PlantType.oak: 'OAK',
  PlantType.pine: 'PINE',
  PlantType.plane: 'PLANE',
  PlantType.poplar: 'POPLAR',
  PlantType.ash: 'ASH',
  PlantType.cottonwood: 'COTTONWOOD',
  PlantType.graminales: 'GRAMINALES',
  PlantType.ragweed: 'RAGWEED',
  PlantType.mugwort: 'MUGWORT',
  PlantType.olive: 'OLIVE',
  PlantType.juniper: 'JUNIPER',
  PlantType.chenopod: 'CHENOPOD',
};

PlantDescription _$PlantDescriptionFromJson(Map<String, dynamic> json) =>
    PlantDescription(
      type: json['type'] as String?,
      family: json['family'] as String?,
      season: json['season'] as String?,
      specialShapes: json['specialShapes'] as String?,
      specialColors: json['specialColors'] as String?,
      crossReaction: json['crossReaction'] as String?,
      picture: json['picture'] as String?,
      pictureCloseup: json['pictureCloseup'] as String?,
    );

Map<String, dynamic> _$PlantDescriptionToJson(PlantDescription instance) =>
    <String, dynamic>{
      'type': instance.type,
      'family': instance.family,
      'season': instance.season,
      'specialShapes': instance.specialShapes,
      'specialColors': instance.specialColors,
      'crossReaction': instance.crossReaction,
      'picture': instance.picture,
      'pictureCloseup': instance.pictureCloseup,
    };
