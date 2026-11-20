// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/cloud_kms_service.dart';
import 'package:googleapis/cloudkms/v1.dart' as kms;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  const cryptoKeyName =
      'projects/flutter-dashboard/locations/global/keyRings/cocoon-jwks/cryptoKeys/pluggable-ci';
  const version1 = '$cryptoKeyName/cryptoKeyVersions/1';
  const version2 = '$cryptoKeyName/cryptoKeyVersions/2';
  const version3 = '$cryptoKeyName/cryptoKeyVersions/3';

  const rfcPublicPem =
      '-----BEGIN PUBLIC KEY-----\n'
      'MCowBQYDK2VwAyEA11qYAYKxCrfVS/7TyWQHOg7hcvPapiMlrwIaaPcHURo=\n'
      '-----END PUBLIC KEY-----';

  group('CloudKmsService', () {
    test('validates CryptoKey and CryptoKeyVersion resource names', () {
      expect(CloudKmsService.isValidCryptoKeyName(cryptoKeyName), isTrue);
      expect(CloudKmsService.isValidCryptoKeyName(version1), isFalse);
      expect(CloudKmsService.isValidCryptoKeyName(''), isFalse);
      expect(
        CloudKmsService.isValidCryptoKeyName('projects/../locations/global'),
        isFalse,
      );

      expect(CloudKmsService.isValidCryptoKeyVersionName(version1), isTrue);
      expect(
        CloudKmsService.isValidCryptoKeyVersionName(cryptoKeyName),
        isFalse,
      );
      expect(CloudKmsService.isValidCryptoKeyVersionName(''), isFalse);
    });

    test(
      'listEnabledEd25519KeyVersionNames paginates and filters to enabled Ed25519 versions',
      () async {
        var requestCount = 0;
        final mockClient = MockClient((http.Request request) async {
          requestCount++;
          expect(request.method, 'GET');
          expect(request.url.path, '/v1/$cryptoKeyName/cryptoKeyVersions');
          expect(
            request.url.queryParameters['filter'],
            'state=ENABLED AND algorithm=EC_SIGN_ED25519',
          );

          if (request.url.queryParameters['pageToken'] == null) {
            return http.Response(
              jsonEncode(<String, Object?>{
                'cryptoKeyVersions': <Map<String, Object?>>[
                  <String, Object?>{
                    'name': version1,
                    'state': 'ENABLED',
                    'algorithm': 'EC_SIGN_ED25519',
                  },
                  <String, Object?>{
                    'name': version2,
                    'state': 'DISABLED',
                    'algorithm': 'EC_SIGN_ED25519',
                  },
                ],
                'nextPageToken': 'page-2',
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }

          expect(request.url.queryParameters['pageToken'], 'page-2');
          return http.Response(
            jsonEncode(<String, Object?>{
              'cryptoKeyVersions': <Map<String, Object?>>[
                <String, Object?>{
                  'name': version3,
                  'state': 'ENABLED',
                  'algorithm': 'EC_SIGN_ED25519',
                },
                <String, Object?>{
                  'name': '$cryptoKeyName/cryptoKeyVersions/4',
                  'state': 'ENABLED',
                  'algorithm': 'EC_SIGN_P256_SHA256',
                },
              ],
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        });

        final service = CloudKmsService.fromApi(kms.CloudKMSApi(mockClient));
        final versions = await service.listEnabledEd25519KeyVersionNames(
          cryptoKeyName,
        );

        expect(requestCount, 2);
        expect(versions, <String>[version1, version3]);
      },
    );

    test(
      'listEnabledEd25519KeyVersionNames rejects invalid CryptoKey name',
      () async {
        final service = CloudKmsService.fromApi(
          kms.CloudKMSApi(
            MockClient((_) async => throw StateError('Unreachable')),
          ),
        );
        await expectLater(
          service.listEnabledEd25519KeyVersionNames('invalid/key'),
          throwsFormatException,
        );
      },
    );

    test('getPublicKeyPem returns SPKI PEM for Ed25519 key version', () async {
      final mockClient = MockClient((http.Request request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/v1/$version1/publicKey');
        return http.Response(
          jsonEncode(<String, Object?>{
            'pem': rfcPublicPem,
            'algorithm': 'EC_SIGN_ED25519',
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });

      final service = CloudKmsService.fromApi(kms.CloudKMSApi(mockClient));
      final pem = await service.getPublicKeyPem(version1);
      expect(pem, rfcPublicPem);
    });

    test(
      'getPublicKeyPem rejects non-Ed25519 algorithm or empty PEM',
      () async {
        final nonEdClient = MockClient((_) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'pem': rfcPublicPem,
              'algorithm': 'EC_SIGN_P256_SHA256',
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        });
        final nonEdService = CloudKmsService.fromApi(
          kms.CloudKMSApi(nonEdClient),
        );
        await expectLater(
          nonEdService.getPublicKeyPem(version1),
          throwsFormatException,
        );

        final emptyPemClient = MockClient((_) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'pem': '',
              'algorithm': 'EC_SIGN_ED25519',
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        });
        final emptyPemService = CloudKmsService.fromApi(
          kms.CloudKMSApi(emptyPemClient),
        );
        await expectLater(
          emptyPemService.getPublicKeyPem(version1),
          throwsFormatException,
        );
      },
    );

    test(
      'asymmetricSign sends raw base64 data for PureEdDSA and decodes 64-byte signature',
      () async {
        final expectedSig = Uint8List.fromList(
          List<int>.generate(64, (i) => i),
        );
        final payload = Uint8List.fromList(utf8.encode('header.payload'));

        final mockClient = MockClient((http.Request request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/v1/$version1:asymmetricSign');
          final body = jsonDecode(request.body) as Map<String, Object?>;
          expect(body['data'], base64Encode(payload));
          expect(body.containsKey('digest'), isFalse);

          return http.Response(
            jsonEncode(<String, Object?>{
              'signature': base64Encode(expectedSig),
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        });

        final service = CloudKmsService.fromApi(kms.CloudKMSApi(mockClient));
        final sig = await service.asymmetricSign(version1, payload);
        expect(sig, expectedSig);
      },
    );

    test('asymmetricSign rejects malformed signature lengths', () async {
      final mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode(<String, Object?>{
            'signature': base64Encode(Uint8List(32)),
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });

      final service = CloudKmsService.fromApi(kms.CloudKMSApi(mockClient));
      await expectLater(
        service.asymmetricSign(version1, Uint8List.fromList(<int>[1, 2, 3])),
        throwsFormatException,
      );
    });
  });
}
