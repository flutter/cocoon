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

    return idToken;
  }

  /// Initiate the Google Sign In process.
  Future<void> signInWithGoogle() async {
    try {
      final userCredential = await _auth.signInWithPopup(GoogleAuthProvider());
      _user = userCredential.user;
      notifyListeners();
    } catch (error) {
      debugPrint('signin failed: $error');
    }
  }

  /// Initiate the GitHub Sign In process.
  Future<void> signInWithGithub() async {
    try {
      final userCredential = await _auth.signInWithPopup(GithubAuthProvider());
      _user = userCredential.user;
    } catch (error) {
      // If email of Github account already registered in Frebase but with
      // Google provider, we need to sign in with Google provider first,
      // then link the GitHub provider to Google provider.
      if (error is FirebaseAuthException &&
          error.code == 'account-exists-with-different-credential') {
        await signInWithGoogle();
        await linkWithGithub();
        return;
      }
      debugPrint('signin with github failed: $error');
    }
    notifyListeners();
  }

  /// Sign out the currently signed in user.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
    } catch (error) {
      debugPrint('signout error $error');
    }
    notifyListeners();
  }

  Future<void> linkWithGoogle() async {
    // We want to have Googole account Primary if present, so we try to:
    // 1. Delete GitHub account from firebase records, but to avoid
    //    **requires-recent-login** error we need to re-sign-in first;
    try {
      await signOut();
      await signInWithGithub();
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      debugPrint('delete user failed: $e');
      return;
    }

    // 2. sign in with Google;
    try {
      await signInWithGoogle();
    } catch (error) {
      debugPrint('signInWithGoogle failed: $error');
      return;
    }

    // 3. then link GitHub account to existing Google account.
    try {
      await linkWithGithub();
    } catch (error) {
      debugPrint('linkWithGoogle failed: $error');
    }
  }

  /// Link the Github provider to the currently signed in user.
  Future<void> linkWithGithub() async {
    try {
      final userCredential = await _auth.currentUser?.linkWithPopup(
        GithubAuthProvider(),
      );
      _user = userCredential?.user;
      debugPrint(await _auth.currentUser?.getIdToken(true));
    } catch (error) {
      debugPrint('linkWithGithub failed: $error');
      //
    }
    notifyListeners();
  }

  /// Unlink the Github provider from the currently signed in user.
  Future<void> unlinkGithub() async {
    // Since we try to keep google acount as primary but primary authentication
    // provider is github, after unlinking github we have to delete google
    // account and re-signin with github.
    // 1. Unlink github provider
    final provider = GithubAuthProvider();
    try {
      _user = await _auth.currentUser?.unlink(provider.providerId);
    } catch (error) {
      debugPrint('unlink ${provider.runtimeType} failed: $error');
      return;
    }

    // 2. Delete Google account from firebase records, but to avoid
    //    **requires-recent-login** error we need to re-sign-in first;
    try {
      await signOut();
      await signInWithGoogle();
      await _auth.currentUser?.delete();
    } catch (e) {
      debugPrint('delete user failed: $e');
      return;
    }

    // 3. sign in with Github;
    try {
      await signOut();
      await signInWithGithub();
    } catch (error) {
      debugPrint('signInWithGithub failed: $error');
    }
  }

  /// Unlink the Google provider from the currently signed in user.
  Future<void> unlinkGoogle() async {
    final provider = GoogleAuthProvider();
    try {
      _user = await _auth.currentUser?.unlink(provider.providerId);
    } catch (error) {
      debugPrint('unlink ${provider.runtimeType} failed: $error');
      return;
    }
    debugPrint(await _user?.getIdToken(true));
    notifyListeners();
  }

  /// Clears the active user from the service, without calling signOut on the plugin.
  ///
  /// This refreshes the UI of the app, while making it easy for users to re-login.
  Future<void> clearUser() async {
    _user = null;
    notifyListeners();
  }
}
