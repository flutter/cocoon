// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;

import 'firebase_auth.dart' show FirebaseAuthService;

/// A FirebaseAuthService, used only in integration testing.
class FakeFirebaseAuthService extends ChangeNotifier
    implements FirebaseAuthService {
  User? _user;

  @override
  Future<void> clearUser() async {
    _user = null;
    notifyListeners();
  }

  @override
  bool get isAuthenticated {
    return _user != null;
  }

  @override
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

  @override
  Future<void> linkWithGithub() async {
    notifyListeners();
  }

  @override
  Future<void> linkWithGoogle() async {
    notifyListeners();
  }

  @override
  Future<void> signInWithGithub() async {
    _user = FakeUser(displayName: 'Fake GitHub User');
    notifyListeners();
  }

  @override
  Future<void> signInWithGoogle() async {
    _user = FakeUser(displayName: 'Fake Google User');
    notifyListeners();
  }

  @override
  Future<void> signOut() async {
    _user = null;
    notifyListeners();
  }

  @override
  Future<void> unlinkGithub() async {
    notifyListeners();
  }

  @override
  Future<void> unlinkGoogle() async {
    notifyListeners();
  }

  @override
  User? get user => _user;
}

class FakeUser implements User {
  @override
  final String? displayName;

  @override
  final String? email;

  @override
  final String uid;

  @override
  final String? photoURL;

  FakeUser({
    this.displayName = 'Fake User',
    this.email = 'fake@example.com',
    this.uid = 'fake_uid',
    this.photoURL = 'https://avatars.githubusercontent.com/u/270479282?v=4',
  });

  @override
  Future<void> delete() async {}

  @override
  bool get emailVerified => true;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    return 'fake_id_token';
  }

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async {
    throw UnimplementedError();
  }

  @override
  bool get isAnonymous => false;

  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) {
    throw UnimplementedError();
  }

  @override
  Future<ConfirmationResult> linkWithPhoneNumber(
    String phoneNumber, [
    RecaptchaVerifier? verifier,
  ]) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) {
    throw UnimplementedError();
  }

  @override
  Future<void> linkWithRedirect(AuthProvider provider) {
    throw UnimplementedError();
  }

  @override
  UserMetadata get metadata => throw UnimplementedError();

  @override
  MultiFactor get multiFactor => throw UnimplementedError();

  @override
  String? get phoneNumber => null;

  @override
  List<UserInfo> get providerData => <UserInfo>[];

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) {
    throw UnimplementedError();
  }

  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) {
    throw UnimplementedError();
  }

  @override
  String? get refreshToken => 'fake_refresh_token';

  @override
  Future<void> reload() async {}

  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async {}

  @override
  String? get tenantId => null;

  @override
  Future<User> unlink(String providerId) async {
    return this;
  }

  @override
  Future<void> updateDisplayName(String? displayName) async {}

  @override
  Future<void> updatePassword(String newPassword) async {}

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {}

  @override
  Future<void> updatePhotoURL(String? photoURL) async {}

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {}
}
