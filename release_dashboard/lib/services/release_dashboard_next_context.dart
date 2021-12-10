// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:file/file.dart' show File;
import 'package:flutter/material.dart';

import '../widgets/progression.dart' show DialogPromptChanger;

/// Service class for using [NextContext] in the local release dashboard environment.
class ReleaseDashboardNextContext extends NextContext {
  ReleaseDashboardNextContext({
    required bool autoAccept,
    required bool force,
    required Checkouts checkouts,
    required File stateFile,
    required this.syncStatusWithState,
    required this.dialogPromptChanger,
  }) : super(
          autoAccept: autoAccept,
          force: force,
          checkouts: checkouts,
          stateFile: stateFile,
        );

  final VoidCallback syncStatusWithState;
  final DialogPromptChanger dialogPromptChanger;

  /// Update the release's state file based on the current progression.
  ///
  /// Sync the release status with the state after the update.
  @override
  void updateState(pb.ConductorState state, [List<String> logs = const <String>[]]) {
    super.updateState(state, logs);
    syncStatusWithState();
  }

  @override
  Future<bool> prompt(String message) async {
    final Completer<bool> completer = Completer<bool>();
    dialogPromptChanger(message, completer);
    return completer.future;
  }
}
