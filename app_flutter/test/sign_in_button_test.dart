// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart' as test;

import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/sign_in_button.dart';
import 'package:app_flutter/state/flutter_build.dart';

import 'utils/fake_google_account.dart';

void main() {
  GoogleSignInService mockAuthService;

  setUp(() {
    mockAuthService = MockGoogleSignInService();
  });

  tearDown(() {
    clearInteractions(mockAuthService);

    // Image.Network caches images which must be cleared.
    PaintingBinding.instance.imageCache.clear();
  });

  testWidgets('shows sign in when not authenticated',
      (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated)
        .thenAnswer((_) async => Future<bool>.value(false));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SignInButton(
          authService: mockAuthService,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(GoogleUserCircleAvatar), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('calls sign in on tap when not authenticated',
      (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated)
        .thenAnswer((_) async => Future<bool>.value(false));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SignInButton(
          authService: mockAuthService,
        ),
      ),
    );
    await tester.pump();

    verifyNever(mockAuthService.signIn());

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    verify(mockAuthService.signIn()).called(1);
  });

  testWidgets('shows avatar when authenticated', (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated)
        .thenAnswer((_) async => Future<bool>.value(true));

    final GoogleSignInAccount user = FakeGoogleSignInAccount();
    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      MaterialApp(
        home: AppBar(
          leading: SignInButton(
            authService: mockAuthService,
          ),
        ),
      ),
    );
    await tester.pump();
    // TODO(chillers): Remove this web check once issue is resolved. https://github.com/flutter/flutter/issues/44370
    if (!kIsWeb) {
      expect(tester.takeException(),
          const test.TypeMatcher<NetworkImageLoadException>());
    }

    expect(find.text('Sign in'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('calls sign out on tap when authenticated',
      (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated)
        .thenAnswer((_) async => Future<bool>.value(true));

    final GoogleSignInAccount user = FakeGoogleSignInAccount();
    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      MaterialApp(
        home: AppBar(
          leading: SignInButton(
            authService: mockAuthService,
          ),
        ),
      ),
    );
    await tester.pump();
    if (!kIsWeb) {
      expect(tester.takeException(),
          const test.TypeMatcher<NetworkImageLoadException>());
    }

    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();

    verifyNever(mockAuthService.signOut());

    await tester.tap(find.text('Log out'));

    verify(mockAuthService.signOut()).called(1);
  });
}

class MockFlutterBuildState extends Mock implements FlutterBuildState {}

class MockGoogleSignInService extends Mock implements GoogleSignInService {}
