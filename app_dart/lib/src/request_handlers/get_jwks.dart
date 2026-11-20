// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_server/logging.dart';
import 'package:meta/meta.dart';

import '../model/jwks/ed25519_jwk.dart';
import '../request_handling/http_utils.dart';
import '../request_handling/public_api_request_handler.dart';
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';
import '../service/cache_service.dart';
import '../service/cloud_kms_service.dart';
import '../service/config.dart';

/// Public JSON Web Key Set (JWKS) endpoint serving Cocoon's active Ed25519 public keys.
///
/// Keys are retrieved from Google Cloud KMS (`ENABLED` `EC_SIGN_ED25519`
/// versions of the configured CryptoKey) and used by Pluggable CI partners to
/// verify EdDSA JWT signatures on outbound webhook dispatches and manual status
/// queries from Cocoon (RFC 610.0002).
///
/// GET: `/api/v1/jwks`
///
/// Response (`200 OK`):
/// ```json
/// {
///   "keys": [
///     {
///       "kty": "OKP",
///       "crv": "Ed25519",
///       "use": "sig",
///       "alg": "EdDSA",
///       "kid": "<RFC 7638 JWK Thumbprint>",
///       "x": "<Base64url-encoded Ed25519 public key>"
///     }
///   ]
/// }
/// ```
final class GetJwks extends PublicApiRequestHandler {
  const GetJwks({
    required super.config,
    required CacheService cache,
    required CloudKmsService cloudKms,
  }) : _cache = cache,
       _cloudKms = cloudKms;

  final CacheService _cache;
  final CloudKmsService _cloudKms;

  static final JsonUtf8Encoder _utf8JsonEncoder = JsonUtf8Encoder();

  @visibleForTesting
  static const String subcacheName = 'jwks';

  @visibleForTesting
  static String cacheKeyForCryptoKey(String cryptoKeyName) =>
      'jwks_response:$cryptoKeyName';

  @override
  Map<String, Object?> createErrorBody(String message) => <String, Object?>{
    'message': message,
  };

  @override
  Future<Response> get(Request request) async {
    final cryptoKeyName = config.flags.jwksKmsKeyName?.trim();
    if (cryptoKeyName == null || cryptoKeyName.isEmpty) {
      return Response.json(
        createErrorBody('No active JWKS public keys configured.'),
        statusCode: HttpStatus.serviceUnavailable,
      );
    }

    // Use a fixed cache key derived only from the configured KMS CryptoKey
    // (ignoring request query parameters) to prevent cache-busting DoS attacks.
    final cacheKey = cacheKeyForCryptoKey(cryptoKeyName);

    try {
      var cachedBytes = await _cache.get(subcacheName, cacheKey);
      var noEnabledKeys = false;
      if (cachedBytes == null) {
        await _cache.tryLock('jwks_lock:$cacheKey', () async {
          cachedBytes = await _cache.get(subcacheName, cacheKey);
          if (cachedBytes != null) {
            return;
          }
          final generated = await _buildJwksBytes(cryptoKeyName);
          if (generated == null) {
            noEnabledKeys = true;
            return;
          }
          await _cache.set(
            subcacheName,
            cacheKey,
            generated,
            ttl: Config.jwksCacheTtl,
          );
          cachedBytes = generated;
        }, const Duration(seconds: 15));

        if (noEnabledKeys) {
          return Response.json(
            createErrorBody('No active JWKS public keys configured.'),
            statusCode: HttpStatus.serviceUnavailable,
          );
        }

        if (cachedBytes == null) {
          final generated = await _buildJwksBytes(cryptoKeyName);
          if (generated == null) {
            return Response.json(
              createErrorBody('No active JWKS public keys configured.'),
              statusCode: HttpStatus.serviceUnavailable,
            );
          }
          await _cache.set(
            subcacheName,
            cacheKey,
            generated,
            ttl: Config.jwksCacheTtl,
          );
          cachedBytes = generated;
        }
      }

      return Response.stream(
        Stream<Uint8List>.value(cachedBytes!),
        contentType: kContentTypeJson,
      );
    } catch (e, s) {
      log.error('Failed to load JWKS public keys from Cloud KMS', e, s);
      return Response.json(
        createErrorBody('Failed to load JWKS public keys.'),
        statusCode: HttpStatus.internalServerError,
      );
    }
  }

  /// Builds UTF-8 encoded JWKS JSON bytes from all `ENABLED` Ed25519 key
  /// versions in Cloud KMS, or returns `null` if no enabled versions exist.
  Future<Uint8List?> _buildJwksBytes(String cryptoKeyName) async {
    if (!CloudKmsService.isValidCryptoKeyName(cryptoKeyName)) {
      throw FormatException(
        'Invalid Cloud KMS CryptoKey resource name: "$cryptoKeyName".',
      );
    }
    final versionNames = await _cloudKms.listEnabledEd25519KeyVersionNames(
      cryptoKeyName,
    );
    if (versionNames.isEmpty) {
      return null;
    }

    final pems = await Future.wait(versionNames.map(_cloudKms.getPublicKeyPem));
    final seenKids = <String>{};
    final keys = <Map<String, Object>>[];
    for (final pem in pems) {
      final jwk = Ed25519PublicJwk.fromPublicKeyPem(pem);
      if (seenKids.add(jwk.kid)) {
        keys.add(jwk.toJson());
      }
    }
    return _utf8JsonEncoder.convert(<String, Object>{'keys': keys})
        as Uint8List;
  }
}
