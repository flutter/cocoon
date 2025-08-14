// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth/firebase_auth.dart';

class FakeFirebaseUser implements User {
  @override
  Future<void> delete() {
    throw UnimplementedError();
  }

  @override
  String? get displayName => 'Dr. Test';

  @override
  String? get email => 'test@flutter.dev';

  @override
  bool get emailVerified => true;

  final tokens = <String>[];

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    if (tokens.isEmpty) return null;
    return tokens.removeAt(0);
  }

  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) {
    throw UnimplementedError();
  }

  @override
  bool get isAnonymous => throw UnimplementedError();

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
  String? get phoneNumber => '867-5309';

  @override
  String? get photoURL =>
      'https://lh3.googleusercontent.com/-ukEAtRyRhw8/AAAAAAAAAAI/AAAAAAAAAAA/ACHi3rfhID9XACtdb9q_xK43VSXQvBV11Q.CMID';

  @override
  List<UserInfo> get providerData => throw UnimplementedError();

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
  String? get refreshToken => throw UnimplementedError();

  @override
  Future<void> reload() {
    throw UnimplementedError();
  }

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) {
    throw UnimplementedError();
  }

  @override
  String? get tenantId => throw UnimplementedError();

  @override
  String get uid => throw UnimplementedError();

  @override
  Future<User> unlink(String providerId) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateDisplayName(String? displayName) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateEmail(String newEmail) {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePassword(String newPassword) {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) {
    throw UnimplementedError();
  }

  @override
  Future<void> updatePhotoURL(String? photoURL) {
    throw UnimplementedError();
  }

  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) {
    throw UnimplementedError();
  }

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) {
    throw UnimplementedError();
  }
}
