// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'cookie_interface.dart';

/// Service class for interacting with Google Sign In authentication for Cocoon backend.
class GoogleSignInService {
  /// Creates a new [GoogleSignIn].
  GoogleSignInService({GoogleSignIn googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: _googleScopes,
            ),
        cookieService = Cookie() {
    _googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount accountValue) {
      user = accountValue;
      notifyListeners();

      if (user != null) {
        user.authentication.then((GoogleSignInAuthentication auth) {
          cookieService.set('X-Flutter-IdToken', auth.idToken,
              options: 'path=/');
        });
      }
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

  /// Service for handling HTML cookies.
  ///
  /// Used to set the id token as a cookie so manual API requests can be made.
  final Cookie cookieService;

  /// Whether or not the application has been signed in to.
  Future<bool> get isAuthenticated => _googleSignIn.isSignedIn();

  /// The Google Account for the signed in user, null if no user is signed in.
  ///
  /// Read only object with only access to clear client auth tokens.
  GoogleSignInAccount user;

  /// Authentication token to be sent to Cocoon Backend to verify API calls.
  ///
  /// If there is no currently signed in user, it will prompt the sign in
  /// process before attempting to return an id token.
  Future<String> get idToken async {
    if (!await isAuthenticated) {
      await signIn();
    }

    final String idToken = await user?.authentication
        ?.then((GoogleSignInAuthentication key) => key.idToken);
    assert(idToken != null && idToken.isNotEmpty);

    return idToken;
  }

  /// Initiate the Google Sign In process.
  Future<void> signIn() async {
    user = await _googleSignIn.signIn();
    notifyListeners();
  }

  Future<void> signOut() async {
    user = await _googleSignIn.signOut();
    notifyListeners();
  }
}
