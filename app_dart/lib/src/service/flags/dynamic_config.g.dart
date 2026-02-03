// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter, use_null_aware_elements

part of 'dynamic_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DynamicConfig _$DynamicConfigFromJson(Map<String, dynamic> json) =>
    DynamicConfig(
      backfillerCommitLimit: (json['backfillerCommitLimit'] as num?)?.toInt(),
      ciYaml: json['ciYaml'] == null
          ? null
          : CiYamlFlags.fromJson(json['ciYaml'] as Map<String, dynamic>?),
      contentAwareHashing: json['contentAwareHashing'] == null
          ? null
          : ContentAwareHashing.fromJson(
              json['contentAwareHashing'] as Map<String, dynamic>?,
            ),
      closeMqGuardAfterPresubmit: json['closeMqGuardAfterPresubmit'] as bool?,
      unifiedCheckRunFlow: json['unifiedCheckRunFlow'] == null
          ? null
          : UnifiedCheckRunFlow.fromJson(
              json['unifiedCheckRunFlow'] as Map<String, dynamic>?,
            ),
      dynamicTestSuppression: json['dynamicTestSuppression'] as bool?,
    );

Map<String, dynamic> _$DynamicConfigToJson(DynamicConfig instance) =>
    <String, dynamic>{
      'backfillerCommitLimit': instance.backfillerCommitLimit,
      'contentAwareHashing': instance.contentAwareHashing.toJson(),
      'ciYaml': instance.ciYaml.toJson(),
      'closeMqGuardAfterPresubmit': instance.closeMqGuardAfterPresubmit,
      'unifiedCheckRunFlow': instance.unifiedCheckRunFlow.toJson(),
      'dynamicTestSuppression': instance.dynamicTestSuppression,
    };
