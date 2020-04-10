// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/widgets/sign_in_button.dart';
import 'package:app_flutter/widgets/state_provider.dart';

import '../utils/fake_google_account.dart';
import '../utils/mocks.dart';

final Widget testApp = MaterialApp(
  home: Scaffold(
    appBar: AppBar(
      actions: const <Widget>[
        SignInButton(),
      ],
    ),
  ),
);

void main() {
  GoogleSignInService mockAuthService;

  setUp(() {
    mockAuthService = MockGoogleSignInService();
  });

  tearDown(() {
    clearInteractions(mockAuthService);
  });

  testWidgets('SignInButton shows sign in when not authenticated', (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated).thenAnswer((_) async => Future<bool>.value(false));

    await tester.pumpWidget(
      ValueProvider<GoogleSignInService>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    expect(find.byType(GoogleUserCircleAvatar), findsNothing);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('test@flutter.dev'), findsNothing);
    await expectLater(find.byType(Overlay), matchesGoldenFile('sign_in_button.not_authenticated.png'));
  });

  testWidgets('SignInButton calls sign in on tap when not authenticated', (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated).thenAnswer((_) async => Future<bool>.value(false));

    await tester.pumpWidget(
      ValueProvider<GoogleSignInService>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    verifyNever(mockAuthService.signIn());

    await tester.tap(find.text('SIGN IN'));
    await tester.pump();

    verify(mockAuthService.signIn()).called(1);
  });

  testWidgets('SignInButton shows avatar when authenticated', (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated).thenAnswer((_) async => Future<bool>.value(true));

    final GoogleSignInAccount user = FakeGoogleSignInAccount();
    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      ValueProvider<GoogleSignInService>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    // TODO(chillers): look for GoogleUserCircleAvatar once we use that (see sign_in_button.dart)
    expect(find.text('SIGN IN'), findsNothing);
    expect(find.text('test@flutter.dev'), findsOneWidget);
    await expectLater(find.byType(Overlay), matchesGoldenFile('sign_in_button.authenticated.png'));
  });

  testWidgets('SignInButton calls sign out on tap when authenticated', (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated).thenAnswer((_) async => Future<bool>.value(true));

    final GoogleSignInAccount user = FakeGoogleSignInAccount();
    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      ValueProvider<GoogleSignInService>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(SignInButton));
    await tester.pumpAndSettle();

    verifyNever(mockAuthService.signOut());

    await tester.tap(find.text('Log out'));

    verify(mockAuthService.signOut()).called(1);
  });
}
