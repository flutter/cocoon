// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart' as test;

import 'package:app_flutter/build_dashboard.dart';
import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/service/fake_cocoon.dart';
import 'package:app_flutter/state/flutter_build.dart';

void main() {
  group('UserAvatar', () {
    GoogleSignInService authService;

    setUp(() {
      authService = MockGoogleSignInService();
    });

    testWidgets('shows sign in button when not signed in',
        (WidgetTester tester) async {
      when(authService.isAuthenticated).thenReturn(false);
      final FlutterBuildState buildState = FlutterBuildState(
          authService: authService, cocoonService: FakeCocoonService());
      await tester.pumpWidget(MaterialApp(
        home: SignInButton(
          buildState: buildState,
        ),
      ));

      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('sign in button activates google sign in when pressed',
        (WidgetTester tester) async {
      when(authService.isAuthenticated).thenReturn(false);
      final FlutterBuildState buildState = FlutterBuildState(
          authService: authService, cocoonService: FakeCocoonService());
      await tester.pumpWidget(MaterialApp(
        home: SignInButton(
          buildState: buildState,
        ),
      ));

      verifyNever(authService.signIn());

      await tester.tap(find.byType(GoogleUserCircleAvatar));

      verify(authService.signIn()).called(1);
    });

    testWidgets('shows user avatar when signed in',
        (WidgetTester tester) async {
      when(authService.isAuthenticated).thenReturn(true);
      when(authService.user).thenReturn(null);
      final FlutterBuildState buildState = FlutterBuildState(
          authService: authService, cocoonService: FakeCocoonService());
      await tester.pumpWidget(MaterialApp(
        home: SignInButton(
          buildState: buildState,
        ),
      ));

      expect(tester.takeException(),
          const test.TypeMatcher<NetworkImageLoadException>());
      expect(find.byType(Image), findsOneWidget);
    });
  });
}

/// Mock [GoogleSignInService] for testing interactions.
class MockGoogleSignInService extends Mock implements GoogleSignInService {}
