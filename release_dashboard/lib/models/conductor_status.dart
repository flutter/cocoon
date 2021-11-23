// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Keys for the release status which is in [Map<K, V>] format.
///
/// The status of the current release is defined in the following format:
///
/// {@tool snippet}
///
/// A partial example of the release status:
///
/// ```dart
/// Map<ConductorStatusEntry, Object> releaseStatus = <ConductorStatusEntry, Object>{
///   ConductorStatusEntry.conductorVersion: 'fakeConductorVersion',
///   ConductorStatusEntry.releaseChannel: 'fakeReleaseChannel',
/// ...
/// };
/// ```
/// {@end-tool}
///
/// [Cherrypick] enums can be used directly to query release status values as shown below:
///
/// {@tool snippet}
///
/// An example to get the values of the release status:
///
/// ```dart
/// const String fakeConductorVersion = releaseStatus[ConductorStatusEntry.conductorVersion];
/// const String fakeReleaseChannel = releaseStatus[ConductorStatusEntry.releaseChannel];
/// ```
/// {@end-tool}
enum ConductorStatusEntry {
  conductorVersion,
  releaseChannel,
  releaseVersion,
  startedAt,
  updatedAt,
  engineCandidateBranch,
  engineStartingGitHead,
  engineCurrentGitHead,
  engineCheckoutPath,
  engineLuciDashboard,
  engineCherrypicks,
  dartRevision,
  frameworkCandidateBranch,
  frameworkStartingGitHead,
  frameworkCurrentGitHead,
  frameworkCheckoutPath,
  frameworkLuciDashboard,
  frameworkCherrypicks,
  currentPhase,
}
