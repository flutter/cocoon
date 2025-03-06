// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'grpc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GrpcStatus _$GrpcStatusFromJson(Map<String, dynamic> json) => GrpcStatus(
  code: json['code'] as int,
  message: json['message'] as String?,
  details: json['details'],
);

Map<String, dynamic> _$GrpcStatusToJson(GrpcStatus instance) {
  final val = <String, dynamic>{'code': instance.code};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  writeNotNull('details', instance.details);
  return val;
}
