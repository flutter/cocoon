// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_sign_in_all/google_sign_in_all.dart';

/// Service class for interacting with Google Sign In authentication for Cocoon backend.
class GoogleSignInService {
  /// Creates a new [GoogleSignIn].
  GoogleSignInService({GoogleSignIn googleSignIn})
      : _googleSignIn = googleSignIn ??
            setupGoogleSignIn(
              scopes: _googleScopes,
              webClientId:
                  '308150028417-vlj9mqlm3gk1d03fb0efif1fu5nagdtt.apps.googleusercontent.com',
            );

  /// A list of Google API OAuth Scopes this project needs access to.
  ///
  /// Currently, the project shows just basic user profile information
  /// when logged in.
  /// 
  /// See https://developers.google.com/identity/protocols/googlescopes
  static const List<String> _googleScopes = <String>[
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  // TODO(chillers): Switch to official Flutter plugin when it supports web.
  final GoogleSignIn _googleSignIn;

  AuthCredentials _credentials;

  GoogleAccount _user;

  /// Whether or not the application has been signed in to.
  bool get isAuthenticated => _credentials?.accessToken != null;

  /// The profile photo url of the current user signed in.
  String get avatarUrl => _user?.photoUrl;

  /// The email of the current user signed in.
  String get email => _user?.email;

  /// Authentication token to be sent to Cocoon Backend to verify API calls.
  String get accessToken => _credentials?.accessToken;

  /// Initiate the Google Sign In process.
  Future<void> signIn() async {
    _credentials = await _googleSignIn.signIn();
    _user = await _googleSignIn.getCurrentUser();
  }
}
