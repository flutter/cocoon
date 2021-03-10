// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'commit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Commit _$CommitFromJson(Map<String, dynamic> json) {
  return Commit(
    timestamp: json['timestamp'] as int,
    sha: json['sha'] as String,
    author: json['author'] as String,
    authorAvatarUrl: json['authorAvatarUrl'] as String,
    message: json['message'] as String,
    repository: json['repository'] as String,
    branch: json['branch'] as String,
  );
}

Map<String, dynamic> _$CommitToJson(Commit instance) => <String, dynamic>{
      'timestamp': instance.timestamp,
      'sha': instance.sha,
      'author': instance.author,
      'authorAvatarUrl': instance.authorAvatarUrl,
      'message': instance.message,
      'repository': instance.repository,
      'branch': instance.branch,
    };
