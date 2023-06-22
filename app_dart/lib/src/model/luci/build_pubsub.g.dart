// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'build_pubsub.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildV2PubSub _$BuildV2PubSubFromJson(Map<String, dynamic> json) =>
    BuildV2PubSub(
      build: json['build'] == null
          ? null
          : Build.fromJson(json['build'] as Map<String, dynamic>),
      compression:
          $enumDecodeNullable(_$CompressionEnumMap, json['compression']),
    );

Map<String, dynamic> _$BuildV2PubSubToJson(BuildV2PubSub instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('build', instance.build);
  writeNotNull('compression', _$CompressionEnumMap[instance.compression]);
  return val;
}

const _$CompressionEnumMap = {
  Compression.zlib: 'ZLIB',
  Compression.zstd: 'ZSTD',
};

PubSubCallBack _$PubSubCallBackFromJson(Map<String, dynamic> json) =>
    PubSubCallBack(
      buildV2PubSub: json['buildV2PubSub'] == null
          ? null
          : BuildV2PubSub.fromJson(
              json['buildV2PubSub'] as Map<String, dynamic>),
      userData: json['userData'] as String?,
    );

Map<String, dynamic> _$PubSubCallBackToJson(PubSubCallBack instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('buildV2PubSub', instance.buildV2PubSub);
  val['userData'] = instance.userData;
  return val;
}
