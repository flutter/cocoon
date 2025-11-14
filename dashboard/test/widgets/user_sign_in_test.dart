// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dashboard/service/firebase_auth.dart';
import 'package:flutter_dashboard/widgets/state_provider.dart';
import 'package:flutter_dashboard/widgets/user_sign_in.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../utils/fake_firebase_user.dart';
import '../utils/golden.dart';
import '../utils/mocks.dart';

final Widget testApp = MaterialApp(
  theme: ThemeData(useMaterial3: false),
  home: Scaffold(appBar: AppBar(actions: const <Widget>[UserSignIn()])),
);

void main() {
  late MockFirebaseAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockFirebaseAuthService();
  });

  tearDown(() {
    clearInteractions(mockAuthService);
  });

  testWidgets('SignInButton shows sign in when not authenticated', (
    WidgetTester tester,
  ) async {
    when(mockAuthService.isAuthenticated).thenReturn(false);
    when(mockAuthService.user).thenReturn(null);

    await tester.pumpWidget(
      ValueProvider<FirebaseAuthService?>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('test@flutter.dev'), findsNothing);
    await expectGoldenMatches(
      find.byType(Overlay),
      'sign_in_button.not_authenticated.png',
    );
  });

  testWidgets('SignInButton calls sign in on tap when not authenticated', (
    WidgetTester tester,
  ) async {
    when(mockAuthService.isAuthenticated).thenReturn(false);
    when(mockAuthService.user).thenReturn(null);

    await tester.pumpWidget(
      ValueProvider<FirebaseAuthService?>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    verifyNever(mockAuthService.signInWithGithub());
    await tester.tap(find.text('SIGN IN'));
    await tester.pump();

    verify(mockAuthService.signInWithGithub()).called(1);
  });

  testWidgets('SignInButton shows avatar when authenticated', (
    WidgetTester tester,
  ) async {
    when(mockAuthService.isAuthenticated).thenReturn(true);

    final user = FakeFirebaseUser();
    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      ValueProvider<FirebaseAuthService?>(
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

  testWidgets('SignInButton calls sign out on tap when authenticated', (
    WidgetTester tester,
  ) async {
    when(mockAuthService.isAuthenticated).thenReturn(true);

    final user = FakeFirebaseUser();
    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      ValueProvider<FirebaseAuthService?>(
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

  testWidgets('SignInButton let link google account when authenticated', (
    WidgetTester tester,
  ) async {
    when(mockAuthService.isAuthenticated).thenReturn(true);

    final user = FakeFirebaseUser();
    user.providerData.add(
      UserInfo.fromJson({
        'providerId': GithubAuthProvider.PROVIDER_ID,
        'uid': 'qwerty12345',
        'isAnonymous': false,
        'isEmailVerified': true,
      }),
    );

    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      ValueProvider<FirebaseAuthService?>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(UserSignIn));
    await tester.pumpAndSettle();

    verifyNever(mockAuthService.linkWithGoogle());

    await tester.tap(find.text('Link Google Account'));

    verify(mockAuthService.linkWithGoogle()).called(1);
  });

  testWidgets('SignInButton let link github account when authenticated', (
    WidgetTester tester,
  ) async {
    when(mockAuthService.isAuthenticated).thenReturn(true);

    final user = FakeFirebaseUser();
    user.providerData.add(
      UserInfo.fromJson({
        'providerId': GoogleAuthProvider.PROVIDER_ID,
        'uid': 'qwerty12345',
        'isAnonymous': false,
        'isEmailVerified': true,
      }),
    );

    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      ValueProvider<FirebaseAuthService?>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(UserSignIn));
    await tester.pumpAndSettle();

    verifyNever(mockAuthService.linkWithGithub());

    await tester.tap(find.text('Link GitHub Account'));

    verify(mockAuthService.linkWithGithub()).called(1);
  });

  testWidgets('SignInButton let unlink google account when linked', (
    WidgetTester tester,
  ) async {
    when(mockAuthService.isAuthenticated).thenReturn(true);

    final user = FakeFirebaseUser();
    user.providerData.add(
      UserInfo.fromJson({
        'providerId': GithubAuthProvider.PROVIDER_ID,
        'uid': 'qwerty12345',
        'isAnonymous': false,
        'isEmailVerified': true,
      }),
    );
    user.providerData.add(
      UserInfo.fromJson({
        'providerId': GoogleAuthProvider.PROVIDER_ID,
        'uid': 'asdfgh67890',
        'isAnonymous': false,
        'isEmailVerified': true,
      }),
    );

    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      ValueProvider<FirebaseAuthService?>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(UserSignIn));
    await tester.pumpAndSettle();

    verifyNever(mockAuthService.unlinkGoogle());

    await tester.tap(find.text('Unlink Google Account'));

    verify(mockAuthService.unlinkGoogle()).called(1);
  });

  testWidgets('SignInButton let unlink github account when linked', (
    WidgetTester tester,
  ) async {
    when(mockAuthService.isAuthenticated).thenReturn(true);

    final user = FakeFirebaseUser();
    user.providerData.add(
      UserInfo.fromJson({
        'providerId': GoogleAuthProvider.PROVIDER_ID,
        'uid': 'qwerty12345',
        'isAnonymous': false,
        'isEmailVerified': true,
      }),
    );
    user.providerData.add(
      UserInfo.fromJson({
        'providerId': GithubAuthProvider.PROVIDER_ID,
        'uid': 'asdfgh67890',
        'isAnonymous': false,
        'isEmailVerified': true,
      }),
    );

    when(mockAuthService.user).thenReturn(user);

    await tester.pumpWidget(
      ValueProvider<FirebaseAuthService?>(
        value: mockAuthService,
        child: testApp,
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(UserSignIn));
    await tester.pumpAndSettle();

    verifyNever(mockAuthService.unlinkGithub());

    await tester.tap(find.text('Unlink GitHub Account'));

    verify(mockAuthService.unlinkGithub()).called(1);
  });
}
