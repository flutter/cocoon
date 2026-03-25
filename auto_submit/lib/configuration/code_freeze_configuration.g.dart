// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'code_freeze_configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CodeFreezeConfiguration _$CodeFreezeConfigurationFromJson(
  Map<String, dynamic> json,
) => CodeFreezeConfiguration(
  (json['repoFreezeCriteria'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, FreezeCriteria.fromJson(e as Map<String, dynamic>)),
      ) ??
      const <String, FreezeCriteria>{},
);

Map<String, dynamic> _$CodeFreezeConfigurationToJson(
  CodeFreezeConfiguration instance,
) => <String, dynamic>{
  'repoFreezeCriteria': instance.repoFreezeCriteria.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
};

FreezeCriteria _$FreezeCriteriaFromJson(Map<String, dynamic> json) =>
    FreezeCriteria(
      frozenLabels:
          (json['frozen_labels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
      frozenPaths:
          (json['frozen_paths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
    );

Map<String, dynamic> _$FreezeCriteriaToJson(FreezeCriteria instance) =>
    <String, dynamic>{
      'frozen_labels': instance.frozenLabels.toList(),
      'frozen_paths': instance.frozenPaths.toList(),
    };
