// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/is_release_branch.dart';
import 'package:test/test.dart';

void main() {
  test('master is not a release branch', () {
    expect(isReleaseCandidateBranch(branchName: 'master'), isFalse);
  });

  test('main is not a release branch', () {
    expect(isReleaseCandidateBranch(branchName: 'main'), isFalse);
  });

  test('flutter-x.x-candidate.x is a release branch', () {
    expect(
      isReleaseCandidateBranch(branchName: 'flutter-2.1-candidate.0'),
      isTrue,
    );
  });

  test('flutter-xx.xx-candidate.xx is a release branch', () {
    expect(
      isReleaseCandidateBranch(branchName: 'flutter-11.22-candidate.33'),
      isTrue,
    );
  });
}
