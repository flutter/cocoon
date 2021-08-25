// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_dashboard/service/google_authentication.dart';
import 'package:flutter_dashboard/widgets/now.dart';
import 'package:flutter_dashboard/widgets/state_provider.dart';

import 'fake_build.dart';
import 'fake_index_state.dart';
import 'mocks.dart';

class FakeInserter extends StatelessWidget {
  const FakeInserter({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final GoogleSignInService authService = MockGoogleSignInService();
    return StateProvider(
      signInService: authService,
      indexState: FakeIndexState(authService: authService),
      buildState: FakeBuildState(authService: authService),
      child: Now.fixed(
        dateTime: DateTime.utc(2000),
        child: child,
      ),
    );
  }
}
