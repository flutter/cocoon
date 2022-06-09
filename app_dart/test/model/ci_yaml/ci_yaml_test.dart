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

  group('Validate pinned version operation.', () {
    void validatePinnedVersion(String input) {
      test("$input -> returns normally", () {
        DependencyValidator.hasVersion(dependencyJsonString: input);
      });
    }

    validatePinnedVersion('[{"dependency": "chrome_and_driver", "version": "version:96.2"}]');
    validatePinnedVersion('[{"dependency": "open_jdk", "version": "11"}]');
    validatePinnedVersion('[{"dependency": "android_sdk", "version": "version:31v8"}]');
    validatePinnedVersion(
        '[{"dependency": "goldctl", "version": "git_revision:3a77d0b12c697a840ca0c7705208e8622dc94603"}]');
  });

  group('Validate un-pinned version operation.', () {
    void validateUnPinnedVersion(String input) {
      test("$input -> returns normally", () {
        expect(() => DependencyValidator.hasVersion(dependencyJsonString: input), throwsException);
      });
    }

    validateUnPinnedVersion('[{"dependency": "some_sdk", "version": ""}]');
    validateUnPinnedVersion('[{"dependency": "another_sdk"}]');
    validateUnPinnedVersion('[{"dependency": "yet_another_sdk", "version": "latest"}]');
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
