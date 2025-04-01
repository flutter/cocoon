// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Commit _$CommitFromJson(Map<String, dynamic> json) => $checkedCreate(
      'Commit',
      json,
      ($checkedConvert) {
        final val = Commit(
          timestamp:
              $checkedConvert('CreateTimestamp', (v) => (v as num).toInt()),
          sha: $checkedConvert('Sha', (v) => v as String),
          author: $checkedConvert('Author',
              (v) => CommitAuthor.fromJson(v as Map<String, dynamic>)),
          message: $checkedConvert('Message', (v) => v as String),
          repository:
              $checkedConvert('FlutterRepositoryPath', (v) => v as String),
          branch: $checkedConvert('Branch', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'timestamp': 'CreateTimestamp',
        'sha': 'Sha',
        'author': 'Author',
        'message': 'Message',
        'repository': 'FlutterRepositoryPath',
        'branch': 'Branch'
      },
    );

Map<String, dynamic> _$CommitToJson(Commit instance) => <String, dynamic>{
      'CreateTimestamp': instance.timestamp,
      'Sha': instance.sha,
      'Author': instance.author,
      'Message': instance.message,
      'FlutterRepositoryPath': instance.repository,
      'Branch': instance.branch,
    };

CommitAuthor _$CommitAuthorFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'CommitAuthor',
      json,
      ($checkedConvert) {
        final val = CommitAuthor(
          login: $checkedConvert('Login', (v) => v as String),
          avatarUrl: $checkedConvert('avatar_url', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {'login': 'Login', 'avatarUrl': 'avatar_url'},
    );

Map<String, dynamic> _$CommitAuthorToJson(CommitAuthor instance) =>
    <String, dynamic>{
      'Login': instance.login,
      'avatar_url': instance.avatarUrl,
    };
