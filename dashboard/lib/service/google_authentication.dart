// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service class for interacting with Google Sign In authentication for Cocoon backend.
///
/// Almost all operations with the plugin can throw an exception and should be caught
/// to prevent this service from crashing.
class GoogleSignInService extends ChangeNotifier {
  /// Creates a new [GoogleSignIn].
  GoogleSignInService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: _googleScopes,
            ) {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? accountValue) {
      user = accountValue;
      notifyListeners();
    });

    try {
      _googleSignIn.signInSilently();
    } on PlatformException catch (error) {
      debugPrint('GoogleSignIn error code: ${error.code}');
      debugPrint(error.message);
    }
  }

  /// A list of Google API OAuth Scopes this project needs access to.
  ///
  /// Currently, the project shows just basic user profile information
  /// when logged in.
  ///
  /// See https://developers.google.com/identity/protocols/googlescopes
  static const List<String> _googleScopes = <String>[];

  /// The instance of the GoogleSignIn plugin to use.
  final GoogleSignIn _googleSignIn;

  /// Whether or not the application has been signed in to.
  ///
  /// If the plugin fails, default to unauthenticated.
  Future<bool> get isAuthenticated async {
    return user != null;
  }

  /// The Google Account for the signed in user, null if no user is signed in.
  ///
  /// Read only object with only access to clear client auth tokens.
  GoogleSignInAccount? user;

  /// Authentication token to be sent to Cocoon Backend to verify API calls.
  ///
  /// If there is no currently signed in user, it will prompt the sign in
  /// process before attempting to return an id token.
  Future<String> get idToken async {
    if (!await isAuthenticated) {
      // This won't work unless it's triggered from an user onclick!
      await signIn();
    }

    final String idToken = (await user?.authentication.then((GoogleSignInAuthentication key) => key.idToken!))!;
    assert(idToken.isNotEmpty);

    return idToken;
  }

  /// Initiate the Google Sign In process.
  Future<void> signIn() async {
    try {
      user = await _googleSignIn.signIn();
      notifyListeners();
    } on PlatformException catch (error) {
      debugPrint('GoogleSignIn error code: ${error.code}');
      debugPrint(error.message);
    }
  }

  Future<void> signOut() async {
    try {
      user = await _googleSignIn.signOut();
      notifyListeners();
    } on PlatformException catch (error) {
      debugPrint('GoogleSignIn error code: ${error.code}');
      debugPrint(error.message);
    }
  }
}
