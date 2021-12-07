// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:file/file.dart';
import 'package:flutter/material.dart';
import 'package:process/process.dart';

class ReleaseDashboardStartContext extends StartContext {
  ReleaseDashboardStartContext({
    required this.syncStatusWithState,
    required String candidateBranch,
    required String? dartRevision,
    required List<String> engineCherrypickRevisions,
    required String engineMirror,
    required String engineUpstream,
    required List<String> frameworkCherrypickRevisions,
    required String frameworkMirror,
    required String frameworkUpstream,
    required String conductorVersion,
    required String incrementLetter,
    required ProcessManager processManager,
    required String releaseChannel,
    required Checkouts checkouts,
    required File stateFile,
    bool force = false,
  }) : super(
          candidateBranch: candidateBranch,
          checkouts: checkouts,
          dartRevision: dartRevision,
          engineCherrypickRevisions: engineCherrypickRevisions,
          engineMirror: engineMirror,
          engineUpstream: engineUpstream,
          conductorVersion: conductorVersion,
          frameworkCherrypickRevisions: frameworkCherrypickRevisions,
          frameworkMirror: frameworkMirror,
          frameworkUpstream: frameworkUpstream,
          incrementLetter: incrementLetter,
          processManager: processManager,
          releaseChannel: releaseChannel,
          stateFile: stateFile,
          force: force,
        );

  final VoidCallback syncStatusWithState;

  @override
  void updateState(pb.ConductorState state, [List<String> logs = const <String>[]]) {
    super.updateState(state, logs);
    syncStatusWithState();
  }

  // TODO(Yugue): Add prompt UI to confirm tag creation at startContext.
  // https://github.com/flutter/flutter/issues/94072.
  @override
  Future<bool> prompt(String message) async {
    return true;
  }
}
