// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:flutter/material.dart';
import 'package:platform/platform.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:conductor_core/proto.dart' as pb;

/// Widget that saves the global state and provides a method to modify it.
class StatusState extends ChangeNotifier {
  Map<String, Object>? currentReleaseStatus;

  // setStatus needs to be asynchronous to make sure it is called before nofityListeners
  Future<void> setStatus(Map<String, Object>? newStatus) async {
    currentReleaseStatus = newStatus;
  }

  /// Method that modifies the global state in provider.
  Future<void> changeCurrentReleaseStatus(Map<String, Object>? data) async {
    await setStatus(data);
    notifyListeners();
  }
}

/// Reads the current state filed saved in disk, and returns the state in a Map<K, V> format.
///
/// Supports passing a testState to mock the release state.
Map<String, Object>? ReleaseStatusSetter(pb.ConductorState? testState) {
  final pb.ConductorState? state;

  if (testState != null) {
    state = testState;
  } else {
    const LocalFileSystem fs = LocalFileSystem();
    const LocalPlatform platform = LocalPlatform();
    final String stateFilePath = defaultStateFilePath(platform);
    final File stateFile = fs.file(stateFilePath);
    state = stateFile.existsSync() ? readStateFromFile(stateFile) : null;
  }

  if (state == null) return null;

  return (presentStateDesktop(state));
}

/// Returns the conductor state in a Map<K, V> format for the desktop app to consume.
Map<String, Object> presentStateDesktop(pb.ConductorState state) {
  final List<Map<String, String>> engineCherrypicks = <Map<String, String>>[];
  for (final pb.Cherrypick cherrypick in state.engine.cherrypicks) {
    engineCherrypicks.add(<String, String>{'trunkRevision': cherrypick.trunkRevision, 'state': '${cherrypick.state}'});
  }

  final List<Map<String, String>> frameworkCherrypicks = <Map<String, String>>[];
  for (final pb.Cherrypick cherrypick in state.framework.cherrypicks) {
    frameworkCherrypicks
        .add(<String, String>{'trunkRevision': cherrypick.trunkRevision, 'state': '${cherrypick.state}'});
  }

  return <String, Object>{
    'Conductor Version': state.conductorVersion,
    'Release Channel': state.releaseChannel,
    'Release Version': state.releaseVersion,
    'Release Started at': DateTime.fromMillisecondsSinceEpoch(state.createdDate.toInt()).toString(),
    'Release Updated at': DateTime.fromMillisecondsSinceEpoch(state.lastUpdatedDate.toInt()).toString(),
    'Engine Candidate Branch': state.engine.candidateBranch,
    'Engine Starting Git HEAD': state.engine.startingGitHead,
    'Engine Current Git HEAD': state.engine.currentGitHead,
    'Engine Path to Checkout': state.engine.checkoutPath,
    'Engine LUCI Dashboard': luciConsoleLink(state.releaseChannel, 'engine'),
    'Engine Cherrypicks': engineCherrypicks,
    'Dart SDK Revision': state.engine.dartRevision,
    'Framework Candidate Branch': state.framework.candidateBranch,
    'Framework Starting Git HEAD': state.framework.startingGitHead,
    'Framework Current Git HEAD': state.framework.currentGitHead,
    'Framework Path to Checkout': state.framework.checkoutPath,
    'Framework LUCI Dashboard': luciConsoleLink(state.releaseChannel, 'flutter'),
    'Framework Cherrypicks': frameworkCherrypicks,
    'Current Phase': state.currentPhase,
  };
}
