// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:conductor_core/conductor_core.dart';
import 'package:file/file.dart';
import 'package:flutter/material.dart';
import 'package:process/process.dart';
import 'package:provider/provider.dart';

import '../state/status_state.dart';

class ReleaseDashboardStartContext extends StartContext {
  ReleaseDashboardStartContext({
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
    required this.context,
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

  final BuildContext context;

  // TODO(Yugue): Add prompt UI to confirm tag creation at startContext.
  // https://github.com/flutter/flutter/issues/94072.
  @override
  Future<bool> prompt(String message) {
    final Completer<bool> completer = Completer<bool>();
    context.watch<StatusState>().dialogueChanger(message, completer);
    return completer.future;
  }
}
