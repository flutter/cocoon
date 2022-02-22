// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues;
import 'package:google_sign_in/google_sign_in.dart';

class FakeGoogleSignInAccount implements GoogleSignInAccount {
  @override
  String get displayName => 'Dr. Test';

  @override
  String get email => 'test@flutter.dev';

  @override
  String get id => 'test123';

  @override
  String get photoUrl =>
      'https://lh3.googleusercontent.com/-ukEAtRyRhw8/AAAAAAAAAAI/AAAAAAAAAAA/ACHi3rfhID9XACtdb9q_xK43VSXQvBV11Q.CMID';

  @override
  String get serverAuthCode => 'migration placeholder';

  @override
  Future<Map<String, String>> get authHeaders => Future<Map<String, String>>.value(<String, String>{});

  @override
  late Future<GoogleSignInAuthentication> authentication;

  @override
  Future<void> clearAuthCache() => Future<void>.value(null);

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! GoogleSignInAccount) {
      return false;
    }
    final GoogleSignInAccount otherAccount = other;
    return displayName == otherAccount.displayName &&
        email == otherAccount.email &&
        id == otherAccount.id &&
        photoUrl == otherAccount.photoUrl &&
        serverAuthCode == otherAccount.serverAuthCode;
  }

  @override
  int get hashCode => hashValues(displayName, email, id, photoUrl, serverAuthCode);
}
