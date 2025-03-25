// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'dart:typed_data';

import 'package:googleapis/secretmanager/v1.dart' as gapis;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

import 'access_client_provider.dart';

/// Wraps Google Cloud [Secret Manager](https://cloud.google.com/security/products/secret-manager).
abstract base class SecretManager {
  /// Returns a [SecretManager] using the access client [provided] provided.
  static Future<SecretManager> create(
    AccessClientProvider provider, {
    String? projectId,
    Iterable<String>? scopes,
    http.Client? baseClient,
  }) async {
    scopes ??= const [gapis.SecretManagerApi.cloudPlatformScope];
    projectId ??= io.Platform.environment['APPLICATION_ID'];
    if (projectId == null) {
      throw StateError('Missing APPLICATION_ID and projectId not set');
    }

    final client = await provider.createAccessClient(
      scopes: [...scopes],
      baseClient: baseClient,
    );
    return SecretManager.fromGoogleCloud(
      gapis.SecretManagerApi(client),
      projectId: projectId,
    );
  }

  /// Creates a [SecretManager] that wraps the provided [gapis.SecretManagerApi].
  @visibleForTesting
  factory SecretManager.fromGoogleCloud(
    gapis.SecretManagerApi api, {
    required String projectId,
  }) = _CloudSecretManager;

  const SecretManager();

  /// Returns the latest secret with the provided [name] as bytes.
  Future<Uint8List> getBytes(String name) async {
    final bytes = await tryGetBytes(name);
    if (bytes == null) {
      throw SecretException(name);
    }
    return bytes;
  }

  /// Returns the latest secret with the provided [name] as bytes.
  ///
  /// If the secret could not be found, `null` is returned.
  Future<Uint8List?> tryGetBytes(String name);

  /// Returns the latest secret with the provided [name] as a UTF-16 string.
  Future<String> getString(String name) async {
    final string = await tryGetString(name);
    if (string == null) {
      throw SecretException(name);
    }
    return string;
  }

  /// Returns the latest secret with the provided [name] as a UTF-16 string.
  ///
  /// If the secret could not be found, `null` is returned.
  Future<String?> tryGetString(String name) async {
    final bytes = await tryGetBytes(name);
    if (bytes == null) {
      return null;
    }
    return String.fromCharCodes(bytes);
  }
}

final class SecretException implements Exception {
  SecretException(this.name);

  /// Name that failed to be fetched.
  final String name;

  @override
  String toString() {
    return 'Failed to fetch secret "$name"';
  }
}

final class _CloudSecretManager extends SecretManager {
  const _CloudSecretManager(this._api, {required String projectId})
    : _projectId = projectId;

  final gapis.SecretManagerApi _api;
  final String _projectId;

  @override
  Future<Uint8List?> tryGetBytes(String name) async {
    final result = await _api.projects.secrets.versions.access(
      p.posix.join(
        'projects',
        _projectId,
        'secrets',
        name,
        'versions',
        'latest',
      ),
    );
    return switch (result.payload?.dataAsBytes) {
      null => null,
      final Uint8List bytes => bytes,
      final bytes => Uint8List.fromList(bytes),
    };
  }
}
