// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:json_annotation/json_annotation.dart';

part 'service_account_info.g.dart';

/// Class that represents authentication information that enables callers to
/// execute environment-specific tasks on behalf of their apps.
///
/// See also:
///
///  * <https://cloud.google.com/appengine/docs/flexible/python/service-account>
///
///  * `package:googleapis_auth`, which can make use of the service account
///    information to obtain an OAuth 2.0 access token on behalf of the
///    application.
@JsonSerializable()
class ServiceAccountInfo {
  /// Creates a new [ServiceAccountInfo] object.
  const ServiceAccountInfo({
    this.type,
    this.projectId,
    this.privateKeyId,
    this.privateKey,
    this.email,
    this.clientId,
    this.authUrl,
    this.tokenUrl,
    this.authCertUrl,
    this.clientCertUrl,
  });

  /// Create a new [ServiceAccountInfo] object from its JSON representation.
  factory ServiceAccountInfo.fromJson(Map<String, dynamic> json) =>
      _$ServiceAccountInfoFromJson(json);

  @JsonKey(name: 'type')
  final String? type;

  @JsonKey(name: 'project_id')
  final String? projectId;

  @JsonKey(name: 'private_key_id')
  final String? privateKeyId;

  @JsonKey(name: 'private_key')
  final String? privateKey;

  @JsonKey(name: 'client_email')
  final String? email;

  @JsonKey(name: 'client_id')
  final String? clientId;

  @JsonKey(name: 'auth_uri')
  final String? authUrl;

  @JsonKey(name: 'token_uri')
  final String? tokenUrl;

  @JsonKey(name: 'auth_provider_x509_cert_url')
  final String? authCertUrl;

  @JsonKey(name: 'client_x509_cert_url')
  final String? clientCertUrl;

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$ServiceAccountInfoToJson(this);

  /// Returns this object in its [ServiceAccountCredentials] form.
  ServiceAccountCredentials asServiceAccountCredentials() {
    return ServiceAccountCredentials(
      email!,
      ClientId(clientId!, null),
      privateKey!,
    );
  }
}
