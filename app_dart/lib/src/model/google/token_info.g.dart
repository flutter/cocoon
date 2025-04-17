// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'token_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenInfo _$TokenInfoFromJson(Map<String, dynamic> json) => TokenInfo(
  issuer: json['iss'] as String?,
  authorizedParty: json['azp'] as String?,
  audience: json['aud'] as String?,
  subject: json['sub'] as String?,
  hostedDomain: json['hd'] as String?,
  email: json['email'] as String?,
  emailIsVerified: const BoolConverter().fromJson(json['email_verified']),
  accessTokenHash: json['at_hash'] as String?,
  fullName: json['name'] as String?,
  profilePictureUrl: json['picture'] as String?,
  givenName: json['given_name'] as String?,
  familyName: json['family_name'] as String?,
  locale: json['locale'] as String?,
  issued: const SecondsSinceEpochConverter().fromJson(json['iat']),
  expiration: const SecondsSinceEpochConverter().fromJson(json['exp']),
  jwtId: json['jti'] as String?,
  algorithm: json['alg'] as String?,
  keyId: json['kid'] as String?,
  encoding: json['typ'] as String?,
);

Map<String, dynamic> _$TokenInfoToJson(TokenInfo instance) => <String, dynamic>{
  'iss': instance.issuer,
  'azp': instance.authorizedParty,
  'aud': instance.audience,
  'sub': instance.subject,
  'hd': instance.hostedDomain,
  'email': instance.email,
  'email_verified': const BoolConverter().toJson(instance.emailIsVerified),
  'at_hash': instance.accessTokenHash,
  'name': instance.fullName,
  'picture': instance.profilePictureUrl,
  'given_name': instance.givenName,
  'family_name': instance.familyName,
  'locale': instance.locale,
  'iat': const SecondsSinceEpochConverter().toJson(instance.issued),
  'exp': const SecondsSinceEpochConverter().toJson(instance.expiration),
  'jti': instance.jwtId,
  'alg': instance.algorithm,
  'kid': instance.keyId,
  'typ': instance.encoding,
};
