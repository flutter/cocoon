// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service class for interacting with Google Sign In authentication for Cocoon backend.
class GoogleSignInService {
  /// Creates a new [GoogleSignIn].
  GoogleSignInService({GoogleSignIn googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: _googleScopes,
            ) {
    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount accountValue) {
      user = accountValue;
      notifyListeners();
    });
    _googleSignIn.signInSilently();
  }

  /// A callback for notifying listeners there has been an update.
  VoidCallback notifyListeners;

  /// A list of Google API OAuth Scopes this project needs access to.
  ///
  /// Currently, the project shows just basic user profile information
  /// when logged in.
  ///
  /// See https://developers.google.com/identity/protocols/googlescopes
  static const List<String> _googleScopes = <String>[
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
    'openid',
  ];

  /// The instance of the GoogleSignIn plugin to use.
  final GoogleSignIn _googleSignIn;

  /// Whether or not the application has been signed in to.
  Future<bool> get isAuthenticated => _googleSignIn.isSignedIn();

  /// The Google Account for the signed in user.
  ///
  /// If any of the fields are null, the current session is not signed in.
  ///
  /// Read only object with only access to clear client auth tokens.
  GoogleSignInAccount user;

  /// Authentication token to be sent to Cocoon Backend to verify API calls.
  Future<String> get idToken => user?.authentication
      ?.then((GoogleSignInAuthentication key) => key.idToken);

  /// Initiate the Google Sign In process.
  Future<void> signIn() async {
    user = await _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    user = await _googleSignIn.signOut();
  }
}
