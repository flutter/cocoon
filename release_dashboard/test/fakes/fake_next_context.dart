// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/src/proto/conductor_state.pb.dart';
import 'package:conductor_ui/services/release_dashboard_next_context.dart';
import 'package:conductor_ui/widgets/progression.dart';
import 'package:file/file.dart';
import 'package:flutter/material.dart';

const String kFlutterRoot = '/flutter';
const String kCheckoutsParentDirectory = '$kFlutterRoot/dev/tools/';

/// Initializes a fake [ReleaseDashboardNextContext] in a fake local environment.
///
/// [runOverride] parameter overrides the parent's [run] method
class FakeNextContext implements ReleaseDashboardNextContext {
  FakeNextContext({
    this.runOverride,
  });

  /// An optional override async callback for the real [run] method.
  Future<void> Function()? runOverride;

  /// Either call [runOverride] if it is not null, else an empty function is called.
  @override
  Future<void> run(state) async {
    if (runOverride != null) {
      return runOverride!();
    }
  }

  @override
  bool get autoAccept => throw UnimplementedError();

  @override
  Checkouts get checkouts => throw UnimplementedError();

  @override
  bool get force => throw UnimplementedError();

  @override
  Future<bool> prompt(String message) {
    throw UnimplementedError();
  }

  @override
  File get stateFile => throw UnimplementedError();

  @override
  Stdio get stdio => throw UnimplementedError();

  @override
  void updateState(ConductorState state, [List<String> logs = const <String>[]]) {}

  @override
  VoidCallback get syncStatusWithState => throw UnimplementedError();

  @override
  DialogPromptChanger get dialogPromptChanger => throw UnimplementedError();
}
