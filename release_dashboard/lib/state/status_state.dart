// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:flutter/material.dart';

import '../enums/cherrypick.dart';
import '../enums/conductor_status.dart';
import '../services/conductor.dart';

/// Widget that saves the global state and provides a method to modify it.
class StatusState extends ChangeNotifier {
  StatusState({
    required this.conductor,
  }) : releaseStatus = stateToMap(conductor.state);

  final ConductorService conductor;

  late Map<conductorStatus, Object>? releaseStatus;

  /// Method that modifies the global state in provider.
  Future<void> changeReleaseStatus(Map<conductorStatus, Object>? data) async {
    // status modification needs to be asynchronous to make sure it is called before nofityListeners
    await () async {
      releaseStatus = data;
    }();

    notifyListeners();
  }
}

/// Returns the conductor state in a [Map<K, V>] format for the widgets to consume.
Map<conductorStatus, Object>? stateToMap(pb.ConductorState? state) {
  if (state == null) return null;
  final List<Map<cherrypick, String>> engineCherrypicks = <Map<cherrypick, String>>[];
  for (final pb.Cherrypick engineCherrypick in state.engine.cherrypicks) {
    engineCherrypicks.add(<cherrypick, String>{
      cherrypick.trunkRevision: engineCherrypick.trunkRevision,
      cherrypick.state: '${engineCherrypick.state}'
    });
  }

  final List<Map<cherrypick, String>> frameworkCherrypicks = <Map<cherrypick, String>>[];
  for (final pb.Cherrypick frameworkCherrypick in state.framework.cherrypicks) {
    frameworkCherrypicks.add(<cherrypick, String>{
      cherrypick.trunkRevision: frameworkCherrypick.trunkRevision,
      cherrypick.state: '${frameworkCherrypick.state}'
    });
  }

  return <conductorStatus, Object>{
    conductorStatus.conductorVersion: state.conductorVersion,
    conductorStatus.releaseChannel: state.releaseChannel,
    conductorStatus.releaseVersion: state.releaseVersion,
    conductorStatus.startedAt: DateTime.fromMillisecondsSinceEpoch(state.createdDate.toInt()).toString(),
    conductorStatus.updatedAt: DateTime.fromMillisecondsSinceEpoch(state.lastUpdatedDate.toInt()).toString(),
    conductorStatus.engineCandidateBranch: state.engine.candidateBranch,
    conductorStatus.engineStartingGitHead: state.engine.startingGitHead,
    conductorStatus.engineCurrentGitHead: state.engine.currentGitHead,
    conductorStatus.engineCheckoutPath: state.engine.checkoutPath,
    conductorStatus.engineLUCIDashboard: luciConsoleLink(state.releaseChannel, 'engine'),
    conductorStatus.engineCherrypicks: engineCherrypicks,
    conductorStatus.dartRevision: state.engine.dartRevision,
    conductorStatus.frameworkCandidateBranch: state.framework.candidateBranch,
    conductorStatus.frameworkStartingGitHead: state.framework.startingGitHead,
    conductorStatus.frameworkCurrentGitHead: state.framework.currentGitHead,
    conductorStatus.frameworkCheckoutPath: state.framework.checkoutPath,
    conductorStatus.frameworkLUCIDashboard: luciConsoleLink(state.releaseChannel, 'flutter'),
    conductorStatus.frameworkCherrypicks: frameworkCherrypicks,
    conductorStatus.currentPhase: state.currentPhase,
  };
}
