// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;
import 'package:flutter/material.dart';

import '../logic/cherrypick_state.dart';
import '../models/cherrypick.dart';
import '../models/conductor_status.dart';
import '../services/conductor.dart';

/// Widget that saves the global state and provides a method to modify it.
class StatusState extends ChangeNotifier {
  StatusState({
    required this.conductor,
  }) : releaseStatus = stateToMap(conductor.state);

  final ConductorService conductor;
  late Map<ConductorStatusEntry, Object>? releaseStatus;

  /// Method that modifies the global state in provider.
  Future<void> changeReleaseStatus(Map<ConductorStatusEntry, Object>? data) async {
    // status modification needs to be asynchronous to make sure it is called before nofityListeners
    await () async {
      releaseStatus = data;
    }();
    notifyListeners();
  }

  /// Updates the release status with the latest values saved in the state file.
  ///
  /// [context] is the [BuildContext] of the widget which is calling this method.
  /// [read] is from 'package:provider/provider.dart'.
  ///
  /// Use the code below to call the method:
  ///
  /// {@tool snippet}
  ///
  /// An example on how to call this method:
  ///
  /// ```dart
  /// context.read<StatusState>().syncStatusWithState();
  /// ```
  /// {@end-tool}
  void syncStatusWithState() {
    releaseStatus = stateToMap(conductor.state);
    notifyListeners();
  }
}

// TODO(Yugue): Add another abstraction between services and state,
// https://github.com/flutter/flutter/issues/94816.

/// Returns the conductor state in a [Map<K, V>] format for the widgets to consume.
Map<ConductorStatusEntry, Object>? stateToMap(pb.ConductorState? state) {
  if (state == null) return null;
  final List<Map<Cherrypick, String>> engineCherrypicks = <Map<Cherrypick, String>>[];
  for (final pb.Cherrypick engineCherrypick in state.engine.cherrypicks) {
    engineCherrypicks.add(<Cherrypick, String>{
      Cherrypick.trunkRevision: engineCherrypick.trunkRevision,
      Cherrypick.state: engineCherrypick.state.string(),
    });
  }

  final List<Map<Cherrypick, String>> frameworkCherrypicks = <Map<Cherrypick, String>>[];
  for (final pb.Cherrypick frameworkCherrypick in state.framework.cherrypicks) {
    frameworkCherrypicks.add(<Cherrypick, String>{
      Cherrypick.trunkRevision: frameworkCherrypick.trunkRevision,
      Cherrypick.state: frameworkCherrypick.state.string(),
    });
  }

  return <ConductorStatusEntry, Object>{
    ConductorStatusEntry.conductorVersion: state.conductorVersion,
    ConductorStatusEntry.releaseChannel: state.releaseChannel,
    ConductorStatusEntry.releaseVersion: state.releaseVersion,
    ConductorStatusEntry.startedAt: DateTime.fromMillisecondsSinceEpoch(state.createdDate.toInt()).toString(),
    ConductorStatusEntry.updatedAt: DateTime.fromMillisecondsSinceEpoch(state.lastUpdatedDate.toInt()).toString(),
    ConductorStatusEntry.engineCandidateBranch: state.engine.candidateBranch,
    ConductorStatusEntry.engineStartingGitHead: state.engine.startingGitHead,
    ConductorStatusEntry.engineCurrentGitHead: state.engine.currentGitHead,
    ConductorStatusEntry.engineCheckoutPath: state.engine.checkoutPath,
    ConductorStatusEntry.engineLuciDashboard: luciConsoleLink(state.releaseChannel, 'engine'),
    ConductorStatusEntry.engineCherrypicks: engineCherrypicks,
    ConductorStatusEntry.dartRevision: state.engine.dartRevision,
    ConductorStatusEntry.frameworkCandidateBranch: state.framework.candidateBranch,
    ConductorStatusEntry.frameworkStartingGitHead: state.framework.startingGitHead,
    ConductorStatusEntry.frameworkCurrentGitHead: state.framework.currentGitHead,
    ConductorStatusEntry.frameworkCheckoutPath: state.framework.checkoutPath,
    ConductorStatusEntry.frameworkLuciDashboard: luciConsoleLink(state.releaseChannel, 'flutter'),
    ConductorStatusEntry.frameworkCherrypicks: frameworkCherrypicks,
    ConductorStatusEntry.currentPhase: state.currentPhase,
  };
}
