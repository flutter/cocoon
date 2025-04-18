// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../service/firebase_auth.dart';
import '../state/build.dart';

class StateProvider extends StatelessWidget {
  const StateProvider({
    super.key,
    this.signInService,
    this.buildState,
    this.child,
  });

  final FirebaseAuthService? signInService;

  final BuildState? buildState;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <ValueProvider<Object?>>[
        ValueProvider<FirebaseAuthService?>(value: signInService),
        ValueProvider<BuildState?>(value: buildState),
      ],
      child: child,
    );
  }
}

/// Similar to Provider.value but doesn't complain when
/// the value is a Listenable.
class ValueProvider<T> extends InheritedProvider<T> {
  ValueProvider({
    super.key,
    required super.value,
    super.updateShouldNotify,
    super.child,
  }) : super.value();
}
