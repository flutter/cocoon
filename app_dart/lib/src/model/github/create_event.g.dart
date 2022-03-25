// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'create_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateEvent _$CreateEventFromJson(Map<String, dynamic> json) => CreateEvent(
      ref: json['ref'] as String?,
      refType: json['ref_type'] as String?,
      pusherType: json['pusher_type'] as String?,
      repository: json['repository'] == null ? null : Repository.fromJson(json['repository'] as Map<String, dynamic>),
      sender: json['sender'] == null ? null : User.fromJson(json['sender'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateEventToJson(CreateEvent instance) => <String, dynamic>{
      'ref': instance.ref,
      'ref_type': instance.refType,
      'pusher_type': instance.pusherType,
      'repository': instance.repository,
      'sender': instance.sender,
    };
