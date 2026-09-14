// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'check_suite_flow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckSuiteFlow _$CheckSuiteFlowFromJson(Map<String, dynamic> json) =>
    CheckSuiteFlow(
      useForAll: json['useForAll'] as bool?,
      useForUsers: (json['useForUsers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$CheckSuiteFlowToJson(CheckSuiteFlow instance) =>
    <String, dynamic>{
      'useForAll': instance.useForAll,
      'useForUsers': instance.useForUsers,
    };
