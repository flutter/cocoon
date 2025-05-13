// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DynamicConfig _$DynamicConfigFromJson(Map<String, dynamic> json) =>
    DynamicConfig(
      backfillerCommitLimit:
          (json['backfillerCommitLimit'] as num?)?.toInt() ?? 50,
      contentAwareHashing: ContentAwareHashingJson.fromJson(
        json['contentAwareHashing'] as Map<String, dynamic>?,
      ),
    );

Map<String, dynamic> _$DynamicConfigToJson(DynamicConfig instance) =>
    <String, dynamic>{
      'backfillerCommitLimit': instance.backfillerCommitLimit,
      'contentAwareHashing': instance.contentAwareHashing.toJson(),
    };
