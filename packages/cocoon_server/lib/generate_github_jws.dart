// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:jose_plus/jose.dart';
import 'package:meta/meta.dart';

/// Generates a Json Web Signature token to prove to GitHub we are [githubAppId].
String generateGitHubJws({
  required String privateKeyPem,
  required String githubAppId,
  @visibleForTesting DateTime? now,
}) {
  // Load the signing key
  final signingKey = JsonWebKey.fromPem(privateKeyPem);

  // Calculate times used for claims.
  now ??= DateTime.now();
  final iat =
      now.millisecondsSinceEpoch ~/
      1000; // Issued at time (seconds since epoch)
  final exp =
      now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/
      1000; // Expiration time (seconds since epoch)

  // Get the builder and add claims
  final builder = JsonWebSignatureBuilder();
  builder.jsonContent = JsonWebTokenClaims.fromJson({
    'iss': githubAppId,
    'iat': iat,
    'exp': exp,
  });

  // Sign it
  builder.addRecipient(signingKey);
  return builder.build().toCompactSerialization();
}
