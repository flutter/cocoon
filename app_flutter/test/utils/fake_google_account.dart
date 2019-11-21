// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  Future<Map<String, String>> get authHeaders => null;

  @override
  Future<GoogleSignInAuthentication> authentication;

  @override
  Future<void> clearAuthCache() => null;
}
