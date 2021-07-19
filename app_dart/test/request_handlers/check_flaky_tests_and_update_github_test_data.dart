// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/service/bigquery.dart';

const String ciYamlContent = '''
# Describes the targets run in continuous integration environment.
#
# Flutter infra uses this file to generate a checklist of tasks to be performed
# for every commit.
#
# More information at:
#  * https://github.com/flutter/cocoon/blob/master/scheduler/README.md
enabled_branches:
  - master

targets:
  - name: mac_android_android_semantics_integration_test
    builder: Mac_android android_semantics_integration_test
    presubmit: false
    scheduler: luci
    properties:
      tags: >
        ["devicelab"]
  - name: Linux analyze
    builder: Linux analyze
    scheduler: luci
    properties:
      tags: >
        ["framework","hostonly"]
  - name: win_framework_tests_misc
    builder: Windows framework_tests_misc
    presubmit: false
    scheduler: luci
    properties:
      tags: >
        ["shard"]
''';

const String ciYamlContentAlreadyFlaky = '''
# Describes the targets run in continuous integration environment.
#
# Flutter infra uses this file to generate a checklist of tasks to be performed
# for every commit.
#
# More information at:
#  * https://github.com/flutter/cocoon/blob/master/scheduler/README.md
enabled_branches:
  - master

targets:
  - name: mac_android_android_semantics_integration_test
    builder: Mac_android android_semantics_integration_test
    bringup: true
    presubmit: false
    scheduler: luci
    properties:
      tags: >
        ["devicelab"]
  - name: Linux analyze
    builder: Linux analyze
    scheduler: luci
    properties:
      tags: >
        ["framework","hostonly"]
  - name: win_framework_tests_misc
    builder: Windows framework_tests_misc
    presubmit: false
    scheduler: luci
    properties:
      tags: >
        ["shard"]
''';

const String testOwnersContent = '''

# Below is a list of Flutter team members' GitHub handles who are
# test owners of this repository.
#
# These owners are mainly team leaders and their sub-teams. Please feel
# free to claim ownership by adding your handle to corresponding tests.
#
# This file will be used as a reference when new flaky bugs are filed and
# the TL will be assigned and the sub-team will be labeled by default
# for further triage.

## Linux Android DeviceLab tests
/dev/devicelab/bin/tasks/android_semantics_integration_test.dart @HansMuller @flutter/framework

## Host only framework tests
# Linux analyze
/dev/bots/analyze.dart @HansMuller @flutter/framework

## Shards tests
# framework_tests @HansMuller @flutter/framework


/dev/devicelab/bin/tasks/android_semantics_integration_test.dart @HansMuller @flutter/framework
''';

const String jobNotCompleteResponse = '''
{
  "jobComplete" : false
}
''';

const String expectedSemanticsIntegrationTestNewIssueURL = 'https://something.something';
const String expectedSemanticsIntegrationTestTreeSha = 'abcdefg';
const int expectedSemanticsIntegrationTestPRNumber = 123;

final List<BuilderStatistic> semanticsIntegrationTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Mac_android android_semantics_integration_test',
    flakyRate: 0.5,
    failedBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201'],
    recentCommit: 'abc',
    failedBuildOfRecentCommit: '103',
  )
];

final List<BuilderStatistic> semanticsIntegrationTestResponseZeroFlake = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Mac_android android_semantics_integration_test',
    flakyRate: 0.0,
    failedBuilds: <String>[],
    succeededBuilds: <String>[],
    recentCommit: '',
    failedBuildOfRecentCommit: '',
  )
];

const String expectedSemanticsIntegrationTestResponseTitle =
    'Mac_android android_semantics_integration_test is 50.00% flaky';
const String expectedSemanticsIntegrationTestResponseBody = '''
<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY.
{
  "name": "Mac_android android_semantics_integration_test"
}
-->

The post-submit test builder `Mac_android android_semantics_integration_test` had a flaky ratio 50.00% for the past 15 days, which is above our 2.00% threshold.

One recent flaky example for a same commit: https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/103
Commit: https://github.com/flutter/flutter/commit/abc
Failed build:
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/103
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/102
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/101

Succeeded build (3 most recent):
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/203
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/202
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/201

Please follow https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness#fixing-flaky-tests to fix the flakiness and enable the test back after validating the fix (internal dashboard to validate: go/flutter_test_flakiness).
''';

const String expectedSemanticsIntegrationTestIssueComment = '''
Current flaky ratio for the past 15 days is 50.00%.
One recent flaky example for a same commit: https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/103
Commit: https://github.com/flutter/flutter/commit/abc
Failed build:
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/103
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/102
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/101
''';

const String expectedSemanticsIntegrationTestZeroFlakeIssueComment = '''
Current flaky ratio for the past 15 days is 0.00%.
''';

const String expectedSemanticsIntegrationTestResponseAssignee = 'HansMuller';
const List<String> expectedSemanticsIntegrationTestResponseLabels = <String>[
  'team: flakes',
  'severe: flake',
  'P1',
];
const String expectedSemanticsIntegrationTestCiYamlContent = '''
# Describes the targets run in continuous integration environment.
#
# Flutter infra uses this file to generate a checklist of tasks to be performed
# for every commit.
#
# More information at:
#  * https://github.com/flutter/cocoon/blob/master/scheduler/README.md
enabled_branches:
  - master

targets:
  - name: mac_android_android_semantics_integration_test
    builder: Mac_android android_semantics_integration_test
    bringup: true # Flaky $expectedSemanticsIntegrationTestNewIssueURL
    presubmit: false
    scheduler: luci
    properties:
      tags: >
        ["devicelab"]
  - name: Linux analyze
    builder: Linux analyze
    scheduler: luci
    properties:
      tags: >
        ["framework","hostonly"]
  - name: win_framework_tests_misc
    builder: Windows framework_tests_misc
    presubmit: false
    scheduler: luci
    properties:
      tags: >
        ["shard"]
''';
const String expectedSemanticsIntegrationTestPullRequestTitle =
    'Marks Mac_android android_semantics_integration_test to be flaky';
const String expectedSemanticsIntegrationTestPullRequestBody = '''
<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY.
{
  "name": "Mac_android android_semantics_integration_test"
}
-->
Issue link: $expectedSemanticsIntegrationTestNewIssueURL
''';

final List<BuilderStatistic> analyzeTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Linux analyze',
    flakyRate: 0.01,
    failedBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201'],
    recentCommit: 'abc',
    failedBuildOfRecentCommit: '103',
  )
];
const String expectedAnalyzeTestResponseAssignee = 'HansMuller';
const List<String> expectedAnalyzeTestResponseLabels = <String>[
  'team: flakes',
  'severe: flake',
  'P2',
];

final List<BuilderStatistic> frameworkTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Windows framework_tests_misc',
    flakyRate: 0.01,
    failedBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201'],
    recentCommit: 'abc',
    failedBuildOfRecentCommit: '103',
  )
];
const String expectedFrameworkTestResponseAssignee = 'HansMuller';
const List<String> expectedFrameworkTestResponseLabels = <String>[
  'team: flakes',
  'severe: flake',
  'P2',
];

String gitHubEncode(String source) {
  final List<int> utf8Characters = utf8.encode(source);
  final String base64encoded = base64Encode(utf8Characters);
  return base64encoded;
}
