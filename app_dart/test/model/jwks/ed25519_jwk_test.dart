// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/jwks/ed25519_jwk.dart';
import 'package:jose_plus/jose.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  // Official IETF RFC 8037 Appendix A.1 / A.3 & RFC 8410 Section 4 test vectors.
  const rfcExpectedX = '11qYAYKxCrfVS_7TyWQHOg7hcvPapiMlrwIaaPcHURo';
  const rfcExpectedKid = 'kPrK_qmxVWaYVA9wwBF6Iuo3vVzz7TxHCTwXBygrS4k';
  const rfcExpectedPublicPem =
      '-----BEGIN PUBLIC KEY-----\n'
      'MCowBQYDK2VwAyEA11qYAYKxCrfVS/7TyWQHOg7hcvPapiMlrwIaaPcHURo=\n'
      '-----END PUBLIC KEY-----';
  const rfcPrivatePem =
      '-----BEGIN PRIVATE KEY-----\n'
      'MC4CAQAwBQYDK2VwBCIEIJ1hsZ3v/VpguoRK9JLsLMREScVpezJpGXA7rAMcrn9g\n'
      '-----END PRIVATE KEY-----';

  // Official RFC 8410 Section 4 Ed25519 SPKI PEM test vector.
  const rfc8410PublicPem =
      '-----BEGIN PUBLIC KEY-----\n'
      'MCowBQYDK2VwAyEAGb9ECWmEzf6FQbrBZ9w7lshQhqowtrbLDFw4rXAxZuE=\n'
      '-----END PUBLIC KEY-----';

  // Official RFC 8037 Appendix A.4 EdDSA JWS signed with the Appendix A.1 key.
  const rfc8037SignedJws =
      'eyJhbGciOiJFZERTQSJ9.'
      'RXhhbXBsZSBvZiBFZDI1NTE5IHNpZ25pbmc.'
      'hgyY0il_MGCjP0JzlnLWG1PPOt7-09PGcvMg3AIbQR6dWbhijcNR4ki4iylGjg5BhVsPt9g7sVvpAr_MuM0KAg';

  Uint8List decodeBase64UrlUnpadded(String input) {
    return base64Url.decode(base64Url.normalize(input));
  }

  group('Ed25519PublicJwk', () {
    test('matches RFC 8037 and RFC 8410 public key test vectors', () {
      final parsed = Ed25519PublicJwk.fromPublicKeyPem(
        rfcExpectedPublicPem,
        expectedKid: rfcExpectedKid,
      );

      expect(parsed.x, rfcExpectedX);
      expect(parsed.kid, rfcExpectedKid);
      expect(parsed.toPublicKeyPem(), rfcExpectedPublicPem);
      expect(parsed.publicKeyBytes, decodeBase64UrlUnpadded(rfcExpectedX));
      expect(parsed.toJson(), <String, Object>{
        'kty': 'OKP',
        'crv': 'Ed25519',
        'use': 'sig',
        'alg': 'EdDSA',
        'kid': rfcExpectedKid,
        'x': rfcExpectedX,
      });

      final fromBytes = Ed25519PublicJwk.fromPublicKeyBytes(
        decodeBase64UrlUnpadded(rfcExpectedX),
      );
      expect(fromBytes, parsed);

      final rfc8410Parsed = Ed25519PublicJwk.fromPublicKeyPem(rfc8410PublicPem);
      expect(rfc8410Parsed.toPublicKeyPem(), rfc8410PublicPem);
      expect(rfc8410Parsed.kid, hasLength(43));
      expect(isValidJwksKeyId(rfc8410Parsed.kid), isTrue);
    });

    test(
      'verifies RFC 8037 Appendix A.4 EdDSA JWS using jose_plus and public JWK',
      () async {
        final publicJwk = Ed25519PublicJwk.fromPublicKeyPem(
          rfcExpectedPublicPem,
        );
        final keyStore = JsonWebKeyStore()..addKey(publicJwk.toJoseKey());

        final jws = JsonWebSignature.fromCompactSerialization(rfc8037SignedJws);
        final payload = await jws.getPayload(
          keyStore,
          allowedAlgorithms: const <String>['EdDSA'],
        );
        expect(payload.stringContent, 'Example of Ed25519 signing');
      },
    );

    test('rejects expectedKid mismatch', () {
      expect(
        () => Ed25519PublicJwk.fromPublicKeyPem(
          rfcExpectedPublicPem,
          expectedKid: 'wrong-kid',
        ),
        throwsFormatException,
      );
    });

    test('rejects wrong PEM types and malformed inputs', () {
      expect(
        () => Ed25519PublicJwk.fromPublicKeyPem(rfcPrivatePem),
        throwsFormatException,
      );
      expect(
        () => Ed25519PublicJwk.fromPublicKeyBytes(Uint8List(31)),
        throwsFormatException,
      );
      expect(
        () => Ed25519PublicJwk.fromPublicKeyPem(
          '-----BEGIN PUBLIC KEY-----\n-----END PUBLIC KEY-----',
        ),
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

      // Multiple PEM blocks in a single input should be rejected.
      expect(
        () => Ed25519PublicJwk.fromPublicKeyPem(
          '$rfcExpectedPublicPem\n$rfc8410PublicPem',
        ),
        throwsFormatException,
      );

      // Boundary markers must appear on their own lines (RFC 7468).
      expect(
        () => Ed25519PublicJwk.fromPublicKeyPem('prefix $rfcExpectedPublicPem'),
        throwsFormatException,
      );
    });

    test('ignores leading and trailing PEM metadata and comments', () {
      const pemWithMetadata =
          'Bag Attributes\r\n'
          '    friendlyName: pluggable-ci\r\n'
          '# Generated by Cloud KMS\r\n'
          '-----BEGIN PUBLIC KEY-----\r\n'
          'MCowBQYDK2VwAyEA11qYAYKxCrfVS/7TyWQHOg7hcvPapiMlrwIaaPcHURo=\r\n'
          '-----END PUBLIC KEY-----\r\n'
          'Trailing note\r\n';

      final parsed = Ed25519PublicJwk.fromPublicKeyPem(
        pemWithMetadata,
        expectedKid: rfcExpectedKid,
      );
      expect(parsed.x, rfcExpectedX);
      expect(parsed.kid, rfcExpectedKid);
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
