// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/google/token_info.dart';
import 'package:test/test.dart';

void main() {
  group('TokenInfo', () {
    test('deserialize', () {
      final token = TokenInfo.fromJson(<String, dynamic>{
        'iss': 'issuer',
        'azp': 'authorizedParty',
        'aud': 'audience',
        'sub': 'subject',
        'hd': 'hostedDomain',
        'email': 'test@flutter.dev',
        'email_verified': 'true',
        'at_hash': 'accessTokenHash',
        'name': 'Test Flutter',
        'picture': 'http://example.org/123.jpg',
        'given_name': 'Test',
        'family_name': 'Flutter',
        'locale': 'en',
        'iat': '12345',
        'exp': '67890',
        'jti': 'jwtId',
        'alg': 'RSA',
        'kid': 'keyId',
        'typ': 'JWT',
      });
      expect(token.issuer, 'issuer');
      expect(token.authorizedParty, 'authorizedParty');
      expect(token.audience, 'audience');
      expect(token.subject, 'subject');
      expect(token.hostedDomain, 'hostedDomain');
      expect(token.email, 'test@flutter.dev');
      expect(token.emailIsVerified, isTrue);
      expect(token.accessTokenHash, 'accessTokenHash');
      expect(token.fullName, 'Test Flutter');
      expect(token.profilePictureUrl, 'http://example.org/123.jpg');
      expect(token.givenName, 'Test');
      expect(token.familyName, 'Flutter');
      expect(token.locale, 'en');
      expect(token.issued, DateTime.fromMillisecondsSinceEpoch(12345 * 1000));
      expect(
        token.expiration,
        DateTime.fromMillisecondsSinceEpoch(67890 * 1000),
      );
      expect(token.jwtId, 'jwtId');
      expect(token.algorithm, 'RSA');
      expect(token.keyId, 'keyId');
      expect(token.encoding, 'JWT');
    });
  });
}
