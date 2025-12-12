// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'firebase_jwt_claim.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FirebaseJwtClaim _$FirebaseJwtClaimFromJson(Map<String, dynamic> json) =>
    FirebaseJwtClaim(
      identities: (json['identities'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      signInProvider: json['sign_in_provider'] as String?,
      tenant: json['tenant'] as String?,
    );

Map<String, dynamic> _$FirebaseJwtClaimToJson(FirebaseJwtClaim instance) =>
    <String, dynamic>{
      'identities': instance.identities,
      'sign_in_provider': instance.signInProvider,
      'tenant': instance.tenant,
    };
