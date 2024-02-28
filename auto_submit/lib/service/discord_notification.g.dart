// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discord_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      json['content'] as String?,
      json['username'] as String?,
      json['avatar_url'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'content': instance.content,
      'username': instance.username,
      'avatar_url': instance.avatarUrl,
    };
