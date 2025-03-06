// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'branch_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReleaseBranch _$ReleaseBranchFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ReleaseBranch', json, ($checkedConvert) {
      final val = ReleaseBranch(
        channel: $checkedConvert('channel', (v) => v as String),
        reference: $checkedConvert('reference', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$ReleaseBranchToJson(ReleaseBranch instance) =>
    <String, dynamic>{
      'channel': instance.channel,
      'reference': instance.reference,
    };
