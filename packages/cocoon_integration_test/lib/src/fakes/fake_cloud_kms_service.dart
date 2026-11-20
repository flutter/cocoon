// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:cocoon_service/cocoon_service.dart';

/// In-memory fake implementation of [CloudKmsService] for tests and local dev.
final class FakeCloudKmsService implements CloudKmsService {
  FakeCloudKmsService({
    Map<String, FakeKmsKeyVersion>? versions,
    this.signHandler,
  }) : _versions = <String, FakeKmsKeyVersion>{...?versions};

  final Map<String, FakeKmsKeyVersion> _versions;

  /// Optional custom signing callback for [asymmetricSign].
  Future<Uint8List> Function(String keyVersionName, Uint8List data)?
  signHandler;

  /// Optional exception thrown by [listEnabledEd25519KeyVersionNames].
  Object? listError;

  /// Optional exception thrown by [getPublicKeyPem].
  Object? getPublicKeyError;

  /// Registers or updates a KMS key version [versionName] with [pem].
  void putKeyVersion(
    String versionName, {
    required String pem,
    String state = CloudKmsService.enabledState,
    String algorithm = CloudKmsService.ed25519Algorithm,
  }) {
    _versions[versionName] = FakeKmsKeyVersion(
      pem: pem,
      state: state,
      algorithm: algorithm,
    );
  }

  /// Removes a registered KMS key version [versionName].
  void removeKeyVersion(String versionName) {
    _versions.remove(versionName);
  }

  /// Removes all registered KMS key versions.
  void clear() => _versions.clear();

  @override
  Future<List<String>> listEnabledEd25519KeyVersionNames(
    String cryptoKeyName,
  ) async {
    if (!CloudKmsService.isValidCryptoKeyName(cryptoKeyName)) {
      throw FormatException(
        'Invalid Cloud KMS CryptoKey resource name: "$cryptoKeyName".',
      );
    }
    if (listError != null) {
      throw listError!;
    }
    final prefix = '$cryptoKeyName/cryptoKeyVersions/';
    return <String>[
      for (final entry in _versions.entries)
        if (entry.key.startsWith(prefix) &&
            entry.value.state == CloudKmsService.enabledState &&
            entry.value.algorithm == CloudKmsService.ed25519Algorithm)
          entry.key,
    ];
  }

  @override
  Future<String> getPublicKeyPem(String keyVersionName) async {
    if (!CloudKmsService.isValidCryptoKeyVersionName(keyVersionName)) {
      throw FormatException(
        'Invalid Cloud KMS CryptoKeyVersion resource name: "$keyVersionName".',
      );
    }
    if (getPublicKeyError != null) {
      throw getPublicKeyError!;
    }
    final version = _versions[keyVersionName];
    if (version == null) {
      throw StateError('KMS key version not found: "$keyVersionName".');
    }
    if (version.algorithm != CloudKmsService.ed25519Algorithm) {
      throw FormatException(
        'Expected ${CloudKmsService.ed25519Algorithm} key for '
        '"$keyVersionName", got "${version.algorithm}".',
      );
    }
    return version.pem;
  }

  @override
  Future<Uint8List> asymmetricSign(
    String keyVersionName,
    Uint8List data,
  ) async {
    if (!CloudKmsService.isValidCryptoKeyVersionName(keyVersionName)) {
      throw FormatException(
        'Invalid Cloud KMS CryptoKeyVersion resource name: "$keyVersionName".',
      );
    }
    if (signHandler != null) {
      return signHandler!(keyVersionName, data);
    }
    if (!_versions.containsKey(keyVersionName)) {
      throw StateError('KMS key version not found: "$keyVersionName".');
    }
    return Uint8List(kEd25519SignatureLength);
  }
}

final class FakeKmsKeyVersion {
  const FakeKmsKeyVersion({
    required this.pem,
    this.state = CloudKmsService.enabledState,
    this.algorithm = CloudKmsService.ed25519Algorithm,
  });

  final String pem;
  final String state;
  final String algorithm;
}
