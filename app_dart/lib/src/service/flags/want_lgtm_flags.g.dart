// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'want_lgtm_flags.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WantLgtmFlags _$WantLgtmFlagsFromJson(Map<String, dynamic> json) =>
    WantLgtmFlags(
      enabled: json['enabled'] as bool?,
      useForAllRepos: json['useForAllRepos'] as bool?,
      enabledRepos: (json['enabledRepos'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$WantLgtmFlagsToJson(WantLgtmFlags instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'useForAllRepos': instance.useForAllRepos,
      'enabledRepos': instance.enabledRepos,
    };
