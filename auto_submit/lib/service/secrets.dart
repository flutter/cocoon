// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:appengine/appengine.dart';
import 'package:auto_submit/service/config.dart';
import 'package:googleapis/secretmanager/v1.dart';

/// Access secrets for Google Cloud projects.
///
/// See also:
///   * https://cloud.google.com/secret-manager/docs
abstract class SecretManager {
  const SecretManager();

  Future<String> get(String key);

  void put(String key, [String? value]);
}

class CloudSecretManager implements SecretManager {
  CloudSecretManager();

  final String projectId = Platform.environment['APPLICATION_ID'] ?? Config.flutterGcpProjectId;

  @override
  Future<String> get(
    String key, {
    String? fields,
  }) async {
    final SecretManagerApi api = SecretManagerApi(authClientService);
    final SecretPayload? payload = (await api.projects.secrets.versions.access(
      'projects/$projectId/secrets/$key/versions/latest',
      $fields: fields,
    ))
        .payload;
    if (payload?.data == null) {
      throw SecretManagerException('Failed to find secret for $key with \$fields=$fields');
    }
    return String.fromCharCodes(base64Decode(payload!.data!));
  }

  @override
  void put(String key, [String? value]) => throw UnimplementedError('put is only supported for local runs');
}

/// Local instance of [SecretManager] for use in testing.
class LocalSecretManager implements SecretManager {
  final Map<String, String?> _secrets = <String, String>{};

  @override
  Future<String> get(String key, {String? fields}) async {
    if (_secrets.containsKey(key)) {
      return _secrets[key]!;
    } else if (Platform.environment.containsKey(key)) {
      return Platform.environment[key]!;
    }

    throw Exception('Failed to find $key in environment. Try adding it to the environment variables');
  }

  @override
  void put(String key, [String? value]) {
    _secrets[key] = value;
  }
}

class SecretManagerException implements Exception {
  SecretManagerException([this.message]);

  final String? message;

  @override
  String toString() => 'SecretManagerException: $message';
}
