// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/generate_github_jws.dart';
import 'package:jose_plus/jose.dart';
import 'package:test/test.dart';

void main() {
  test('generates a signed json web token', () async {
    final now = DateTime(2025, 04, 28, 8, 0);

    final tokenString = generateGitHubJws(
      privateKeyPem: testKeyPem,
      githubAppId: 'abc123',
      now: now,
    );

    final key = JsonWebKey.fromPem(testKeyPem);
    final publicKey = JsonWebKey.fromCryptoKeys(
      publicKey: key.cryptoKeyPair.publicKey,
    );
    final keyStore = JsonWebKeyStore()..addKey(publicKey);

    final jwt = await JsonWebToken.decodeAndVerify(tokenString, keyStore);
    final claims = jwt.claims;
    expect(claims.issuedAt, now);
    expect(claims.expiry, now.add(const Duration(minutes: 10)));
    expect('${claims.issuer}', 'abc123');
  });
}

/// This is a random RSA 2048 test key and should not be used for anything else.
const testKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQC309JyNJthKTto
Bk18X3ECr4jQoQvZu9c3/B4plTU+a3eGX3sYvDG4V91HZmFdW+boHoK539dvvGhq
Ox8TTbqY3AnxVCyheokao/+2PUXKNlc65TlpWqr8hhC3wuBuZWPxuekJzZrV7QoB
UuZM7eAhgZF2s//sX/YGpDIRNiTdPel8r7N2WejEZxW4mWG3O8LfUiXLHhNdSe01
/z+/Ka40waqQGwoOEdrELC5CyZIdI7NRHFJ4cqvtJ9rEtgzO0PU6mmTXx1PwPqq3
MftXmiDZhwcvDU1gv8Xzo5eZ17W2ftnfTmjIc7mYpovF5drv0BgSg9vnPOpXAcPE
n7PoQ1V5AgMBAAECggEAArAdmzHRpaaZpxGe24SAlZMYF2yKwhwqVK1HynXzXXvA
N4t+SawtzMXhzHqZePOgMUZ0mk/E5GNp7PIQnXgFCZlqaU2WFKXjAEFZOr1TtQtd
SZU4D9DwNV6nUFfl2iNle4TrXLX1j27RVxfdhM7eeJWeuTCUW6ItvybdPGMb6qK9
KG6wxuj6YZFQnhfhZP5r7PnilVrT70z11ucxkUwIpwoKe9gKBc8xBBqc+2Qw8D3P
ObtwGv9PTIlLx1jc9KXl+bg1kOWRVMS1fpShivFbvm0lz7XXx68IwSxg2fhQabgg
K+zoYnqrtmkKsaQEmjMoBXXmXv5OQtP/gs3PfwqPYQKBgQD9oDqRMYoKZ3Eca0JQ
bDAgVz8ONDlOimPHG+r/M3JS28LEH/sI//vSRVbxwLYTjFAkKxDaSaYbcaXmyNGq
1boXQu9g0wAL8733Hh3UUvuLiSMTgvMW3CiW/tQDL0yCOeLWPPZNV6o08CV1kw55
0oGDq7xnq5Hf04mGpYpb/6KGoQKBgQC5jFVJvAL7XoW/OSYvDrK+G571YCzrhmyb
Np7+6MQSGQqajk5SdmdKgDNvxqE21XXP8RLZHfVYyoMD8NtdGxa5BpyuQpBYStqM
AX9r6Os0AmcdxiE6X41N9MOkCj1FfNgPr7l/cAP1v7u63X0Nxla5XpMM1UWo04VT
wkm+167X2QKBgQDueZhYKVJ4kecDJ79Ey1U9M4vwmR5BQVKsRw3hQ8h9LHGn48Ix
JjDr95LW4bLSEp7QQ0YnWhS7vVKW+8BZd3jwollem0dx9Y9rKoA1wokPHLVEhV54
4i2wPI+xJuozkKY/dzbIZmN+P0eZk9qKpWpuGi6e8+3Hnam0VzcPZgC1wQKBgHOM
tixl/oFmOup7/5B8mcmUT+jFTRQbsZTzbg6XDEus9pKLnrDx9Z9KuT2ZuBn60xR9
L9ywMHNsIi0ZGLMhxIPTX02SPGwPqYxY/m5ILflEqcy770N37/qlPBTzH3cfqToT
l/SJ4J1xGsrjVhZ29tkX0YHDa08Y8sXXj69eiA75AoGBAMZi3u/gsNULJcoXkRSu
jmAhOGj5YThvLIL7RdZQZQ3R76BTKHXg8Us8RjIaAG7xpHrf3vDWMzn4O/ByvJ09
xdoQ3VGeZRfMZcdoip3i9at1KSUAIq1HuDiEZR4G5+jMExFJBCEAeN3WV9wx+QUJ
XkwJjkpDPRiZILdY2vkk4Dqw
-----END PRIVATE KEY-----
''';
