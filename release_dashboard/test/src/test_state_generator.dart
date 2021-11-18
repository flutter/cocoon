// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;

const String kConductorVersion = 'v1.0';
const String kReleaseChannel = 'beta';
const String kReleaseVersion = '1.2.0-3.4.pre';
const String kEngineCandidateBranch = 'flutter-1.2-candidate.3';
const String kFrameworkCandidateBranch = 'flutter-1.2-candidate.4';
const String kWorkingBranch = 'cherrypicks-$kEngineCandidateBranch';
const String kDartRevision = 'fe9708ab688dcda9923f584ba370a66fcbc3811f';
const String kEngineCherrypick1 = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0';
const String kEngineCherrypick2 = '94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
const String kEngineCherrypick3 = '94d06a2e1d01a3b0c693b94d70c5e1df9d78d255';
const String kFrameworkCherrypick = '768cd702b691584b2c67b8d30b5cb33e0ef6f0';
const String kEngineStartingGitHead = '083049e6cae311910c6a6619a6681b7eba4035b4';
const String kEngineCurrentGitHead = '23otn2o3itn2o3int2oi3tno23itno2i3tn';
const String kEngineCheckoutPath = '/Users/engine';
const String kFrameworkStartingGitHead = 'df6981e98rh49er8h149er8h19er8h1';
const String kFrameworkCurrentGitHead = '239tnint023t09j2039tj0239tn';
const String kFrameworkCheckoutPath = '/Users/framework';
final String kEngineLUCIDashboard = luciConsoleLink(kReleaseChannel, 'engine');
final String kFrameworkLUCIDashboard = luciConsoleLink(kReleaseChannel, 'flutter');

/// Helper function that generates a test conductor state.
///
/// Default state has all the info complete and valid with no cherrypick conflicts.
pb.ConductorState generateConductorState({
  bool? engineCherrypicksInConflict,
  bool? frameworkCherrypicksInConflict,
  String? conductorVersion = kConductorVersion,
  String? releaseChannel = kReleaseChannel,
  String? releaseVersion = kReleaseVersion,
  String? engineCandidateBranch = kEngineCandidateBranch,
  String? frameworkCandidateBranch = kFrameworkCandidateBranch,
  String? workingBranch = kWorkingBranch,
  String? dartRevision = kDartRevision,
  String? engineCherrypick1 = kEngineCherrypick1,
  String? engineCherrypick2 = kEngineCherrypick2,
  String? engineCherrypick3 = kEngineCherrypick3,
  String? frameworkCherrypick = kFrameworkCherrypick,
  String? engineStartingGitHead = kEngineStartingGitHead,
  String? engineCurrentGitHead = kEngineCurrentGitHead,
  String? engineCheckoutPath = kEngineCheckoutPath,
  String? frameworkStartingGitHead = kFrameworkStartingGitHead,
  String? frameworkCurrentGitHead = kFrameworkCurrentGitHead,
  String? frameworkCheckoutPath = kFrameworkCheckoutPath,
}) {
  return pb.ConductorState(
    engine: pb.Repository(
      candidateBranch: engineCandidateBranch,
      cherrypicks: <pb.Cherrypick>[
        /// When [engineCherrypicksInConflict] trigger is on, only turns two cherrypicks into conflict, and leave one as pending.
        pb.Cherrypick(
            trunkRevision: engineCherrypick1,
            state: engineCherrypicksInConflict == true ? pb.CherrypickState.PENDING_WITH_CONFLICT : null),
        pb.Cherrypick(
            trunkRevision: engineCherrypick2,
            state: engineCherrypicksInConflict == true ? pb.CherrypickState.PENDING_WITH_CONFLICT : null),
        pb.Cherrypick(trunkRevision: engineCherrypick3),
      ],
      dartRevision: dartRevision,
      workingBranch: workingBranch,
      startingGitHead: engineStartingGitHead,
      currentGitHead: engineCurrentGitHead,
      checkoutPath: engineCheckoutPath,
    ),
    framework: pb.Repository(
      candidateBranch: frameworkCandidateBranch,
      cherrypicks: <pb.Cherrypick>[
        pb.Cherrypick(
            trunkRevision: frameworkCherrypick,
            state: frameworkCherrypicksInConflict == true ? pb.CherrypickState.PENDING_WITH_CONFLICT : null),
      ],
      workingBranch: workingBranch,
      startingGitHead: frameworkStartingGitHead,
      currentGitHead: frameworkCurrentGitHead,
      checkoutPath: frameworkCheckoutPath,
    ),
    conductorVersion: conductorVersion,
    releaseChannel: releaseChannel,
    releaseVersion: releaseVersion,
  );
}
