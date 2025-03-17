// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_dashboard/service/google_authentication.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

import '../utils/fake_google_account.dart';
import '../utils/mocks.dart';

void main() {
  group('GoogleSignInService not signed in', () {
    late GoogleSignInService authService;
    GoogleSignIn? mockSignIn;

    setUp(() {
      mockSignIn = MockGoogleSignIn();
      when(
        mockSignIn!.onCurrentUserChanged,
      ).thenAnswer((_) => const Stream<GoogleSignInAccount>.empty());
      when(
        // ignore: discarded_futures
        mockSignIn!.isSignedIn(),
      ).thenAnswer((_) => Future<bool>.value(false));
      when(
        // ignore: discarded_futures
        mockSignIn!.signInSilently(),
      ).thenAnswer((_) => Future<GoogleSignInAccount?>.value(null));
      authService = GoogleSignInService(googleSignIn: mockSignIn);
    });

    tearDown(() {
      clearInteractions(mockSignIn);
    });

    test('not authenticated', () async {
      expect(authService.isAuthenticated, false);
    });

    test('no user information', () {
      expect(authService.user, null);
    });

    test('sign in silently called', () async {
      verify(mockSignIn!.signInSilently()).called(1);
    });
  });

  group('GoogleSignInService sign in', () {
    late GoogleSignInService authService;
    late GoogleSignIn mockSignIn;
    late StreamController<GoogleSignInAccount> userChanged;

    final GoogleSignInAccount testAccount = FakeGoogleSignInAccount();

    // Pushes a change to the userChanged Stream controller that we can await for it to propagate.
    Future<void> pushUserChanged(GoogleSignInAccount? account) {
      userChanged.add(testAccount);
      // Let the change to the stream propagate to the object...
      return Future<void>.delayed(Duration.zero);
    }

    setUp(() {
      userChanged = StreamController<GoogleSignInAccount>.broadcast();

      mockSignIn = MockGoogleSignIn();
      when(
        // ignore: discarded_futures
        mockSignIn.signIn(),
      ).thenAnswer((_) => Future<GoogleSignInAccount>.value(testAccount));
      when(
        // ignore: discarded_futures
        mockSignIn.signInSilently(),
      ).thenAnswer((_) => Future<GoogleSignInAccount>.value(testAccount));
      when(mockSignIn.currentUser).thenReturn(testAccount);
      // ignore: discarded_futures
      when(mockSignIn.isSignedIn()).thenAnswer((_) => Future<bool>.value(true));
      when(
        mockSignIn.onCurrentUserChanged,
      ).thenAnswer((_) => userChanged.stream);

      authService = GoogleSignInService(googleSignIn: mockSignIn);
    });

    test('is authenticated after sign in from Google Sign In button', () async {
      await pushUserChanged(testAccount);

      expect(authService.isAuthenticated, isTrue);
      expect(authService.user, testAccount);
    });

    test('there is user information after successful sign in', () async {
      await pushUserChanged(testAccount);

      expect(authService.user, isNotNull);
      expect(authService.user!.displayName, 'Dr. Test');
      expect(authService.user!.email, 'test@flutter.dev');
      expect(authService.user!.id, 'test123');
      expect(
        authService.user!.photoUrl,
        'https://lh3.googleusercontent.com/-ukEAtRyRhw8/AAAAAAAAAAI/AAAAAAAAAAA/ACHi3rfhID9XACtdb9q_xK43VSXQvBV11Q.CMID',
      );
    });

    test('signIn method also works, but should be deprecated!', () async {
      await authService.signIn();

      expect(authService.isAuthenticated, true);
      expect(authService.user, testAccount);
    });

    test('id token available with logged in user', () async {
      final GoogleSignInAccount testAccountWithAuthentication =
          FakeGoogleSignInAccount()
            ..authentication = Future<GoogleSignInAuthentication>.value(
              FakeGoogleSignInAuthentication(),
            );
      authService.user = testAccountWithAuthentication;

      expect(await authService.idToken, 'id123');
    });

    test('is not authenticated after failure in sign in', () async {
      when(
        mockSignIn.signInSilently(),
      ).thenAnswer((_) => Future<GoogleSignInAccount?>.value(null));
      when(
        mockSignIn.signIn(),
      ).thenAnswer((_) => Future<GoogleSignInAccount?>.value(null));

      await authService.signIn();

      expect(authService.user, null);
    });

    test('clearUser removes the user without calling signOut', () async {
      await pushUserChanged(testAccount);

      expect(authService.isAuthenticated, isTrue);
      expect(authService.user, testAccount);

      await authService.clearUser();

      expect(authService.isAuthenticated, isFalse);
      expect(authService.user, isNull);
      verifyNever(mockSignIn.signOut());
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
