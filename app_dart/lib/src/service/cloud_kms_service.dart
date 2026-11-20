// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_server/google_auth_provider.dart';
import 'package:googleapis/cloudkms/v1.dart' as kms;
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../model/jwks/ed25519_jwk.dart';

/// Wraps Google Cloud Key Management Service (Cloud KMS) for Ed25519 asymmetric
/// signing keys used by Pluggable CI JWKS and outbound JWT signing.
abstract interface class CloudKmsService {
  /// Cloud KMS algorithm identifier for PureEdDSA on Curve25519.
  static const String ed25519Algorithm = 'EC_SIGN_ED25519';

  /// Cloud KMS CryptoKeyVersion state for active signing keys.
  static const String enabledState = 'ENABLED';

  static final RegExp _cryptoKeyNamePattern = RegExp(
    r'^projects/[A-Za-z0-9_-]+/locations/[A-Za-z0-9_-]+/keyRings/[A-Za-z0-9_-]+/cryptoKeys/[A-Za-z0-9_-]+$',
  );

  static final RegExp _cryptoKeyVersionNamePattern = RegExp(
    r'^projects/[A-Za-z0-9_-]+/locations/[A-Za-z0-9_-]+/keyRings/[A-Za-z0-9_-]+/cryptoKeys/[A-Za-z0-9_-]+/cryptoKeyVersions/[A-Za-z0-9_-]+$',
  );

  /// Returns whether [name] is a valid Cloud KMS CryptoKey resource name:
  /// `projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{cryptoKey}`.
  static bool isValidCryptoKeyName(String name) =>
      _cryptoKeyNamePattern.hasMatch(name);

  /// Returns whether [name] is a valid Cloud KMS CryptoKeyVersion resource name:
  /// `projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{cryptoKey}/cryptoKeyVersions/{version}`.
  static bool isValidCryptoKeyVersionName(String name) =>
      _cryptoKeyVersionNamePattern.hasMatch(name);

  /// Creates a [CloudKmsService] authenticated via [authProvider].
  static Future<CloudKmsService> from(
    GoogleAuthProvider authProvider, {
    http.Client? baseClient,
  }) async {
    final client = await authProvider.createClient(
      scopes: const <String>[kms.CloudKMSApi.cloudkmsScope],
      baseClient: baseClient,
    );
    return CloudKmsService.fromApi(kms.CloudKMSApi(client));
  }

  /// Creates a [CloudKmsService] backed by the provided [api].
  @visibleForTesting
  factory CloudKmsService.fromApi(kms.CloudKMSApi api) = _GoogleCloudKmsService;

  /// Lists all `ENABLED` `EC_SIGN_ED25519` [kms.CryptoKeyVersion] resource names
  /// under [cryptoKeyName].
  Future<List<String>> listEnabledEd25519KeyVersionNames(String cryptoKeyName);

  /// Fetches the SPKI PEM-encoded Ed25519 public key for [keyVersionName].
  Future<String> getPublicKeyPem(String keyVersionName);

  /// Signs raw [data] using PureEdDSA (`EC_SIGN_ED25519`) with [keyVersionName].
  ///
  /// Returns the raw 64-byte Ed25519 signature.
  Future<Uint8List> asymmetricSign(String keyVersionName, Uint8List data);
}

final class _GoogleCloudKmsService implements CloudKmsService {
  const _GoogleCloudKmsService(this._api);

  final kms.CloudKMSApi _api;

  @override
  Future<List<String>> listEnabledEd25519KeyVersionNames(
    String cryptoKeyName,
  ) async {
    if (!CloudKmsService.isValidCryptoKeyName(cryptoKeyName)) {
      throw FormatException(
        'Invalid Cloud KMS CryptoKey resource name: "$cryptoKeyName".',
      );
    }

    final versions = <String>[];
    String? pageToken;
    do {
      final response = await _api
          .projects
          .locations
          .keyRings
          .cryptoKeys
          .cryptoKeyVersions
          .list(
            cryptoKeyName,
            filter:
                'state=${CloudKmsService.enabledState} AND '
                'algorithm=${CloudKmsService.ed25519Algorithm}',
            pageToken: pageToken,
          );
      for (final version
          in response.cryptoKeyVersions ?? const <kms.CryptoKeyVersion>[]) {
        final name = version.name;
        if (name != null &&
            version.state == CloudKmsService.enabledState &&
            version.algorithm == CloudKmsService.ed25519Algorithm) {
          versions.add(name);
        }
      }
      pageToken = response.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);

    return versions;
  }

  @override
  Future<String> getPublicKeyPem(String keyVersionName) async {
    if (!CloudKmsService.isValidCryptoKeyVersionName(keyVersionName)) {
      throw FormatException(
        'Invalid Cloud KMS CryptoKeyVersion resource name: "$keyVersionName".',
      );
    }

    final publicKey = await _api
        .projects
        .locations
        .keyRings
        .cryptoKeys
        .cryptoKeyVersions
        .getPublicKey(keyVersionName);
    if (publicKey.algorithm != CloudKmsService.ed25519Algorithm) {
      throw FormatException(
        'Expected ${CloudKmsService.ed25519Algorithm} key for '
        '"$keyVersionName", got "${publicKey.algorithm}".',
      );
    }
    final pem = publicKey.pem;
    if (pem == null || pem.trim().isEmpty) {
      throw FormatException(
        'Cloud KMS returned an empty public key PEM for "$keyVersionName".',
      );
    }
    return pem;
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

    // PureEdDSA (EC_SIGN_ED25519) signs raw message bytes in `data` (not `digest`).
    final response = await _api
        .projects
        .locations
        .keyRings
        .cryptoKeys
        .cryptoKeyVersions
        .asymmetricSign(
          kms.AsymmetricSignRequest(data: base64Encode(data)),
          keyVersionName,
        );
    final encodedSignature = response.signature;
    if (encodedSignature == null || encodedSignature.isEmpty) {
      throw FormatException(
        'Cloud KMS returned an empty signature for "$keyVersionName".',
      );
    }
    final signature = base64Decode(encodedSignature);
    if (signature.length != kEd25519SignatureLength) {
      throw FormatException(
        'Expected $kEd25519SignatureLength-byte Ed25519 signature from Cloud KMS, '
        'got ${signature.length} bytes.',
      );
    }
    return signature;
  }
}
