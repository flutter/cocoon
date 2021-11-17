// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import '../services/conductor.dart';
import 'package:flutter/material.dart';
import 'package:conductor_core/proto.dart' as pb;

/// Widget that saves the global state and provides a method to modify it.
class StatusState extends ChangeNotifier {
  StatusState({
    required this.conductor,
  }) : releaseStatus = stateToMap(conductor.state);

  final ConductorService conductor;

  late Map<String, Object>? releaseStatus;

  /// Method that modifies the global state in provider.
  Future<void> changeReleaseStatus(Map<String, Object>? data) async {
    // status modification needs to be asynchronous to make sure it is called before nofityListeners
    await () async {
      releaseStatus = data;
    }();

    notifyListeners();
  }
}

/// Returns the conductor state in a [Map<K, V>] format for the widgets to consume.
Map<String, Object>? stateToMap(pb.ConductorState? state) {
  if (state == null) return null;
  final List<Map<String, String>> engineCherrypicks = <Map<String, String>>[];
  for (final pb.Cherrypick cherrypick in state.engine.cherrypicks) {
    engineCherrypicks.add(<String, String>{'trunkRevision': cherrypick.trunkRevision, 'state': '${cherrypick.state}'});
  }

  final List<Map<String, String>> frameworkCherrypicks = <Map<String, String>>[];
  for (final pb.Cherrypick cherrypick in state.framework.cherrypicks) {
    frameworkCherrypicks
        .add(<String, String>{'trunkRevision': cherrypick.trunkRevision, 'state': '${cherrypick.state}'});
  }

// TODO(Yugue): Use enums as keys, https://github.com/flutter/flutter/issues/93748.
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
