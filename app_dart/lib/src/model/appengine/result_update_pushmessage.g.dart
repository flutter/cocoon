// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'result_update_pushmessage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResultUpdatePushMessage _$ResultUpdatePushMessageFromJson(
        Map<String, dynamic> json) =>
    ResultUpdatePushMessage(
      sha: json['sha'] as String,
      branch: json['branch'] as String,
      slug: RepositorySlug.fromJson(json['slug'] as Map<String, dynamic>),
      name: json['name'] as String,
      result: json['result'] as String,
      started: json['started'] == null
          ? null
          : DateTime.parse(json['started'] as String),
      finished: json['finished'] == null
          ? null
          : DateTime.parse(json['finished'] as String),
    );

Map<String, dynamic> _$ResultUpdatePushMessageToJson(
    ResultUpdatePushMessage instance) {
  final val = <String, dynamic>{
    'sha': instance.sha,
    'branch': instance.branch,
    'slug': instance.slug,
    'name': instance.name,
    'result': instance.result,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('started', instance.started?.toIso8601String());
  writeNotNull('finished', instance.finished?.toIso8601String());
  return val;
}
