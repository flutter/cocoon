// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/service/firebase_jwt_validator.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:jose_plus/jose.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  final rightNow = DateTime(2025, 04, 16, 12, 00);
  final beforeNow =
      rightNow.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/
      1000;
  final afterNow =
      rightNow.add(const Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000;

  test('verifies not expired', () {
    expect(
      () => FirebaseJwtValidator.verifyJwtClaims(
        JsonWebTokenClaims.fromJson({'exp': beforeNow}),
        rightNow,
      ),
      jwtException('JWT expired'),
    );
  });

  test('verifies not issued in the future', () {
    expect(
      () => FirebaseJwtValidator.verifyJwtClaims(
        JsonWebTokenClaims.fromJson({'exp': afterNow, 'iat': afterNow}),
        rightNow,
      ),
      jwtException('JWT issued in the future'),
    );
  });

  test('verifies not auth_time in the future', () {
    expect(
      () => FirebaseJwtValidator.verifyJwtClaims(
        JsonWebTokenClaims.fromJson({
          'exp': afterNow,
          'iat': beforeNow,
          'auth_time': afterNow,
        }),
        rightNow,
      ),
      jwtException('JWT auth_time in the future'),
    );
  });

  test('verifies audience contains `flutter-dashboard`', () {
    expect(
      () => FirebaseJwtValidator.verifyJwtClaims(
        JsonWebTokenClaims.fromJson({
          'exp': afterNow,
          'iat': beforeNow,
          'auth_time': beforeNow,
          'aud': 'bar',
        }),
        rightNow,
      ),
      jwtException('JWT aud does not include flutter-dashboard'),
    );
  });

  test(
    'verifies issuer is `https://securetoken.google.com/flutter-dashboard`',
    () {
      expect(
        () => FirebaseJwtValidator.verifyJwtClaims(
          JsonWebTokenClaims.fromJson({
            'exp': afterNow,
            'iat': beforeNow,
            'auth_time': beforeNow,
            'aud': ['flutter-dashboard'],
            'iss': 'https://example.com',
          }),
          rightNow,
        ),
        jwtException(
          'JWT iss not from https://securetoken.google.com/flutter-dashboard',
        ),
      );
    },
  );

  test('verifies subject is not empty', () {
    expect(
      () => FirebaseJwtValidator.verifyJwtClaims(
        JsonWebTokenClaims.fromJson({
          'exp': afterNow,
          'iat': beforeNow,
          'auth_time': beforeNow,
          'aud': ['flutter-dashboard'],
          'iss': 'https://securetoken.google.com/flutter-dashboard',
        }),
        rightNow,
      ),
      jwtException('JWT subject is empty string'),
    );
  });

  test('verification passes', () {
    expect(
      () => FirebaseJwtValidator.verifyJwtClaims(
        JsonWebTokenClaims.fromJson({
          'exp': afterNow,
          'iat': beforeNow,
          'auth_time': beforeNow,
          'aud': ['flutter-dashboard'],
          'iss': 'https://securetoken.google.com/flutter-dashboard',
          'sub': 'abcdef',
        }),
        rightNow,
      ),
      returnsNormally,
    );
  });

  group('service', () {
    late FirebaseJwtValidator validator;
    late List<Response> pemKeyResponse;
    late CacheService cache;
    late DateTime now;

    setUp(() {
      cache = CacheService(inMemory: true);
      now = DateTime(2025, 04, 16, 12, 00);
      pemKeyResponse = [Response(pemKeysString, 200)];

      validator = FirebaseJwtValidator(
        cache: cache,
        now: () => now,
        client: MockClient((req) async {
          if (req.url == FirebaseJwtValidator.firebasePEMKeysUri) {
            if (pemKeyResponse.isNotEmpty) {
              return pemKeyResponse.removeAt(0);
            }
          }
          return Response('', 404);
        }),
      );
    });

    test('caches calls for PEM keys', () async {
      pemKeyResponse.add(Response(pemKeysString, 200));
      await validator.maybeRefreshKeyStore();
      await validator.maybeRefreshKeyStore();
      expect(pemKeyResponse.length, 1, reason: 'keys fetched once');
    });

    test('refreshes keystore', () async {
      pemKeyResponse.add(Response(pemKeysSingleString, 200));
      final header = JoseHeader.fromBase64EncodedString(
        'eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg1NzA4MWNhOWNiYjM3YzIzNDk4ZGQzOTQzYmYzNzFhMDU4ODNkMjgiLCJ0eXAiOiJKV1QifQ',
      );

      await validator.maybeRefreshKeyStore();
      expect(
        await validator.keyStore.findJsonWebKeys(header, 'verify').toList(),
        isNotEmpty,
      );

      await cache.purge('firebase_jwt_keys', 'firebase_jwt_keys');
      await validator.maybeRefreshKeyStore();

      expect(pemKeyResponse.length, 0, reason: 'second fetch after purge');
      expect(
        await validator.keyStore.findJsonWebKeys(header, 'verify').toList(),
        isEmpty,
      );
    });
  });
}

