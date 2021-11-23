// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Keys for repository cherrypicks which are in [Map<K, V>] format.
///
/// Each cherrypick of the engine or framework repo in the release dashboard
/// is defined in the following format:
///
/// {@tool snippet}
///
/// An example of a cherrypick map:
///
/// ```dart
/// Map<Cherrypick, String> singleCherrypick = <Cherrypick, String>{
///   Cherrypick.trunkRevision: 'fakeTrunkRevision',
///   Cherrypick.state: 'fakeState',
/// };
/// ```
/// {@end-tool}
///
/// [Cherrypick] enums can be used directly to query cherrypick values as shown below:
///
/// {@tool snippet}
///
/// An example to get the values of a cherrypick map:
///
/// ```dart
/// const String fakeTrunkRevision = singleCherrypick[Cherrypick.trunkRevision];
/// const String fakeState = singleCherrypick[Cherrypick.state];
/// ```
/// {@end-tool}
enum Cherrypick {
  trunkRevision,
  state,
}
