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
import '../service/config.dart';

/// Public JSON Web Key Set (JWKS) endpoint serving Cocoon's active Ed25519 public keys.
///
/// Used by Pluggable CI partners to verify EdDSA JWT signatures on outbound
/// webhook dispatches and manual status queries from Cocoon (RFC 610.0002).
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
  const GetJwks({required super.config, required CacheService cache})
    : _cache = cache;

  final CacheService _cache;

  static final JsonUtf8Encoder _utf8JsonEncoder = JsonUtf8Encoder();

  @visibleForTesting
  static const String subcacheName = 'jwks';

  @visibleForTesting
  static String cacheKeyForKids(Iterable<String> kids) =>
      'jwks_response:${kids.join(',')}';

  @override
  Map<String, Object?> createErrorBody(String message) => <String, Object?>{
    'message': message,
  };

  @override
  Future<Response> get(Request request) async {
    final kids = <String>{...config.flags.jwksPublicKids}.toList();
    if (kids.isEmpty) {
      return Response.json(
        createErrorBody('No active JWKS public keys configured.'),
        statusCode: HttpStatus.serviceUnavailable,
      );
    }

    // Use a fixed cache key derived only from configured kids (ignoring request
    // query parameters) to prevent unauthenticated cache-busting DoS requests.
    final cacheKey = cacheKeyForKids(kids);

    try {
      var cachedBytes = await _cache.get(subcacheName, cacheKey);
      if (cachedBytes == null) {
        await _cache.tryLock('jwks_lock:$cacheKey', () async {
          cachedBytes = await _cache.get(subcacheName, cacheKey);
          if (cachedBytes != null) {
            return;
          }
          final generated = await _buildJwksBytes(kids);
          await _cache.set(
            subcacheName,
            cacheKey,
            generated,
            ttl: Config.jwksCacheTtl,
          );
          cachedBytes = generated;
        }, const Duration(seconds: 15));

        if (cachedBytes == null) {
          final generated = await _buildJwksBytes(kids);
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
      log.error('Failed to load JWKS public keys', e, s);
      return Response.json(
        createErrorBody('Failed to load JWKS public keys.'),
        statusCode: HttpStatus.internalServerError,
      );
    }
  }

  Future<Uint8List> _buildJwksBytes(List<String> kids) async {
    final keys = <Map<String, Object>>[];
    for (final kid in kids) {
      if (!isValidJwksKeyId(kid)) {
        throw FormatException('Invalid JWKS key ID configured: "$kid".');
      }
      final pem = await config.getJwksPublicKeyPem(kid);
      final jwk = Ed25519PublicJwk.fromPublicKeyPem(pem, expectedKid: kid);
      keys.add(jwk.toJson());
    }
    return _utf8JsonEncoder.convert(<String, Object>{'keys': keys})
        as Uint8List;
  }
}
