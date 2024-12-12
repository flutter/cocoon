// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_dashboard/service/google_authentication.dart';
import 'package:flutter_dashboard/widgets/state_provider.dart';
import 'package:flutter_dashboard/widgets/user_sign_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mockito/mockito.dart';

import '../utils/fake_google_account.dart';
import '../utils/golden.dart';
import '../utils/mocks.dart';

final Widget testApp = MaterialApp(
  theme: ThemeData(useMaterial3: false),
  home: Scaffold(
    appBar: AppBar(
      actions: const <Widget>[
        UserSignIn(),
      ],
    ),
  ),
);

void main() {
  late GoogleSignInService mockAuthService;

  setUp(() {
    mockAuthService = MockGoogleSignInService();
  });

  tearDown(() {
    clearInteractions(mockAuthService);
  });

  testWidgets('SignInButton shows sign in when not authenticated', (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated).thenReturn(false);
    when(mockAuthService.user).thenReturn(null);

    await tester.pumpWidget(
      ValueProvider<GoogleSignInService?>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    expect(find.byType(GoogleUserCircleAvatar), findsNothing);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('test@flutter.dev'), findsNothing);
    await expectGoldenMatches(find.byType(Overlay), 'sign_in_button.not_authenticated.png');
  });

  testWidgets('SignInButton calls sign in on tap when not authenticated', (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated).thenReturn(false);
    when(mockAuthService.user).thenReturn(null);

    await tester.pumpWidget(
      ValueProvider<GoogleSignInService?>(
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
    when(mockAuthService.isAuthenticated).thenReturn(true);

    final GoogleSignInAccount user = FakeGoogleSignInAccount();
    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      ValueProvider<GoogleSignInService?>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    // TODO(chillers): look for GoogleUserCircleAvatar once we use that (see sign_in_button.dart)
    expect(find.text('SIGN IN'), findsNothing);
    expect(find.text('test@flutter.dev'), findsOneWidget);
    // TODO(xu-baolin): Re-enable this ASAP.
    // Tracking at https://github.com/flutter/flutter/issues/73527
    // await expectGoldenMatches(find.byType(Overlay), 'sign_in_button.authenticated.png');
  });

  testWidgets('SignInButton calls sign out on tap when authenticated', (WidgetTester tester) async {
    when(mockAuthService.isAuthenticated).thenReturn(true);

    final GoogleSignInAccount user = FakeGoogleSignInAccount();
    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      ValueProvider<GoogleSignInService?>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(UserSignIn));
    await tester.pumpAndSettle();

    verifyNever(mockAuthService.signOut());

    await tester.tap(find.text('Log out'));

    verify(mockAuthService.signOut()).called(1);
  });
}
