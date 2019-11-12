// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:app_flutter/service/google_authentication.dart';

void main() {
  group('GoogleSignInService not signed in', () {
    GoogleSignInService authService;

    setUp(() {
      authService = GoogleSignInService(googleSignIn: MockGoogleSignIn());
    });

    test('not authenticated', () {
      expect(authService.isAuthenticated, false);
    });

    test('no user information', () {
      expect(authService.user, null);
      expect(authService.idToken, null);
    });
  });

  group('GoogleSignInService sign in', () {
    GoogleSignInService authService;
    GoogleSignIn mockSignIn;

    setUp(() {
      mockSignIn = MockGoogleSignIn();
      when(mockSignIn.signIn()).thenAnswer(
          (_) => Future<GoogleSignInAccount>.value(fakeCredentials));
      when(mockSignIn.currentUser).thenAnswer((_) =>
          Future<GoogleSignInAccount>.value(GoogleSignInAccount(
              email: 'fake@fake.com', photoUrl: 'fake://fake.png')));

      authService = GoogleSignInService(googleSignIn: mockSignIn);
    });

    test('is authenticated after successful sign in', () async {
      await authService.signIn();

      expect(authService.isAuthenticated, true);
    });

    test('there is user information after successful sign in', () async {
      await authService.signIn();

      expect(authService.idToken, 'fake id token');
    });

    test('is not authenticated after failure in sign in', () async {
      when(mockSignIn.signInSilently())
          .thenAnswer((_) => Future<GoogleSignInAccount>.value(null));
      when(mockSignIn.signIn())
          .thenAnswer((_) => Future<GoogleSignInAccount>.value(null));

      await authService.signIn();

      expect(authService.isAuthenticated, false);
      expect(authService.user, null);
      expect(authService.idToken, null);
    });
  });
}

/// Mock [GoogleSignIn] for testing interactions.
class MockGoogleSignIn extends Mock implements GoogleSignIn {}
