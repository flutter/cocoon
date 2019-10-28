// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:app_flutter/service/authentication.dart';
import 'package:google_sign_in_all/google_sign_in_all.dart';

/// Authentication service class for authenticating with Google Sign In.
class GoogleAuthenticationService implements AuthenticationService {
  GoogleAuthenticationService({GoogleSignIn googleSignIn})
      : _googleSignIn = googleSignIn ??
            setupGoogleSignIn(
              scopes: <String>[
                'https://www.googleapis.com/auth/userinfo.email',
                'https://www.googleapis.com/auth/userinfo.profile',
              ],
              webClientId:
                  '308150028417-vlj9mqlm3gk1d03fb0efif1fu5nagdtt.apps.googleusercontent.com',
            );

  // TODO(chillers): Switch to official Flutter plugin when it supports web.
  final GoogleSignIn _googleSignIn;

  AuthCredentials _credentials;

  GoogleAccount _user;

  @override
  bool get isAuthenticated => _credentials?.accessToken != null;

  @override
  String get avatarUrl => _user?.photoUrl;

  @override
  String get email => _user?.email;

  @override
  String get accessToken => _credentials?.accessToken;

  @override
  Future<void> signIn() async {
    _credentials = await _googleSignIn.signIn();
    _user = await _googleSignIn.getCurrentUser();
  }
}
