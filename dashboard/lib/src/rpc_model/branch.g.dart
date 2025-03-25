// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'branch.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Branch _$BranchFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Branch',
      json,
      ($checkedConvert) {
        final val = Branch(
          channel: $checkedConvert('channel', (v) => v as String),
          reference: $checkedConvert('reference', (v) => v as String),
        );
        return val;
      },
    );

Map<String, dynamic> _$BranchToJson(Branch instance) => <String, dynamic>{
      'channel': instance.channel,
      'reference': instance.reference,
    };
