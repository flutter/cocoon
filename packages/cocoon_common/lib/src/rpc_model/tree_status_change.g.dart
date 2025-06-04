// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tree_status_change.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TreeStatusChange _$TreeStatusChangeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('TreeStatusChange', json, ($checkedConvert) {
      final val = TreeStatusChange(
        createdOn: $checkedConvert(
          'createdOn',
          (v) => DateTime.parse(v as String),
        ),
        status: $checkedConvert(
          'status',
          (v) => $enumDecode(_$TreeStatusEnumMap, v),
        ),
        authoredBy: $checkedConvert('author', (v) => v as String),
        reason: $checkedConvert('reason', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {'authoredBy': 'author'});

Map<String, dynamic> _$TreeStatusChangeToJson(TreeStatusChange instance) =>
    <String, dynamic>{
      'createdOn': instance.createdOn.toIso8601String(),
      'status': _$TreeStatusEnumMap[instance.status]!,
      'author': instance.authoredBy,
      'reason': instance.reason,
    };

const _$TreeStatusEnumMap = {
  TreeStatus.success: 'success',
  TreeStatus.failure: 'failure',
};
