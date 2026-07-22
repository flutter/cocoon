// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'ordered_presubmit_flags.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderedPresubmit _$OrderedPresubmitFromJson(Map<String, dynamic> json) =>
    OrderedPresubmit(
      useForAll: json['useForAll'] as bool?,
      useForUsers: (json['useForUsers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$OrderedPresubmitToJson(OrderedPresubmit instance) =>
    <String, dynamic>{
      'useForAll': instance.useForAll,
      'useForUsers': instance.useForUsers,
    };
