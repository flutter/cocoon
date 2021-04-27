// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'package:app_flutter/service/google_authentication.dart';
import 'package:app_flutter/widgets/now.dart';
import 'package:app_flutter/widgets/state_provider.dart';

import 'fake_agent_state.dart';
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
      agentState: FakeAgentState(authService: authService),
      buildState: FakeBuildState(authService: authService),
      child: Now.fixed(
        dateTime: DateTime.utc(2000),
        child: child,
      ),
    );
  }
}
