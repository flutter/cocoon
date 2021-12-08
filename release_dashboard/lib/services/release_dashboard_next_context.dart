// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:file/file.dart' show File;
import 'package:flutter/material.dart';

/// Service class for using [NextContext] in the local release dashboard environment.
class ReleaseDashboardNextContext extends NextContext {
  ReleaseDashboardNextContext({
    required bool autoAccept,
    required bool force,
    required Checkouts checkouts,
    required File stateFile,
    required this.syncStatusWithState,
  }) : super(
          autoAccept: autoAccept,
          force: force,
          checkouts: checkouts,
          stateFile: stateFile,
        );

  final VoidCallback syncStatusWithState;

  /// Update the release's state file based on the current progression.
  ///
  /// Sync the release status with the state after the update.
  @override
  void updateState(pb.ConductorState state, [List<String> logs = const <String>[]]) {
    super.updateState(state, logs);
    syncStatusWithState();
  }

  // TODO(Yugue): [release_dashboard] Add DialoguePrompt for all NextContext command,
  // https://github.com/flutter/flutter/issues/94222.
  @override
  Future<bool> prompt(String message) async {
    return true;
  }
}
