// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:test/test.dart';

void main() {
  group('enabledBranchesMatchesCurrentBranch', () {
    final List<EnabledBranchesRegexTest> tests = <EnabledBranchesRegexTest>[
      EnabledBranchesRegexTest('matches main', 'main', <String>['main']),
      EnabledBranchesRegexTest(
          'matches candidate branch', 'flutter-2.4-candidate.3', <String>['flutter-\\d+\\.\\d+-candidate\\.\\d+']),
      EnabledBranchesRegexTest('matches main when not first pattern', 'main', <String>['dev', 'main']),
      EnabledBranchesRegexTest('does not do partial matches', 'super-main', <String>['main'], false),
    ];

    for (EnabledBranchesRegexTest regexTest in tests) {
      test(regexTest.name, () {
        expect(CiYaml.enabledBranchesMatchesCurrentBranch(regexTest.enabledBranches, regexTest.branch),
            regexTest.expectation);
      });
    }
  });
}

/// Wrapper class for table driven design of [CiYaml.enabledBranchesMatchesCurrentBranch].
class EnabledBranchesRegexTest {
  EnabledBranchesRegexTest(this.name, this.branch, this.enabledBranches, [this.expectation = true]);

  final String branch;
  final List<String> enabledBranches;
  final String name;
  final bool expectation;
}
