// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/index.dart';

void main() {
  group('IndexState', () {
    IndexState indexState;
    MockGoogleSignInService mockAuthService;

    setUp(() {
      mockAuthService = MockGoogleSignInService();
      indexState = IndexState(authServiceValue: mockAuthService);
    });

    tearDown(() {
      clearInteractions(mockAuthService);
    });

    testWidgets('auth functions forward to google sign in service', (WidgetTester tester) async {
      verifyNever(mockAuthService.signIn());
      verifyNever(mockAuthService.signOut());

      await indexState.signIn();

      verify(mockAuthService.signIn()).called(1);
      verifyNever(mockAuthService.signOut());

      await indexState.signOut();
      verify(mockAuthService.signOut()).called(1);
    });
  });

  testWidgets('sign in functions call notify listener', (WidgetTester tester) async {
    final MockGoogleSignInPlugin mockSignInPlugin = MockGoogleSignInPlugin();
    when(mockSignInPlugin.onCurrentUserChanged).thenAnswer((_) => Stream<GoogleSignInAccount>.value(null));
    final GoogleSignInService signInService = GoogleSignInService(googleSignIn: mockSignInPlugin);
    final IndexState indexState = IndexState(authServiceValue: signInService);

    int callCount = 0;
    indexState.addListener(() => callCount++);

    // notify listener is called during construction of the state
    await tester.pump(const Duration(seconds: 5));
    expect(callCount, 1);

    await indexState.signIn();
    expect(callCount, 2);

    await indexState.signOut();
    expect(callCount, 3);
  });
}

/// Mock for testing interactions with [GoogleSignInService].
class MockGoogleSignInService extends Mock implements GoogleSignInService {}

class MockGoogleSignInPlugin extends Mock implements GoogleSignIn {}
