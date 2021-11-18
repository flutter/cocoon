// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/conductor_core.dart';
import 'package:conductor_core/proto.dart' as pb;

const String conductorVersionDefault = 'v1.0';
const String releaseChannelDefault = 'beta';
const String releaseVersionDefault = '1.2.0-3.4.pre';
const String engineCandidateBranchDefault = 'flutter-1.2-candidate.3';
const String frameworkCandidateBranchDefault = 'flutter-1.2-candidate.4';
const String workingBranchDefault = 'cherrypicks-$engineCandidateBranchDefault';
const String dartRevisionDefault = 'fe9708ab688dcda9923f584ba370a66fcbc3811f';
const String engineCherrypick1Default = 'a5a25cd702b062c24b2c67b8d30b5cb33e0ef6f0';
const String engineCherrypick2Default = '94d06a2e1d01a3b0c693b94d70c5e1df9d78d249';
const String engineCherrypick3Default = '94d06a2e1d01a3b0c693b94d70c5e1df9d78d255';
const String frameworkCherrypickDefault = '768cd702b691584b2c67b8d30b5cb33e0ef6f0';
const String engineStartingGitHeadDefault = '083049e6cae311910c6a6619a6681b7eba4035b4';
const String engineCurrentGitHeadDefault = '23otn2o3itn2o3int2oi3tno23itno2i3tn';
const String engineCheckoutPathDefault = '/Users/engine';
const String frameworkStartingGitHeadDefault = 'df6981e98rh49er8h149er8h19er8h1';
const String frameworkCurrentGitHeadDefault = '239tnint023t09j2039tj0239tn';
const String frameworkCheckoutPathDefault = '/Users/framework';
final String engineLUCIDashboardDefault = luciConsoleLink(releaseChannelDefault, 'engine');
final String frameworkLUCIDashboardDefault = luciConsoleLink(releaseChannelDefault, 'flutter');

/// Helper function that generates a test conductor state.
///
/// Default state has all the info complete and valid with no cherrypick conflicts.
pb.ConductorState generateConductorState({
  bool? engineCherrypicksInConflict,
  bool? frameworkCherrypicksInConflict,
  String? conductorVersion = conductorVersionDefault,
  String? releaseChannel = releaseChannelDefault,
  String? releaseVersion = releaseVersionDefault,
  String? engineCandidateBranch = engineCandidateBranchDefault,
  String? frameworkCandidateBranch = frameworkCandidateBranchDefault,
  String? workingBranch = workingBranchDefault,
  String? dartRevision = dartRevisionDefault,
  String? engineCherrypick1 = engineCherrypick1Default,
  String? engineCherrypick2 = engineCherrypick2Default,
  String? engineCherrypick3 = engineCherrypick3Default,
  String? frameworkCherrypick = frameworkCherrypickDefault,
  String? engineStartingGitHead = engineStartingGitHeadDefault,
  String? engineCurrentGitHead = engineCurrentGitHeadDefault,
  String? engineCheckoutPath = engineCheckoutPathDefault,
  String? frameworkStartingGitHead = frameworkStartingGitHeadDefault,
  String? frameworkCurrentGitHead = frameworkCurrentGitHeadDefault,
  String? frameworkCheckoutPath = frameworkCheckoutPathDefault,
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
