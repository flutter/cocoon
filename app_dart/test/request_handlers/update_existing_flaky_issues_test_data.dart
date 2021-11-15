// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/service/bigquery.dart';

const String expectedSemanticsIntegrationTestIssueComment = '''
Current flaky ratio for the past 15 days is 50.00%.
One recent flaky example for a same commit: https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/103
Commit: https://github.com/flutter/flutter/commit/abc
Flaky builds:
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/103
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/102
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/101
''';

const String expectedStagingSemanticsIntegrationTestIssueComment = '''
Current flaky ratio for the past 15 days is 50.00%.
One recent flaky example for a same commit: https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/103
Commit: https://github.com/flutter/flutter/commit/abc
Flaky builds:
https://ci.chromium.org/ui/p/flutter/builders/staging/Linux%20ci_yaml%20flutter%20roller/103
https://ci.chromium.org/ui/p/flutter/builders/staging/Linux%20ci_yaml%20flutter%20roller/102
https://ci.chromium.org/ui/p/flutter/builders/staging/Linux%20ci_yaml%20flutter%20roller/101
''';

const String expectedSemanticsIntegrationTestZeroFlakeIssueComment = '''
Current flaky ratio for the past 15 days is 0.00%.
''';

final List<BuilderStatistic> semanticsIntegrationTestResponseZeroFlake = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Mac_android android_semantics_integration_test',
    flakyRate: 0.0,
    flakyBuilds: <String>[],
    succeededBuilds: <String>[],
    recentCommit: '',
    flakyBuildOfRecentCommit: '',
  )
];

final List<BuilderStatistic> semanticsIntegrationTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Mac_android android_semantics_integration_test',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
  )
];

final List<BuilderStatistic> shardSemanticsIntegrationTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Mac build_tests_1_4',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
  )
];

final List<BuilderStatistic> stagingSemanticsIntegrationTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Linux ci_yaml flutter roller',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
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
Flaky builds:
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/103
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/102
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/101

Succeeded builds (3 most recent):
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/203
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/202
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/201

Please follow https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness#fixing-flaky-tests to fix the flakiness and enable the test back after validating the fix (internal dashboard to validate: go/flutter_test_flakiness).
''';

const String expectedStagingSemanticsIntegrationTestResponseTitle = 'Linux ci_yaml flutter roller is 50.00% flaky';
const String expectedStagingSemanticsIntegrationTestResponseBody = '''
<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY.
{
  "name": "Linux ci_yaml flutter roller"
}
-->

The post-submit test builder `Linux ci_yaml flutter roller` had a flaky ratio 50.00% for the past 15 days, which is above our 2.00% threshold.

One recent flaky example for a same commit: https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/103
Commit: https://github.com/flutter/flutter/commit/abc
Flaky builds:
https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/103
https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/102
https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/101

Succeeded builds (3 most recent):
https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/203
https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/202
https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/201

Please follow https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness#fixing-flaky-tests to fix the flakiness and enable the test back after validating the fix (internal dashboard to validate: go/flutter_test_flakiness).
''';

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
    builder: Mac_android android_semantics_integration_test
    presubmit: false
    scheduler: luci
    properties:
      tags: >
        ["devicelab"]

  - name: Linux ci_yaml flutter roller
    recipe: infra/ci_yaml
    bringup: true # TODO(chillers): https://github.com/flutter/flutter/issues/93225
    timeout: 30
    properties:
      tags: >
        ["framework","hostonly","shard"]
    scheduler: luci
    runIf:
      - .ci.yaml

  - name: Mac build_tests_1_4
    recipe: flutter/flutter_drone
    timeout: 60
    properties:
      add_recipes_cq: "true"
      dependencies: >-
        [
          {"dependency": "android_sdk", "version": "version:29.0"},
          {"dependency": "chrome_and_driver", "version": "version:84"},
          {"dependency": "open_jdk"},
          {"dependency": "xcode"},
          {"dependency": "gems"},
          {"dependency": "goldctl"}
        ]
      shard: build_tests
      subshard: "1_4"
      tags: >
        ["framework","hostonly","shard"]
    scheduler: luci
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

String gitHubEncode(String source) {
  final List<int> utf8Characters = utf8.encode(source);
  final String base64encoded = base64Encode(utf8Characters);
  return base64encoded;
}