Matcher jwtException(String message) =>
    throwsA(isA<JwtException>().having((r) => r.message, 'message', message));

const pemKeysString = r'''{
  "857081ca9cbb37c23498dd3943bf371a05883d28": "-----BEGIN CERTIFICATE-----\nMIIDHDCCAgSgAwIBAgIIOBNPkX+Mt1wwDQYJKoZIhvcNAQEFBQAwMTEvMC0GA1UE\nAwwmc2VjdXJldG9rZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wHhcNMjUw\nNDA5MDczMzA0WhcNMjUwNDI1MTk0ODA0WjAxMS8wLQYDVQQDDCZzZWN1cmV0b2tl\nbi5zeXN0ZW0uZ3NlcnZpY2VhY2NvdW50LmNvbTCCASIwDQYJKoZIhvcNAQEBBQAD\nggEPADCCAQoCggEBAMSZYAER4kpUeokjt8runwdE5+IWn8+htnXm22W3UuRfT2nI\n6sOCESNwvqu9jGgyQMuP7HNGFoT4atg3DmEQcXxzdOSvz0dJfk3JjMiFggxScpq5\nZ1m54/GJt7U2oX2RriwVzNfyCxnKwGAp5L6ViNijX0iv2zyZeaJhxz8ZVwrEgpSd\nS1uk5MVblaiIDrV6KsJ0ES4cDm0WhdgLXE3lMjY8jPlumf6jIPTAuYuuTzPPXSnJ\nQuEm0s8mloLYwniX21HAkvvGxa82R7N/xwZRUhKSq9d9NDrO9twCQlt9CRPB7XpU\nGq0dgT8ja7Ker3Zh6yRmbAbgtkOeIUB0lRzcQvsCAwEAAaM4MDYwDAYDVR0TAQH/\nBAIwADAOBgNVHQ8BAf8EBAMCB4AwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwIwDQYJ\nKoZIhvcNAQEFBQADggEBACcCmjn3Z+FE8wR8/bvIz7AKJffgwDSzajrBMOHQid5g\nF6RxfRsoa32AvP6k0JUAVxpys+H1WEj+9sgaMYD6R067v8B8LnofNGwrUn17Y5NY\nPQuK3Gda6uA4SHOUNphiasYqnEpQT5ch+9Y5zs4cjUfz+JbRR8VOnbO7WhAqDdA/\nvtgMaMo9ImhF+Zig/ZS81OVZPNMLP9UZo6V/1n/boL+MSBqm2b8UR/6mN0+R34fK\nJJ3EtrhhA2uq1WOsZqop26vGBLkL9kHZqKVyATkS7mZL/kg7emgqw6JmD4DL43AS\ndqiX4OeivdvnsQYU6R0ZKqvRwjaZcl94rpmxjwPWjH0=\n-----END CERTIFICATE-----\n",
  "71115235a6c61454efdedc45a77e4351367eebe0": "-----BEGIN CERTIFICATE-----\nMIIDHTCCAgWgAwIBAgIJAPQj4R1B9zajMA0GCSqGSIb3DQEBBQUAMDExLzAtBgNV\nBAMMJnNlY3VyZXRva2VuLnN5c3RlbS5nc2VydmljZWFjY291bnQuY29tMB4XDTI1\nMDQwMTA3MzMwM1oXDTI1MDQxNzE5NDgwM1owMTEvMC0GA1UEAwwmc2VjdXJldG9r\nZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wggEiMA0GCSqGSIb3DQEBAQUA\nA4IBDwAwggEKAoIBAQCzi1z5FfjOtZIpaNIxI0/jQdoeCnUhY1xeSCzds3kGPTee\nioVQh3tk8RBeBkjkRFKfrzvFisShYh2xrrQ6IEBJ7tfqUpDxv4Ejjw5VylM0Tvy1\n2fMpFtyaIWqp+j4KAEtESr0bogcMOYdfs0ma+kVH098vuQQ29W+YBDCnFIcb2IQU\nWc72vN+lBLsJ8GDxN9OKyHF9/+TtGBCDwRK6dzWYYsyL5vQJD1Pto70nk6vtrffm\nkSOqYm0PwLWHuXd4gvQuXlqnR0WUfQTEFMoG8iVGM21yfABmtawkykHXRtEsr6/d\nHxuD+B43gYZKKfPR3Rf9M8Da2RmQ4H98Lk070cX5AgMBAAGjODA2MAwGA1UdEwEB\n/wQCMAAwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMCMA0G\nCSqGSIb3DQEBBQUAA4IBAQCvUpnPb1dhjJm0zSXXHa7m1Ti/tid/0tfRjS51esFu\n2DmsI9uUzQukRQzZXLKxqHbVUdAI2RAOg5i7GStlkvniXomPVcU6fYiYsdBGEah2\n6LNMiSja0/F7cA1qpWBCekJuN9nCEd75bwLHiVVCDK6su7EXzLQn7NZGpeDiCQhv\n8tYOdyg9ArdZMflMihpBZ5LJbuZYH4OhheDc9vnnZ5+klqghL6ixcqg/zIAHVGEi\nqIQim7ZSnkNxHLEYtlUhHiuYOoF5dKqYLeudYp0esNDgW15gv8sJ7f20Br2cldEc\nR7GG1M+sM55z/55LjdDg9GCb3d0jVR9sk8DMMGh8q+MO\n-----END CERTIFICATE-----\n"
}''';

