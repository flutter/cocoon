// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suppressed_test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuppressedTest _$SuppressedTestFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SuppressedTest', json, ($checkedConvert) {
      final val = SuppressedTest(
        name: $checkedConvert('name', (v) => v as String),
        repository: $checkedConvert('repository', (v) => v as String),
        issueLink: $checkedConvert('issueLink', (v) => v as String),
        createTimestamp: $checkedConvert(
          'createTimestamp',
          (v) => (v as num).toInt(),
        ),
        updates: $checkedConvert(
          'updates',
          (v) =>
              (v as List<dynamic>?)
                  ?.map(
                    (e) =>
                        SuppressionUpdate.fromJson(e as Map<String, dynamic>),
                  )
                  .toList() ??
              [],
        ),
      );
      return val;
    });

Map<String, dynamic> _$SuppressedTestToJson(SuppressedTest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'repository': instance.repository,
      'issueLink': instance.issueLink,
      'createTimestamp': instance.createTimestamp,
      'updates': instance.updates,
    };

SuppressionUpdate _$SuppressionUpdateFromJson(Map<String, dynamic> json) =>
    $checkedCreate('SuppressionUpdate', json, ($checkedConvert) {
      final val = SuppressionUpdate(
        user: $checkedConvert('user', (v) => v as String),
        action: $checkedConvert('action', (v) => v as String),
        updateTimestamp: $checkedConvert(
          'updateTimestamp',
          (v) => (v as num).toInt(),
        ),
        note: $checkedConvert('note', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$SuppressionUpdateToJson(SuppressionUpdate instance) =>
    <String, dynamic>{
      'user': instance.user,
      'action': instance.action,
      'updateTimestamp': instance.updateTimestamp,
      'note': instance.note,
    };
