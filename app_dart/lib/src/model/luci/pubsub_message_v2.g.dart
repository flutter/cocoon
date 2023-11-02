// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'pubsub_message_v2.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushMessageV2 _$PushMessageV2FromJson(Map<String, dynamic> json) =>
    PushMessageV2(
      message: json['message'] == null
          ? null
          : PubSubMessageV2.fromJson(json['message'] as Map<String, dynamic>),
      subscription: json['subscription'] as String?,
    );

Map<String, dynamic> _$PushMessageV2ToJson(PushMessageV2 instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  writeNotNull('subscription', instance.subscription);
  return val;
}

PubSubMessageV2 _$PubSubMessageV2FromJson(Map<String, dynamic> json) =>
    PubSubMessageV2(
      attributes: (json['attributes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      data: json['data'] as String?,
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
  writeNotNull('data', instance.data);
  writeNotNull('messageId', instance.messageId);
  writeNotNull('publishTime', instance.publishTime);
  return val;
}
