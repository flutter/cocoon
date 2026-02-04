// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'pubsub_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PubSubPushMessage _$PubSubPushMessageFromJson(Map<String, dynamic> json) =>
    PubSubPushMessage(
      message: json['message'] == null
          ? null
          : PushMessage.fromJson(json['message'] as Map<String, dynamic>),
      subscription: json['subscription'] as String?,
    );

Map<String, dynamic> _$PubSubPushMessageToJson(PubSubPushMessage instance) =>
    <String, dynamic>{
      'message': ?instance.message,
      'subscription': ?instance.subscription,
    };

PushMessage _$PushMessageFromJson(Map<String, dynamic> json) => PushMessage(
  attributes: (json['attributes'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  data: _$JsonConverterFromJson<String, String>(
    json['data'],
    const Base64Converter().fromJson,
  ),
  messageId: json['messageId'] as String?,
  publishTime: json['publishTime'] as String?,
);

Map<String, dynamic> _$PushMessageToJson(PushMessage instance) =>
    <String, dynamic>{
      'attributes': ?instance.attributes,
      'data': ?_$JsonConverterToJson<String, String>(
        instance.data,
        const Base64Converter().toJson,
      ),
      'messageId': ?instance.messageId,
      'publishTime': ?instance.publishTime,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
