// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'pubsub_message_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PubSubMessageV2 _$PubSubMessageV2FromJson(Map<String, dynamic> json) => PubSubMessageV2(
      attributes: (json['attributes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      data: _$JsonConverterFromJson<String, String>(json['data'], const Base64Converter().fromJson),
      messageId: json['messageId'] as String?,
      publishTime: json['publishTime'] as String?,
    );

Map<String, dynamic> _$PubSubMessageV2ToJson(PubSubMessageV2 instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('attributes', instance.attributes);
  writeNotNull('data', _$JsonConverterToJson<String, String>(instance.data, const Base64Converter().toJson));
  writeNotNull('messageId', instance.messageId);
  writeNotNull('publishTime', instance.publishTime);
  return val;
}

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);