const pemKeysSingleString = r'''{
  "71115235a6c61454efdedc45a77e4351367eebe0": "-----BEGIN CERTIFICATE-----\nMIIDHTCCAgWgAwIBAgIJAPQj4R1B9zajMA0GCSqGSIb3DQEBBQUAMDExLzAtBgNV\nBAMMJnNlY3VyZXRva2VuLnN5c3RlbS5nc2VydmljZWFjY291bnQuY29tMB4XDTI1\nMDQwMTA3MzMwM1oXDTI1MDQxNzE5NDgwM1owMTEvMC0GA1UEAwwmc2VjdXJldG9r\nZW4uc3lzdGVtLmdzZXJ2aWNlYWNjb3VudC5jb20wggEiMA0GCSqGSIb3DQEBAQUA\nA4IBDwAwggEKAoIBAQCzi1z5FfjOtZIpaNIxI0/jQdoeCnUhY1xeSCzds3kGPTee\nioVQh3tk8RBeBkjkRFKfrzvFisShYh2xrrQ6IEBJ7tfqUpDxv4Ejjw5VylM0Tvy1\n2fMpFtyaIWqp+j4KAEtESr0bogcMOYdfs0ma+kVH098vuQQ29W+YBDCnFIcb2IQU\nWc72vN+lBLsJ8GDxN9OKyHF9/+TtGBCDwRK6dzWYYsyL5vQJD1Pto70nk6vtrffm\nkSOqYm0PwLWHuXd4gvQuXlqnR0WUfQTEFMoG8iVGM21yfABmtawkykHXRtEsr6/d\nHxuD+B43gYZKKfPR3Rf9M8Da2RmQ4H98Lk070cX5AgMBAAGjODA2MAwGA1UdEwEB\n/wQCMAAwDgYDVR0PAQH/BAQDAgeAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMCMA0G\nCSqGSIb3DQEBBQUAA4IBAQCvUpnPb1dhjJm0zSXXHa7m1Ti/tid/0tfRjS51esFu\n2DmsI9uUzQukRQzZXLKxqHbVUdAI2RAOg5i7GStlkvniXomPVcU6fYiYsdBGEah2\n6LNMiSja0/F7cA1qpWBCekJuN9nCEd75bwLHiVVCDK6su7EXzLQn7NZGpeDiCQhv\n8tYOdyg9ArdZMflMihpBZ5LJbuZYH4OhheDc9vnnZ5+klqghL6ixcqg/zIAHVGEi\nqIQim7ZSnkNxHLEYtlUhHiuYOoF5dKqYLeudYp0esNDgW15gv8sJ7f20Br2cldEc\nR7GG1M+sM55z/55LjdDg9GCb3d0jVR9sk8DMMGh8q+MO\n-----END CERTIFICATE-----\n"
}''';
