// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'grpc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GrpcStatus _$GrpcStatusFromJson(Map<String, dynamic> json) => GrpcStatus(
  code: (json['code'] as num).toInt(),
  message: json['message'] as String?,
  details: json['details'],
);

Map<String, dynamic> _$GrpcStatusToJson(GrpcStatus instance) =>
    <String, dynamic>{
      'code': instance.code,
      if (instance.message case final value?) 'message': value,
      if (instance.details case final value?) 'details': value,
    };
