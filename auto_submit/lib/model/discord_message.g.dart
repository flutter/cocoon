// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discord_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      content: json['content'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'content': instance.content,
      'username': instance.username,
      if (instance.avatarUrl case final value?) 'avatar_url': value,
    };
