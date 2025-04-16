// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier, debugPrint;

/// Service class for interacting with Google Sign In authentication for Cocoon backend.
///
/// Almost all operations with the plugin can throw an exception and should be caught
/// to prevent this service from crashing.
class FirebaseAuthService extends ChangeNotifier {
  final FirebaseAuth _auth;
  User? _user;

  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (_user == null) {
        print('user signed out');
      } else {
        print('user signed in');
      }
      notifyListeners();
    });
  }

  User? get user {
    return _user;
  }

  /// Whether or not the application has been signed in to.
  ///
  /// If the plugin fails, default to unauthenticated.
  bool get isAuthenticated {
    return _user != null;
  }

  /// Authentication token to be sent to Cocoon Backend to verify API calls.
  Future<String> get idToken async {
    assert(
      isAuthenticated,
      'Ensure user isAuthenticated before requesting an idToken.',
    );

    final idToken = await _user?.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('invalid idToken');
    }
    GoogleAuthProvider();

    return idToken;
  }

  /// Initiate the Google Sign In process.
  Future<void> signIn() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'login_hint': 'user@example.com'});
      await _auth.signInWithPopup(googleProvider);
      notifyListeners();
    } catch (error) {
      debugPrint('signin failed: $error');
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (error) {
      debugPrint('signout error $error');
    }
  }

  /// Clears the active user from the service, without calling signOut on the plugin.
  ///
  /// This refreshes the UI of the app, while making it easy for users to re-login.
  Future<void> clearUser() async {
    _user = null;
    notifyListeners();
  }
}
