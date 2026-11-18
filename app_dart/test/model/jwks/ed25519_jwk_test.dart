// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/jwks/ed25519_jwk.dart';
import 'package:jose_plus/jose.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();
  // Official IETF RFC 8037 Appendix A.1 / A.3 & RFC 8410 Section 4 / 7 test vector.
  const rfcSeedBase64Url = 'nWGxne_9WmC6hEr0kuwsxERJxWl7MmkZcDusAxyuf2A';
  const rfcExpectedX = '11qYAYKxCrfVS_7TyWQHOg7hcvPapiMlrwIaaPcHURo';
  const rfcExpectedKid = 'kPrK_qmxVWaYVA9wwBF6Iuo3vVzz7TxHCTwXBygrS4k';
  const rfcExpectedPublicPem =
      '-----BEGIN PUBLIC KEY-----\n'
      'MCowBQYDK2VwAyEA11qYAYKxCrfVS/7TyWQHOg7hcvPapiMlrwIaaPcHURo=\n'
      '-----END PUBLIC KEY-----';
  const rfcExpectedPrivatePem =
      '-----BEGIN PRIVATE KEY-----\n'
      'MC4CAQAwBQYDK2VwBCIEIJ1hsZ3v/VpguoRK9JLsLMREScVpezJpGXA7rAMcrn9g\n'
      '-----END PRIVATE KEY-----';

  // Official RFC 8410 Section 7 / Section 4 Ed25519 PEM test vector.
  const rfc8410PrivatePem =
      '-----BEGIN PRIVATE KEY-----\n'
      'MC4CAQAwBQYDK2VwBCIEINTuctv5E1hK1bbY8fdp+K06/nwoy/HU++CXqI9EdVhC\n'
      '-----END PRIVATE KEY-----';
  const rfc8410PublicPem =
      '-----BEGIN PUBLIC KEY-----\n'
      'MCowBQYDK2VwAyEAGb9ECWmEzf6FQbrBZ9w7lshQhqowtrbLDFw4rXAxZuE=\n'
      '-----END PUBLIC KEY-----';

  Uint8List decodeBase64UrlUnpadded(String input) {
    return base64Url.decode(base64Url.normalize(input));
  }

  group('Ed25519KeyPair and Ed25519PublicJwk', () {
    test('matches RFC 8037 and RFC 8410 test vectors', () {
      final seed = decodeBase64UrlUnpadded(rfcSeedBase64Url);
      final keyPair = Ed25519KeyPair.fromSeed(seed);

      expect(keyPair.d, rfcSeedBase64Url);
      expect(keyPair.publicJwk.x, rfcExpectedX);
      expect(keyPair.kid, rfcExpectedKid);
      expect(keyPair.publicJwk.kid, rfcExpectedKid);
      expect(keyPair.toPublicKeyPem(), rfcExpectedPublicPem);
      expect(keyPair.toPrivateKeyPem(), rfcExpectedPrivatePem);

      expect(keyPair.publicJwk.toJson(), <String, Object>{
        'kty': 'OKP',
        'crv': 'Ed25519',
        'use': 'sig',
        'alg': 'EdDSA',
        'kid': rfcExpectedKid,
        'x': rfcExpectedX,
      });

      final rfc8410Pair = Ed25519KeyPair.fromPrivateKeyPem(rfc8410PrivatePem);
      expect(rfc8410Pair.toPrivateKeyPem(), rfc8410PrivatePem);
      expect(rfc8410Pair.toPublicKeyPem(), rfc8410PublicPem);
    });

    test('round-trips generated key pair through PKCS#8 and SPKI PEM', () {
      final generated = Ed25519KeyPair.generate(Random(42));
      final privatePem = generated.toPrivateKeyPem();
      final publicPem = generated.toPublicKeyPem();

      final parsedPrivate = Ed25519KeyPair.fromPrivateKeyPem(
        privatePem,
        expectedKid: generated.kid,
      );
      final parsedPublic = Ed25519PublicJwk.fromPublicKeyPem(
        publicPem,
        expectedKid: generated.kid,
      );

      expect(parsedPrivate.seedBytes, generated.seedBytes);
      expect(parsedPrivate.publicJwk, generated.publicJwk);
      expect(parsedPublic, generated.publicJwk);
      expect(parsedPublic.kid, hasLength(43));
      expect(isValidJwksKeyId(parsedPublic.kid), isTrue);
    });

    test(
      'signs and verifies EdDSA JWT using jose_plus and public JWK',
      () async {
        final keyPair = Ed25519KeyPair.generate(Random(7));

        final builder = JsonWebSignatureBuilder()
          ..jsonContent = <String, Object>{
            'iss': 'cocoon',
            'aud': 'https://partner-ci.example.com/webhook',
            'iat': 1774962000,
            'exp': 1774962300,
            'version': 'v1',
          }
          ..setProtectedHeader('typ', 'JWT')
          ..addRecipient(keyPair.toPrivateJoseKey(), algorithm: 'EdDSA');

        final compactJwt = builder.build().toCompactSerialization();

        // Simulate partner loading Cocoon's /api/v1/jwks response.
        final partnerKeyStore = JsonWebKeyStore()
          ..addKey(JsonWebKey.fromJson(keyPair.publicJwk.toJson())!);

        final verified = await JsonWebToken.decodeAndVerify(
          compactJwt,
          partnerKeyStore,
          allowedArguments: const <String>['EdDSA'],
        );
        expect(verified.claims['iss'], 'cocoon');
        expect(verified.claims['version'], 'v1');
        expect(
          JoseObject.fromCompactSerialization(
            compactJwt,
          ).commonProtectedHeader['kid'],
          keyPair.kid,
        );
      },
    );

    test('parses OneAsymmetricKey v2 (version 1) with embedded public key', () {
      final seed = decodeBase64UrlUnpadded(rfcSeedBase64Url);
      final pubBytes = decodeBase64UrlUnpadded(rfcExpectedX);

      // Build RFC 8410 Section 7 OneAsymmetricKey v2 DER with [1] publicKey.
      final inner = BytesBuilder()
        ..add(const <int>[0x02, 0x01, 0x01]) // version = 1 (v2)
        ..add(const <int>[0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70]) // Ed25519
        ..add(const <int>[0x04, 0x22, 0x04, 0x20])
        ..add(seed)
        ..add(const <int>[0x81, 0x21, 0x00]) // [1] IMPLICIT BIT STRING
        ..add(pubBytes);
      final innerBytes = inner.toBytes();
      final der = Uint8List.fromList(<int>[
        0x30,
        innerBytes.length,
        ...innerBytes,
      ]);
      final pem =
          '-----BEGIN PRIVATE KEY-----\n'
          '${base64Encode(der)}\n'
          '-----END PRIVATE KEY-----';

      final parsed = Ed25519KeyPair.fromPrivateKeyPem(
        pem,
        expectedKid: rfcExpectedKid,
      );
      expect(parsed.publicJwk.x, rfcExpectedX);
    });

    test('rejects OneAsymmetricKey v2 with mismatched embedded public key', () {
      final seed = decodeBase64UrlUnpadded(rfcSeedBase64Url);
      final wrongPubBytes = Uint8List(32); // All zeroes

      final inner = BytesBuilder()
        ..add(const <int>[0x02, 0x01, 0x01])
        ..add(const <int>[0x30, 0x05, 0x06, 0x03, 0x2b, 0x65, 0x70])
        ..add(const <int>[0x04, 0x22, 0x04, 0x20])
        ..add(seed)
        ..add(const <int>[0x81, 0x21, 0x00])
        ..add(wrongPubBytes);
      final innerBytes = inner.toBytes();
      final der = Uint8List.fromList(<int>[
        0x30,
        innerBytes.length,
        ...innerBytes,
      ]);
      final pem =
          '-----BEGIN PRIVATE KEY-----\n'
          '${base64Encode(der)}\n'
          '-----END PRIVATE KEY-----';

      expect(
        () => Ed25519KeyPair.fromPrivateKeyPem(pem),
        throwsFormatException,
      );
    });

    test('rejects expectedKid mismatch', () {
      expect(
        () => Ed25519PublicJwk.fromPublicKeyPem(
          rfcExpectedPublicPem,
          expectedKid: 'wrong-kid',
        ),
        throwsFormatException,
      );
      expect(
        () => Ed25519KeyPair.fromPrivateKeyPem(
          rfcExpectedPrivatePem,
          expectedKid: 'wrong-kid',
        ),
        throwsFormatException,
      );
    });

    test('rejects wrong PEM types and malformed inputs', () {
      expect(
        () => Ed25519PublicJwk.fromPublicKeyPem(rfcExpectedPrivatePem),
        throwsFormatException,
      );
      expect(
        () => Ed25519KeyPair.fromPrivateKeyPem(rfcExpectedPublicPem),
        throwsFormatException,
      );
      expect(
        () => Ed25519PublicJwk.fromPublicKeyBytes(Uint8List(31)),
        throwsFormatException,
      );
      expect(
        () => Ed25519KeyPair.fromSeed(Uint8List(33)),
        throwsFormatException,
      );

      // SPKI with disallowed NULL parameter in AlgorithmIdentifier (RFC 8410 §3).
      final pubBytes = decodeBase64UrlUnpadded(rfcExpectedX);
      final badAlgSpki = Uint8List.fromList(<int>[
        0x30, 0x2c,
        0x30, 0x07, 0x06, 0x03, 0x2b, 0x65, 0x70, 0x05, 0x00, // extra NULL
        0x03, 0x21, 0x00,
        ...pubBytes,
      ]);
      final badPem =
          '-----BEGIN PUBLIC KEY-----\n'
          '${base64Encode(badAlgSpki)}\n'
          '-----END PUBLIC KEY-----';
      expect(
        () => Ed25519PublicJwk.fromPublicKeyPem(badPem),
        throwsFormatException,
      );
    });

    test('validates key ID format', () {
      expect(isValidJwksKeyId(rfcExpectedKid), isTrue);
      expect(isValidJwksKeyId('abc_123-XYZ'), isTrue);
      expect(isValidJwksKeyId(''), isFalse);
      expect(isValidJwksKeyId('../secret'), isFalse);
      expect(isValidJwksKeyId('abc=def'), isFalse);
      expect(isValidJwksKeyId('abc+def'), isFalse);
      expect(isValidJwksKeyId('abc def'), isFalse);
    });
  });
}
