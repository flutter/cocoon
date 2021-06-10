// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, implicit_dynamic_parameter

part of 'service_account_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceAccountInfo _$ServiceAccountInfoFromJson(Map<String, dynamic> json) => ServiceAccountInfo(
      type: json['type'] as String?,
      projectId: json['project_id'] as String?,
      privateKeyId: json['private_key_id'] as String?,
      privateKey: json['private_key'] as String?,
      email: json['client_email'] as String?,
      clientId: json['client_id'] as String?,
      authUrl: json['auth_uri'] as String?,
      tokenUrl: json['token_uri'] as String?,
      authCertUrl: json['auth_provider_x509_cert_url'] as String?,
      clientCertUrl: json['client_x509_cert_url'] as String?,
    );

Map<String, dynamic> _$ServiceAccountInfoToJson(ServiceAccountInfo instance) => <String, dynamic>{
      'type': instance.type,
      'project_id': instance.projectId,
      'private_key_id': instance.privateKeyId,
      'private_key': instance.privateKey,
      'client_email': instance.email,
      'client_id': instance.clientId,
      'auth_uri': instance.authUrl,
      'token_uri': instance.tokenUrl,
      'auth_provider_x509_cert_url': instance.authCertUrl,
      'client_x509_cert_url': instance.clientCertUrl,
    };
