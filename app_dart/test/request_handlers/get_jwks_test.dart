// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'dart:math';

import 'package:cocoon_common/core_extensions.dart';
import 'package:cocoon_integration_test/testing.dart';
import 'package:cocoon_server_test/fake_secret_manager.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handling/http_io.dart';
import 'package:test/test.dart';

import '../src/request_handling/request_handler_tester.dart';

void main() {
  useTestLoggerPerTest();

  group('GetJwks', () {
    late CacheService cache;
    late FakeSecretManager secrets;
    late RequestHandlerTester tester;
    late Ed25519KeyPair keyPair1;
    late Ed25519KeyPair keyPair2;

    setUp(() {
      cache = CacheService.inMemory();
      secrets = FakeSecretManager();
      tester = RequestHandlerTester();
      keyPair1 = Ed25519KeyPair.generate(Random(1));
      keyPair2 = Ed25519KeyPair.generate(Random(2));
    });

    Future<Map<String, Object?>> decodeJsonResponse(Response response) async {
      final bytes = await response.body.collectBytes();
      return bytes.parseAsJsonObject();
    }

    test(
      'returns 200 OK with active Ed25519 JWKS from Secret Manager',
      () async {
        secrets.putString(
          Config.jwksPublicKeySecretName(keyPair1.kid),
          keyPair1.toPublicKeyPem(),
        );
        secrets.putString(
          Config.jwksPublicKeySecretName(keyPair2.kid),
          keyPair2.toPublicKeyPem(),
        );

        final config = Config(
          cache,
          secrets,
          initialConfig: DynamicConfig(
            // Include a duplicate kid to verify deduplication preserves order.
            jwksPublicKids: <String>[keyPair1.kid, keyPair2.kid, keyPair1.kid],
          ),
        );
        final handler = GetJwks(config: config, cache: cache);

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
              'kid': keyPair1.kid,
              'x': keyPair1.publicJwk.x,
            },
            <String, Object?>{
              'kty': 'OKP',
              'crv': 'Ed25519',
              'use': 'sig',
              'alg': 'EdDSA',
              'kid': keyPair2.kid,
              'x': keyPair2.publicJwk.x,
            },
          ],
        });
      },
    );

    test(
      'caches JWKS response and ignores query parameters including flushCache',
      () async {
        secrets.putString(
          Config.jwksPublicKeySecretName(keyPair1.kid),
          keyPair1.toPublicKeyPem(),
        );
        final config = Config(
          cache,
          secrets,
          initialConfig: DynamicConfig(jwksPublicKids: <String>[keyPair1.kid]),
        );
        final handler = GetJwks(config: config, cache: cache);

        // Populate cache on first request.
        final firstResponse = await tester.get(handler);
        expect(firstResponse.statusCode, HttpStatus.ok);

        // Remove secret and config cache entry to prove GetJwks serves its own
        // fixed-key cache and ignores ?flushCache=true / arbitrary query params.
        secrets.remove(Config.jwksPublicKeySecretName(keyPair1.kid));
        await cache.purge(
          Config.configCacheName,
          Config.jwksPublicKeySecretName(keyPair1.kid),
        );

        tester.request = FakeHttpRequest(
          queryParametersValue: <String, String>{
            'flushCache': 'true',
            'buster': '12345',
          },
        );
        final cachedResponse = await tester.get(handler);
        expect(cachedResponse.statusCode, HttpStatus.ok);
        final body = await decodeJsonResponse(cachedResponse);
        expect(
          (body['keys'] as List<Object?>).single,
          keyPair1.publicJwk.toJson(),
        );
      },
    );

    test(
      'serves updated JWKS immediately when DynamicConfig kids change',
      () async {
        final config = FakeConfig(
          jwksPublicKeyPemsValue: <String, String>{
            keyPair1.kid: keyPair1.toPublicKeyPem(),
            keyPair2.kid: keyPair2.toPublicKeyPem(),
          },
          dynamicConfig: DynamicConfig(jwksPublicKids: <String>[keyPair1.kid]),
        );
        final handler = GetJwks(config: config, cache: cache);

        final beforeRotation = await decodeJsonResponse(
          await tester.get(handler),
        );
        expect(beforeRotation['keys'], <Object>[keyPair1.publicJwk.toJson()]);

        // Simulate DynamicConfigUpdater refreshing config.yaml with a rotated key.
        config.dynamicConfig = DynamicConfig(
          jwksPublicKids: <String>[keyPair1.kid, keyPair2.kid],
        );

        final duringRotation = await decodeJsonResponse(
          await tester.get(handler),
        );
        expect(duringRotation['keys'], <Object>[
          keyPair1.publicJwk.toJson(),
          keyPair2.publicJwk.toJson(),
        ]);
      },
    );

    test(
      'returns 503 with message when no active keys are configured',
      () async {
        final config = FakeConfig(
          dynamicConfig: DynamicConfig(jwksPublicKids: const <String>[]),
        );
        final handler = GetJwks(config: config, cache: cache);

        final response = await tester.get(handler);
        expect(response.statusCode, HttpStatus.serviceUnavailable);
        expect(await decodeJsonResponse(response), <String, Object?>{
          'message': 'No active JWKS public keys configured.',
        });
      },
    );

    test(
      'returns 500 with message and does not cache when secret is missing',
      () async {
        final config = Config(
          cache,
          secrets,
          initialConfig: DynamicConfig(jwksPublicKids: <String>[keyPair1.kid]),
        );
        final handler = GetJwks(config: config, cache: cache);

        final errorResponse = await tester.get(handler);
        expect(errorResponse.statusCode, HttpStatus.internalServerError);
        expect(await decodeJsonResponse(errorResponse), <String, Object?>{
          'message': 'Failed to load JWKS public keys.',
        });

        // Verify failure was not cached: adding the secret now succeeds.
        secrets.putString(
          Config.jwksPublicKeySecretName(keyPair1.kid),
          keyPair1.toPublicKeyPem(),
        );
        final okResponse = await tester.get(handler);
        expect(okResponse.statusCode, HttpStatus.ok);
      },
    );

    test(
      'returns 500 when stored public key thumbprint does not match kid',
      () async {
        // Store keyPair2's PEM under keyPair1's kid.
        secrets.putString(
          Config.jwksPublicKeySecretName(keyPair1.kid),
          keyPair2.toPublicKeyPem(),
        );
        final config = Config(
          cache,
          secrets,
          initialConfig: DynamicConfig(jwksPublicKids: <String>[keyPair1.kid]),
        );
        final handler = GetJwks(config: config, cache: cache);

        final response = await tester.get(handler);
        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await decodeJsonResponse(response), <String, Object?>{
          'message': 'Failed to load JWKS public keys.',
        });
      },
    );

    test(
      'returns 500 when configured kid contains invalid characters',
      () async {
        final config = FakeConfig(
          dynamicConfig: DynamicConfig(
            jwksPublicKids: const <String>['../bad'],
          ),
        );
        final handler = GetJwks(config: config, cache: cache);

        final response = await tester.get(handler);
        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await decodeJsonResponse(response), <String, Object?>{
          'message': 'Failed to load JWKS public keys.',
        });
      },
    );

    test('returns 405 with {"message": ...} on POST requests', () async {
      final config = FakeConfig(
        jwksPublicKeyPemsValue: <String, String>{
          keyPair1.kid: keyPair1.toPublicKeyPem(),
        },
        dynamicConfig: DynamicConfig(jwksPublicKids: <String>[keyPair1.kid]),
      );
      final handler = GetJwks(config: config, cache: cache);

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
