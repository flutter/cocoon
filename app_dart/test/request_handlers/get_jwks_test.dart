// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:cocoon_common/core_extensions.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handling/http_io.dart';
import 'package:test/test.dart';

import '../src/request_handling/request_handler_tester.dart';

void main() {
  useTestLoggerPerTest();

  const cryptoKeyName =
      'projects/flutter-dashboard/locations/global/keyRings/cocoon-jwks/cryptoKeys/pluggable-ci';
  const rotatedCryptoKeyName =
      'projects/flutter-dashboard/locations/global/keyRings/cocoon-jwks/cryptoKeys/pluggable-ci-v2';

  // RFC 8037 Appendix A.1 Ed25519 public key PEM.
  const pem1 =
      '-----BEGIN PUBLIC KEY-----\n'
      'MCowBQYDK2VwAyEA11qYAYKxCrfVS/7TyWQHOg7hcvPapiMlrwIaaPcHURo=\n'
      '-----END PUBLIC KEY-----';
  // RFC 8410 Section 4 Ed25519 public key PEM.
  const pem2 =
      '-----BEGIN PUBLIC KEY-----\n'
      'MCowBQYDK2VwAyEAGb9ECWmEzf6FQbrBZ9w7lshQhqowtrbLDFw4rXAxZuE=\n'
      '-----END PUBLIC KEY-----';

  group('GetJwks', () {
    late CacheService cache;
    late FakeCloudKmsService cloudKms;
    late RequestHandlerTester tester;
    late Ed25519PublicJwk jwk1;
    late Ed25519PublicJwk jwk2;

    setUp(() {
      cache = CacheService.inMemory();
      cloudKms = FakeCloudKmsService();
      tester = RequestHandlerTester();
      jwk1 = Ed25519PublicJwk.fromPublicKeyPem(pem1);
      jwk2 = Ed25519PublicJwk.fromPublicKeyPem(pem2);
    });

    Future<Map<String, Object?>> decodeJsonResponse(Response response) async {
      final bytes = await response.body.collectBytes();
      return bytes.parseAsJsonObject();
    }

    test(
      'returns 200 OK with all ENABLED Ed25519 JWKS versions from Cloud KMS',
      () async {
        cloudKms
          ..putKeyVersion('$cryptoKeyName/cryptoKeyVersions/1', pem: pem1)
          ..putKeyVersion('$cryptoKeyName/cryptoKeyVersions/2', pem: pem2)
          ..putKeyVersion(
            '$cryptoKeyName/cryptoKeyVersions/3',
            pem: pem2,
            state: 'DISABLED',
          )
          ..putKeyVersion(
            '$cryptoKeyName/cryptoKeyVersions/4',
            pem: pem2,
            algorithm: 'EC_SIGN_P256_SHA256',
          );

        final config = FakeConfig(
          dynamicConfig: DynamicConfig(jwksKmsKeyName: cryptoKeyName),
        );
        final handler = GetJwks(
          config: config,
          cache: cache,
          cloudKms: cloudKms,
        );

        final response = await tester.get(handler);
        expect(response.statusCode, HttpStatus.ok);
        expect(response.contentType, kContentTypeJson);

        final body = await decodeJsonResponse(response);
        expect(body, <String, Object?>{
          'keys': <Map<String, Object?>>[
            <String, Object?>{
              'kty': 'OKP',
              'crv': 'Ed25519',
              'use': 'sig',
              'alg': 'EdDSA',
              'kid': jwk1.kid,
              'x': jwk1.x,
            },
            <String, Object?>{
              'kty': 'OKP',
              'crv': 'Ed25519',
              'use': 'sig',
              'alg': 'EdDSA',
              'kid': jwk2.kid,
              'x': jwk2.x,
            },
          ],
        });
      },
    );

    test(
      'caches JWKS response and ignores query parameters including flushCache',
      () async {
        cloudKms.putKeyVersion('$cryptoKeyName/cryptoKeyVersions/1', pem: pem1);
        final config = FakeConfig(
          dynamicConfig: DynamicConfig(jwksKmsKeyName: cryptoKeyName),
        );
        final handler = GetJwks(
          config: config,
          cache: cache,
          cloudKms: cloudKms,
        );

        // Populate cache on first request.
        final firstResponse = await tester.get(handler);
        expect(firstResponse.statusCode, HttpStatus.ok);

        // Remove key from KMS to prove GetJwks serves its own fixed-key cache
        // and ignores ?flushCache=true / arbitrary query params.
        cloudKms.clear();

        tester.request = FakeHttpRequest(
          queryParametersValue: <String, String>{
            'flushCache': 'true',
            'buster': '12345',
          },
        );
        final cachedResponse = await tester.get(handler);
        expect(cachedResponse.statusCode, HttpStatus.ok);
        final body = await decodeJsonResponse(cachedResponse);
        expect((body['keys'] as List<Object?>).single, jwk1.toJson());
      },
    );

    test(
      'serves updated JWKS immediately when DynamicConfig jwksKmsKeyName changes',
      () async {
        cloudKms
          ..putKeyVersion('$cryptoKeyName/cryptoKeyVersions/1', pem: pem1)
          ..putKeyVersion(
            '$rotatedCryptoKeyName/cryptoKeyVersions/1',
            pem: pem2,
          );
        final config = FakeConfig(
          dynamicConfig: DynamicConfig(jwksKmsKeyName: cryptoKeyName),
        );
        final handler = GetJwks(
          config: config,
          cache: cache,
          cloudKms: cloudKms,
        );

        final before = await decodeJsonResponse(await tester.get(handler));
        expect(before['keys'], <Object>[jwk1.toJson()]);

        config.dynamicConfig = DynamicConfig(
          jwksKmsKeyName: rotatedCryptoKeyName,
        );

        final after = await decodeJsonResponse(await tester.get(handler));
        expect(after['keys'], <Object>[jwk2.toJson()]);
      },
    );

    test(
      'returns 503 with message when jwksKmsKeyName is not configured',
      () async {
        final config = FakeConfig(
          dynamicConfig: DynamicConfig(jwksKmsKeyName: null),
        );
        final handler = GetJwks(
          config: config,
          cache: cache,
          cloudKms: cloudKms,
        );

        final response = await tester.get(handler);
        expect(response.statusCode, HttpStatus.serviceUnavailable);
        expect(await decodeJsonResponse(response), <String, Object?>{
          'message': 'No active JWKS public keys configured.',
        });
      },
    );

    test(
      'returns 503 and does not cache when KMS has no ENABLED Ed25519 versions',
      () async {
        final config = FakeConfig(
          dynamicConfig: DynamicConfig(jwksKmsKeyName: cryptoKeyName),
        );
        final handler = GetJwks(
          config: config,
          cache: cache,
          cloudKms: cloudKms,
        );

        final emptyResponse = await tester.get(handler);
        expect(emptyResponse.statusCode, HttpStatus.serviceUnavailable);
        expect(await decodeJsonResponse(emptyResponse), <String, Object?>{
          'message': 'No active JWKS public keys configured.',
        });

        // Verify empty result was not cached: enabling a key version now succeeds.
        cloudKms.putKeyVersion('$cryptoKeyName/cryptoKeyVersions/1', pem: pem1);
        final okResponse = await tester.get(handler);
        expect(okResponse.statusCode, HttpStatus.ok);
        final body = await decodeJsonResponse(okResponse);
        expect(body['keys'], <Object>[jwk1.toJson()]);
      },
    );

    test(
      'returns 500 with message and does not cache when Cloud KMS fails',
      () async {
        cloudKms
          ..putKeyVersion('$cryptoKeyName/cryptoKeyVersions/1', pem: pem1)
          ..listError = StateError('KMS unavailable');

        final config = FakeConfig(
          dynamicConfig: DynamicConfig(jwksKmsKeyName: cryptoKeyName),
        );
        final handler = GetJwks(
          config: config,
          cache: cache,
          cloudKms: cloudKms,
        );

        final errorResponse = await tester.get(handler);
        expect(errorResponse.statusCode, HttpStatus.internalServerError);
        expect(await decodeJsonResponse(errorResponse), <String, Object?>{
          'message': 'Failed to load JWKS public keys.',
        });

        // Verify failure was not cached: recovering KMS now succeeds.
        cloudKms.listError = null;
        final okResponse = await tester.get(handler);
        expect(okResponse.statusCode, HttpStatus.ok);
      },
    );

    test('returns 500 when KMS returns invalid public key PEM', () async {
      cloudKms.putKeyVersion(
        '$cryptoKeyName/cryptoKeyVersions/1',
        pem: 'not-a-valid-pem',
      );
      final config = FakeConfig(
        dynamicConfig: DynamicConfig(jwksKmsKeyName: cryptoKeyName),
      );
      final handler = GetJwks(config: config, cache: cache, cloudKms: cloudKms);

      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await decodeJsonResponse(response), <String, Object?>{
        'message': 'Failed to load JWKS public keys.',
      });
    });

    test('returns 500 when configured jwksKmsKeyName is malformed', () async {
      final config = FakeConfig(
        dynamicConfig: DynamicConfig(jwksKmsKeyName: '../bad/key'),
      );
      final handler = GetJwks(config: config, cache: cache, cloudKms: cloudKms);

      final response = await tester.get(handler);
      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await decodeJsonResponse(response), <String, Object?>{
        'message': 'Failed to load JWKS public keys.',
      });
    });

    test('returns 405 with {"message": ...} on POST requests', () async {
      cloudKms.putKeyVersion('$cryptoKeyName/cryptoKeyVersions/1', pem: pem1);
      final config = FakeConfig(
        dynamicConfig: DynamicConfig(jwksKmsKeyName: cryptoKeyName),
      );
      final handler = GetJwks(config: config, cache: cache, cloudKms: cloudKms);

      final server = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(server.close);
      server.listen((io.HttpRequest request) {
        handler.service(request.toRequest());
      });

      final client = io.HttpClient();
      addTearDown(client.close);
      final req = await client.post(
        io.InternetAddress.loopbackIPv4.host,
        server.port,
        '/api/v1/jwks',
      );
      final resp = await req.close();

      expect(resp.statusCode, HttpStatus.methodNotAllowed);
      final bodyBytes = await resp.collectBytes();
      expect(bodyBytes.parseAsJsonObject(), <String, Object?>{
        'message': 'Unsupported method: POST',
      });
    });
  });
}
