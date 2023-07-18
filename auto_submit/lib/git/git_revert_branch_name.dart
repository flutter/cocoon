// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Wrapper class to create a revert branch that is comprised of the prefix
/// revert_ and the commit sha so the branch is easily identifiable.
class GitRevertBranchName {
  final String _commitSha;

  const GitRevertBranchName(this._commitSha);

  static const String _branchPrefix = 'revert';

  String get branch => '${_branchPrefix}_$_commitSha';
}