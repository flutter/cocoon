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
  FlutterBuildState mockBuildState;
  GoogleSignInService mockSignIn;

  setUp(() {
    mockBuildState = MockFlutterBuildState();
    mockSignIn = MockGoogleSignInService();

    when(mockBuildState.authService).thenReturn(mockSignIn);
  });

  tearDown(() {
    clearInteractions(mockBuildState);
    clearInteractions(mockSignIn);
  });

  testWidgets('shows sign in when not authenticated',
      (WidgetTester tester) async {
    when(mockSignIn.isAuthenticated).thenReturn(false);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SignInButton(
          buildState: mockBuildState,
        ),
      ),
    );

    expect(find.byType(GoogleUserCircleAvatar), findsNothing);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('calls sign in on tap when not authenticated',
      (WidgetTester tester) async {
    when(mockSignIn.isAuthenticated).thenReturn(false);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SignInButton(
          buildState: mockBuildState,
        ),
      ),
    );

    verifyNever(mockBuildState.signIn());

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    verify(mockBuildState.signIn()).called(1);
  });

  testWidgets('shows avatar when authenticated', (WidgetTester tester) async {
    when(mockSignIn.isAuthenticated).thenReturn(true);

    final GoogleSignInAccount user = TestGoogleSignInAccount();
    when(mockSignIn.user).thenReturn(user);

    await tester.pumpWidget(
      MaterialApp(
        home: AppBar(
          leading: SignInButton(
            buildState: mockBuildState,
          ),
        ),
      ),
    );
    tester.takeException();

    expect(find.text('Sign in'), findsNothing);
    expect(find.byType(GoogleUserCircleAvatar), findsOneWidget);
  });

  testWidgets('calls sign out on tap when authenticated',
      (WidgetTester tester) async {});
}

class TestGoogleSignInAccount implements GoogleSignInAccount {
  @override
  String get displayName => 'Dr. Test';

  @override
  String get email => 'test@flutter.dev';

  @override
  String get id => 'test123';

  @override
  String get photoUrl => 'https://flutter.dev/test.png';

  @override
  Future<Map<String, String>> get authHeaders => null;

  @override
  Future<GoogleSignInAuthentication> get authentication => null;

  @override
  Future<void> clearAuthCache() => null;
}

class MockFlutterBuildState extends Mock implements FlutterBuildState {}

class MockGoogleSignInService extends Mock implements GoogleSignInService {}
