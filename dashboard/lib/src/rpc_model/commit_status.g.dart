// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commit_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommitStatus _$CommitStatusFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CommitStatus', json, ($checkedConvert) {
      final val = CommitStatus(
        commit: $checkedConvert(
          'Commit',
          (v) => Commit.fromJson(v as Map<String, dynamic>),
        ),
        tasks: $checkedConvert(
          'Tasks',
          (v) => (v as List<dynamic>).map(
            (e) => Task.fromJson(e as Map<String, dynamic>),
          ),
        ),
      );
      return val;
    }, fieldKeyMap: const {'commit': 'Commit', 'tasks': 'Tasks'});

Map<String, dynamic> _$CommitStatusToJson(CommitStatus instance) =>
    <String, dynamic>{'Commit': instance.commit, 'Tasks': instance.tasks};
