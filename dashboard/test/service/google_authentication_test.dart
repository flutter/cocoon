// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dashboard/service/firebase_auth.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../utils/fake_firebase_user.dart';
import '../utils/mocks.dart';

void main() {
  group('FirebaseAuthService not signed in', () {
    late FirebaseAuthService authService;
    late MockFirebaseAuth mockSignIn;

    setUp(() {
      mockSignIn = MockFirebaseAuth();
      when(
        mockSignIn.authStateChanges(),
      ).thenAnswer((_) => const Stream<User>.empty());
      authService = FirebaseAuthService(auth: mockSignIn);
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
  });

  group('FirebaseAuthService sign in', () {
    late FirebaseAuthService authService;
    late MockFirebaseAuth mockSignIn;
    late StreamController<User> userChanged;

    final testAccount = FakeFirebaseUser();

    // Pushes a change to the userChanged Stream controller that we can await for it to propagate.
    Future<void> pushUserChanged(User? account) {
      userChanged.add(testAccount);
      // Let the change to the stream propagate to the object...
      return Future<void>.delayed(Duration.zero);
    }

    setUp(() {
      userChanged = StreamController<User>.broadcast();

      mockSignIn = MockFirebaseAuth();
      when(
        // ignore: discarded_futures
        mockSignIn.signInWithPopup(any),
      ).thenAnswer((_) async => MockUserCredential());
      when(mockSignIn.authStateChanges()).thenAnswer((_) => userChanged.stream);

      authService = FirebaseAuthService(auth: mockSignIn);
    });

    test('is authenticated after sign in from Google Sign In button', () async {
      await pushUserChanged(testAccount);

      expect(authService.isAuthenticated, isTrue);
      expect(authService.user, testAccount);
    });

    test('id token available with logged in user', () async {
      testAccount.tokens.add('abc1234');
      await pushUserChanged(testAccount);

      expect(await authService.idToken, 'abc1234');
    });
  });
}
