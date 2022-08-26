// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_dashboard/widgets/now.dart';
import 'package:flutter_dashboard/widgets/state_provider.dart';
import 'package:mockito/mockito.dart';

import 'fake_build.dart';
import 'fake_google_account.dart';
import 'fake_index_state.dart';
import 'mocks.dart';

class FakeInserter extends StatelessWidget {
  const FakeInserter({super.key, this.child, this.signedIn = true});

  final Widget? child;

  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final MockGoogleSignInService fakeAuthService = MockGoogleSignInService();
    if (signedIn) {
      when(fakeAuthService.isAuthenticated).thenAnswer((_) => Future<bool>.value(true));
    } else {
      when(fakeAuthService.isAuthenticated).thenAnswer((_) => Future<bool>.value(false));
    }

    when(fakeAuthService.user).thenReturn(FakeGoogleSignInAccount());

    return StateProvider(
      signInService: fakeAuthService,
      indexState: FakeIndexState(authService: fakeAuthService),
      buildState: FakeBuildState(authService: fakeAuthService),
      child: Now.fixed(
        dateTime: DateTime.utc(2000),
        child: child!,
      ),
    );
  }
}
