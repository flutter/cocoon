// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/service/bigquery.dart';

const int existingIssueNumber = 85578;
const String existingIssueURL = 'https://github.com/flutter/flutter/issues/$existingIssueNumber';

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
  - name: Mac_android android_semantics_integration_test
    presubmit: false
    bringup: true # Flaky $existingIssueURL
    scheduler: luci
    properties:
      tags: >
        ["devicelab"]
  - name: Mac_android ignore_myflakiness
    bringup: true
    presubmit: false
    scheduler: luci
    properties:
      ignore_flakiness: "true"
      tags: >
        ["devicelab"]
  - name: Linux analyze
    scheduler: luci
    properties:
      tags: >
        ["framework","hostonly"]
  - name: Windows framework_tests_misc
    presubmit: false
    scheduler: luci
    properties:
      tags: >
        ["shard"]
''';

const String ciYamlContentNoIssue = '''
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
  - name: Mac_android android_semantics_integration_test
    presubmit: false
    bringup: true
    scheduler: luci
    properties:
      tags: >
        ["devicelab"]
  - name: Mac_android ignore_myflakiness
    bringup: true
    presubmit: false
    scheduler: luci
    properties:
      ignore_flakiness: "true"
      tags: >
        ["devicelab"]
  - name: Linux analyze
    scheduler: luci
    properties:
      tags: >
        ["framework","hostonly"]
  - name: Windows framework_tests_misc
    presubmit: false
    scheduler: luci
    properties:
      tags: >
        ["shard"]
''';

const String ciYamlContentFlakyInIgnoreList = '''
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
  - name: Mac_ios32 native_ui_tests_ios
    presubmit: false
    bringup: true
    scheduler: luci
    properties:
      tags: >
        ["devicelab"]
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

const String expectedSemanticsIntegrationTestResponseBody = '''
<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY.
{
  "name": "Mac_android android_semantics_integration_test"
}
-->

The post-submit test builder `Mac_android android_semantics_integration_test`, which has been marked `bringup: true`, had 3 flakes over past 10 commits.

One recent flaky example for a same commit: https://ci.chromium.org/ui/p/flutter/builders/staging/Mac_android%20android_semantics_integration_test/103
Commit: https://github.com/flutter/flutter/commit/abc

Flaky builds:
https://ci.chromium.org/ui/p/flutter/builders/staging/Mac_android%20android_semantics_integration_test/103
https://ci.chromium.org/ui/p/flutter/builders/staging/Mac_android%20android_semantics_integration_test/102
https://ci.chromium.org/ui/p/flutter/builders/staging/Mac_android%20android_semantics_integration_test/101

Recent test runs:
https://flutter-dashboard.appspot.com/#/build?taskFilter=Mac_android%20android_semantics_integration_test

Please follow https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness#fixing-flaky-tests to fix the flakiness and enable the test back after validating the fix (internal dashboard to validate: go/flutter_test_flakiness).
''';

final List<BuilderRecord> semanticsIntegrationTestRecordsAllPassed = <BuilderRecord>[
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
];

final List<BuilderRecord> semanticsIntegrationTestRecordsFlaky = <BuilderRecord>[
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: true, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
];

final List<BuilderRecord> semanticsIntegrationTestRecordsFailed = <BuilderRecord>[
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: true),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
  BuilderRecord(commit: 'abc', isFlaky: false, isFailed: false),
];

const String expectedSemanticsIntegrationTestOwner = 'HansMuller';
const List<String> expectedSemanticsIntegrationTestLabels = <String>[
  'team: flakes',
  'severe: flake',
  'P1',
  'framework',
];
const String expectedSemanticsIntegrationTestTreeSha = 'abcdefg';
const int expectedSemanticsIntegrationTestPRNumber = 123;

const String expectedSemanticsIntegrationTestBuilderName = 'Mac_android android_semantics_integration_test';
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
  - name: Mac_android android_semantics_integration_test
    presubmit: false
    scheduler: luci
    properties:
      tags: >
        ["devicelab"]
  - name: Mac_android ignore_myflakiness
    bringup: true
    presubmit: false
    scheduler: luci
    properties:
      ignore_flakiness: "true"
      tags: >
        ["devicelab"]
  - name: Linux analyze
    scheduler: luci
    properties:
      tags: >
        ["framework","hostonly"]
  - name: Windows framework_tests_misc
    presubmit: false
    scheduler: luci
    properties:
      tags: >
        ["shard"]
''';
const String expectedSemanticsIntegrationTestPullRequestTitle =
    'Marks Mac_android android_semantics_integration_test to be unflaky';
const String expectedSemanticsIntegrationTestPullRequestBody = '''
<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY.
{
  "name": "Mac_android android_semantics_integration_test"
}
-->
The issue $existingIssueURL has been closed, and the test has been passing for [8 consecutive runs](https://data.corp.google.com/sites/flutter_infra_metrics_datasite/flutter_check_test_flakiness_status_dashboard/?p=BUILDER_NAME:%22Mac_android%20android_semantics_integration_test%22).
This test can be marked as unflaky.
''';
const String expectedSemanticsIntegrationTestPullRequestBodyNoIssue = '''
<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY.
{
  "name": "Mac_android android_semantics_integration_test"
}
-->
The test has been passing for [8 consecutive runs](https://data.corp.google.com/sites/flutter_infra_metrics_datasite/flutter_check_test_flakiness_status_dashboard/?p=BUILDER_NAME:%22Mac_android%20android_semantics_integration_test%22).
This test can be marked as unflaky.
''';

final List<BuilderStatistic> stagingSemanticsIntegrationTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Mac_android android_semantics_integration_test',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201', '200', '199', '198', '197'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
    flakyNumber: 3,
    totalNumber: 10,
  ),
  // This builder is flakey, but it should be
  // ignored because it has ignore_flakiness set.
  BuilderStatistic(
    name: 'Mac_android ignore_myflakiness',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201', '200', '199', '198', '197'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
    flakyNumber: 3,
    totalNumber: 10,
  ),
];

String gitHubEncode(String source) {
  final List<int> utf8Characters = utf8.encode(source);
  final String base64encoded = base64Encode(utf8Characters);
  return base64encoded;
}
