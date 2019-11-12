// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart' as test;

import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/sign_in_button.dart';
import 'package:app_flutter/state/flutter_build.dart';

void main() {
  GoogleSignInService mockAuthService;

  setUp(() {
    mockAuthService = MockGoogleSignInService();
  });

  tearDown(() {
    clearInteractions(mockAuthService);
  });

  testWidgets('shows sign in when not authenticated',
      (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated).thenReturn(false);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SignInButton(
          authService: mockAuthService,
        ),
      ),
    );

    expect(find.byType(GoogleUserCircleAvatar), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('calls sign in on tap when not authenticated',
      (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated).thenReturn(false);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SignInButton(
          authService: mockAuthService,
        ),
      ),
    );

    verifyNever(mockAuthService.signIn());

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    verify(mockAuthService.signIn()).called(1);
  });

  testWidgets('shows avatar when authenticated', (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated).thenReturn(true);

    final GoogleSignInAccount user = TestGoogleSignInAccount();
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
    expect(tester.takeException(),
        const test.TypeMatcher<NetworkImageLoadException>());

    expect(find.text('Sign in'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('calls sign out on tap when authenticated',
      (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated).thenReturn(true);

    final GoogleSignInAccount user = TestGoogleSignInAccount();
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
    expect(tester.takeException(),
        const test.TypeMatcher<NetworkImageLoadException>());

    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();

    verifyNever(mockAuthService.signOut());

    await tester.tap(find.text('Log out'));

    verify(mockAuthService.signOut()).called(1);
  });
}

class TestGoogleSignInAccount implements GoogleSignInAccount {
  @override
  String get displayName => 'Dr. Test';

  @override
  String get email => 'test@flutter.dev';

  @override
  String get id => 'test123';

  @override
  String get photoUrl =>
      'https://lh3.googleusercontent.com/-ukEAtRyRhw8/AAAAAAAAAAI/AAAAAAAAAAA/ACHi3rfhID9XACtdb9q_xK43VSXQvBV11Q.CMID';

  @override
  Future<Map<String, String>> get authHeaders => null;

  @override
  Future<GoogleSignInAuthentication> get authentication => null;

  @override
  Future<void> clearAuthCache() => null;
}

class MockFlutterBuildState extends Mock implements FlutterBuildState {}

class MockGoogleSignInService extends Mock implements GoogleSignInService {}
