// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service class for interacting with Google Sign In authentication for Cocoon backend.
class GoogleSignInService {
  /// Creates a new [GoogleSignIn].
  GoogleSignInService({GoogleSignIn googleSignIn, this.notifyListeners})
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
  final VoidCallback notifyListeners;

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

  final GoogleSignIn _googleSignIn;

  /// Whether or not the application has been signed in to.
  bool get isAuthenticated => user != null;

  /// The Google Account for the signed in user
  ///
  /// Null if no user is signed in
  GoogleSignInAccount user;

  /// Authentication token to be sent to Cocoon Backend to verify API calls.
  Future<String> get idToken => user?.authentication
      ?.then((GoogleSignInAuthentication key) => key.idToken);

  /// Initiate the Google Sign In process.
  Future<void> signIn() async {
    user = await _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    user = null;
  }
}
