// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/state/index.dart';

import '../utils/mocks.dart';

void main() {
  testWidgets('IndexState sign in functions call notify listener',
      (WidgetTester tester) async {
    final MockGoogleSignInPlugin mockSignInPlugin = MockGoogleSignInPlugin();
    when(mockSignInPlugin.onCurrentUserChanged)
        .thenAnswer((_) => Stream<GoogleSignInAccount>.value(null));
    final GoogleSignInService signInService =
        GoogleSignInService(googleSignIn: mockSignInPlugin);
    final IndexState indexState = IndexState(authService: signInService);

    int callCount = 0;
    indexState.addListener(() => callCount++);

    // notify listener is called during construction of the state
    await tester.pump(const Duration(seconds: 5));
    expect(callCount, 1);

    await signInService.signIn();
    expect(callCount, 2);

    await signInService.signOut();
    expect(callCount, 3);
  });
}
