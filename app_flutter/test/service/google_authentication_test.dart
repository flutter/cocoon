// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:google_sign_in_all/google_sign_in_all.dart';
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
      expect(authService.avatarUrl, null);
      expect(authService.email, null);
      expect(authService.accessToken, null);
    });
  });

  group('GoogleSignInService sign in', () {
    GoogleSignInService authService;
    GoogleSignIn mockSignIn;

    setUp(() {
      mockSignIn = MockGoogleSignIn();
      final AuthCredentials fakeCredentials = FakeAuthCredentials();
      when(mockSignIn.signIn())
          .thenAnswer((_) => Future<AuthCredentials>.value(fakeCredentials));
      when(mockSignIn.getCurrentUser()).thenAnswer((_) =>
          Future<GoogleAccount>.value(GoogleAccount(
              email: 'fake@fake.com', photoUrl: 'fake://fake.png')));

      authService = GoogleSignInService(googleSignIn: mockSignIn);
    });

    test('is authenticated after successful sign in', () async {
      await authService.signIn();

      expect(authService.isAuthenticated, true);
    });

    test('there is user information after successful sign in', () async {
      await authService.signIn();

      expect(authService.email, 'fake@fake.com');
      expect(authService.avatarUrl, 'fake://fake.png');
      expect(authService.accessToken, 'fake');
    });

    test('is not authenticated after failure in sign in', () async {
      when(mockSignIn.signIn())
          .thenAnswer((_) => Future<AuthCredentials>.value(null));
      when(mockSignIn.getCurrentUser())
          .thenAnswer((_) => Future<GoogleAccount>.value(null));

      await authService.signIn();

      expect(authService.isAuthenticated, false);
      expect(authService.email, null);
      expect(authService.avatarUrl, null);
      expect(authService.accessToken, null);
    });
  });
}

/// Mock [GoogleSignIn] for testing interactions.
class MockGoogleSignIn extends Mock implements GoogleSignIn {}

/// Fake [AuthCredentials] for [MockGoogleSignIn].
class FakeAuthCredentials implements AuthCredentials {
  @override
  final String accessToken = 'fake';

  @override
  final String idToken = 'faker';
}
