// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:app_flutter/service/google_authentication.dart';

import '../utils/fake_google_account.dart';
import '../utils/mocks.dart';

void main() {
  group('GoogleSignInService not signed in', () {
    GoogleSignInService authService;
    GoogleSignIn mockSignIn;

    setUp(() {
      mockSignIn = MockGoogleSignInPlugin();
      when(mockSignIn.onCurrentUserChanged).thenAnswer((_) => const Stream<GoogleSignInAccount>.empty());
      when(mockSignIn.isSignedIn()).thenAnswer((_) => Future<bool>.value(false));
      authService = GoogleSignInService(googleSignIn: mockSignIn);
    });

    tearDown(() {
      clearInteractions(mockSignIn);
    });

    test('not authenticated', () async {
      expect(await authService.isAuthenticated, false);
    });

    test('no user information', () {
      expect(authService.user, null);
    });

    test('sign in silently called', () async {
      verify(mockSignIn.signInSilently()).called(1);
    });

    test('id token will prompt sign in', () async {
      final GoogleSignInAccount testAccountWithAuthentication = FakeGoogleSignInAccount()
        ..authentication = Future<GoogleSignInAuthentication>.value(FakeGoogleSignInAuthentication());
      when(mockSignIn.signIn()).thenAnswer((_) => Future<GoogleSignInAccount>.value(testAccountWithAuthentication));

      verifyNever(mockSignIn.isSignedIn());
      verifyNever(mockSignIn.signIn());

      expect(await authService.idToken, 'id123');

      verify(mockSignIn.isSignedIn()).called(1);
      verify(mockSignIn.signIn()).called(1);
    });
  });

  group('GoogleSignInService sign in', () {
    GoogleSignInService authService;
    GoogleSignIn mockSignIn;

    final GoogleSignInAccount testAccount = FakeGoogleSignInAccount();

    setUp(() {
      mockSignIn = MockGoogleSignInPlugin();
      when(mockSignIn.signIn()).thenAnswer((_) => Future<GoogleSignInAccount>.value(testAccount));
      when(mockSignIn.currentUser).thenReturn(testAccount);
      when(mockSignIn.isSignedIn()).thenAnswer((_) => Future<bool>.value(true));
      when(mockSignIn.onCurrentUserChanged).thenAnswer((_) => const Stream<GoogleSignInAccount>.empty());

      authService = GoogleSignInService(googleSignIn: mockSignIn);
    });

    test('is authenticated after successful sign in', () async {
      await authService.signIn();

      expect(await authService.isAuthenticated, true);
      expect(authService.user, testAccount);
    });

    test('there is user information after successful sign in', () async {
      await authService.signIn();

      expect(authService.user.displayName, 'Dr. Test');
      expect(authService.user.email, 'test@flutter.dev');
      expect(authService.user.id, 'test123');
      expect(authService.user.photoUrl,
          'https://lh3.googleusercontent.com/-ukEAtRyRhw8/AAAAAAAAAAI/AAAAAAAAAAA/ACHi3rfhID9XACtdb9q_xK43VSXQvBV11Q.CMID');
    });

    test('id token available with logged in user', () async {
      final GoogleSignInAccount testAccountWithAuthentication = FakeGoogleSignInAccount()
        ..authentication = Future<GoogleSignInAuthentication>.value(FakeGoogleSignInAuthentication());
      authService.user = testAccountWithAuthentication;

      expect(await authService.idToken, 'id123');
    });

    test('is not authenticated after failure in sign in', () async {
      when(mockSignIn.signInSilently()).thenAnswer((_) => Future<GoogleSignInAccount>.value(null));
      when(mockSignIn.signIn()).thenAnswer((_) => Future<GoogleSignInAccount>.value(null));

      await authService.signIn();

      expect(authService.user, null);
    });
  });
}

class FakeGoogleSignInAuthentication implements GoogleSignInAuthentication {
  @override
  String get accessToken => 'access123';

  @override
  String get idToken => 'id123';

  @override
  String get serverAuthCode => 'serverAuth123';
}
