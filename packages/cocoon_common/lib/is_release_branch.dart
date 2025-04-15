// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Returns whether [branchName] "looks like" a release candidate build.
bool isReleaseCandidateBranch({required String branchName}) {
  return _isReleaseCandidate.hasMatch(branchName);
}

final _isReleaseCandidate = RegExp(r'flutter-\d+\.\d+-candidate\.\d+');
