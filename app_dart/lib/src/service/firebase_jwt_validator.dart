// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:http/http.dart' show Client;
import 'package:jose_plus/jose.dart';
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/google/token_info.dart';

/// Handles fully validating a Firebase JWT (json web token).
///
/// This class validates a JWT was signed correctly by maintaining a
/// [JsonWebKeyStore] with the up to date public signing keys from Firestore.
/// It then verifies the claims as required by
/// https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library
interface class FirebaseJwtValidator {
  FirebaseJwtValidator({
    required CacheService cache,
    @visibleForTesting DateTime Function() now = DateTime.now,
    @visibleForTesting Client? client,
  }) : _cache = cache,
       _client = client ?? Client(),
       _now = now;

  final Client _client;
  final DateTime Function() _now;
  final CacheService _cache;

  /// This keystore will be replaced when [maybeRefreshKeyStore] downloads
  /// on cache invalidation.
  var _keyStore = JsonWebKeyStore();

  @visibleForTesting
  JsonWebKeyStore get keyStore => _keyStore;

  static final firebasePEMKeysUri = Uri.parse(
    'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com',
  );

  static const issuer = 'https://securetoken.google.com/flutter-dashboard';

  /// Decode and verify that [jwtString] is from Firebase and for our project.
  Future<TokenInfo> decodeAndVerify(String jwtString) async {
    final now = _now();

    // Maybe fetch the PEM keys.
    await maybeRefreshKeyStore();

    // This will throw if the JWT wasn't signed correctly.
    final jwt = await JsonWebToken.decodeAndVerify(jwtString, _keyStore);
    verifyJwtClaims(jwt.claims, now);
    return TokenInfo.fromJson(jwt.claims.toJson());
  }

  @visibleForTesting
  static void verifyJwtClaims(JsonWebTokenClaims claims, DateTime now) {
    // Now we need to validate the JWT according to https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library
    if (claims.expiry?.isBefore(now) ?? true) {
      throw JwtException('JWT expired');
    }
    if (claims.issuedAt?.isAfter(now) ?? true) {
      throw JwtException('JWT issued in the future');
    }
    if (claims.getTyped<DateTime>('auth_time')?.isAfter(now) ?? true) {
      throw JwtException('JWT auth_time in the future');
    }
    if (claims.audience != null &&
        !claims.audience!.contains('flutter-dashboard')) {
      throw JwtException('JWT aud does not include flutter-dashboard');
    }
    if ('${claims.issuer}' != issuer) {
      throw JwtException('JWT iss not from $issuer');
    }
    if (claims.subject?.isEmpty ?? true) {
      throw JwtException('JWT subject is empty string');
    }
  }

  @visibleForTesting
  Future<void> maybeRefreshKeyStore() async {
    final bytes = await _cache.getOrCreateWithLocking(
      'firebase_jwt_keys',
      'firebase_jwt_keys',
      createFn: _downloadPEMs,
      // It is unlikely the PEM keys are going to rotate.
      ttl: const Duration(minutes: 15),
    );
    final pems = json.decode(utf8.decode(bytes!)) as Map<String, Object?>;
    _keyStore = JsonWebKeyStore();
    for (final MapEntry(:key, :value) in pems.entries) {
      _keyStore.addKey(JsonWebKey.fromPem(value as String, keyId: key));
    }
  }

  /// Attempts to download PEMs from Firebase and return that json array as bytes.
  ///
  /// The side effect of this running is the [_keyStore] is refreshed with the
  /// new keys.
  Future<Uint8List> _downloadPEMs() async {
    final response = await _client.get(
      Uri.parse(
        'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com',
      ),
    );
    if (response.statusCode != 200) {
      log.warn(
        'error downloading Firebase PEM keys: code=${response.statusCode} body=${response.body}',
      );
      throw StateError('error downloading Firebase PEM keys');
    }

    final bytes = response.bodyBytes;
    return bytes;
  }
}

class JwtException implements Exception {
  final String message;
  JwtException(this.message);

  @override
  String toString() {
    return '$JwtException: $message';
  }
}
