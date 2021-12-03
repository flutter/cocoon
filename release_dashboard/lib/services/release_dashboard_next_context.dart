// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:file/file.dart' show File;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/status_state.dart';

/// Service class for using [NextContext] in the local release dashboard environment.
class ReleaseDashboardNextContext extends NextContext {
  ReleaseDashboardNextContext({
    required this.context,
    required bool autoAccept,
    required bool force,
    required Checkouts checkouts,
    required File stateFile,
  }) : super(
          autoAccept: autoAccept,
          force: force,
          checkouts: checkouts,
          stateFile: stateFile,
        );

  final BuildContext context;

  /// Update the release's state file based on the current progression.
  ///
  /// Sync the release status with the state after the update.
  @override
  void updateState(pb.ConductorState state, [List<String> logs = const <String>[]]) {
    super.updateState(state, logs);
    context.read<StatusState>().syncStatusWithState();
  }
}
