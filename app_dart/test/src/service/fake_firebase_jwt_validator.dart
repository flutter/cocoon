// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/google/token_info.dart';
import 'package:cocoon_service/src/service/firebase_jwt_validator.dart';
import 'package:jose_plus/src/jwk.dart';

class FakeFirebaseJwtValidator implements FirebaseJwtValidator {
  final jwts = <TokenInfo>[];

  @override
  Future<TokenInfo> decodeAndVerify(String jwtString) async {
    if (jwts.isEmpty) {
      throw JwtException('JWT invalid');
    }
    return jwts.removeAt(0);
  }

  @override
  JsonWebKeyStore get keyStore => throw UnimplementedError();

  @override
  Future<void> maybeRefreshKeyStore() {
    throw UnimplementedError();
  }
}
