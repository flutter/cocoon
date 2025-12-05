// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'firebase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Firebase _$FirebaseFromJson(Map<String, dynamic> json) => Firebase(
  identities: (json['identities'] as Map<String, dynamic>?)?.map(
    (k, e) =>
        MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
  ),
  signInProvider: json['sign_in_provider'] as String?,
  tenant: json['tenant'] as String?,
);

Map<String, dynamic> _$FirebaseToJson(Firebase instance) => <String, dynamic>{
  'identities': instance.identities,
  'sign_in_provider': instance.signInProvider,
  'tenant': instance.tenant,
};
