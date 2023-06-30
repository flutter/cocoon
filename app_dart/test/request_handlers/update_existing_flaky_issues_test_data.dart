// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_service/src/model/ci_yaml/ci_yaml.dart';
import 'package:cocoon_service/src/service/bigquery.dart';
import 'package:cocoon_service/src/service/config.dart';

import 'package:cocoon_service/src/model/proto/protos.dart' as pb;

const String expectedSemanticsIntegrationTestIssueComment = '''
[prod pool] flaky ratio for the past (up to) 100 commits between 2023-06-20 and 2023-06-29 is 50.00%. Flaky number: 3; total number: 10.
One recent flaky example for a same commit: https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/103
Commit: https://github.com/flutter/flutter/commit/abc
Flaky builds:
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/103
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/102
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/101

Recent test runs:
https://flutter-dashboard.appspot.com/#/build?taskFilter=Mac_android%20android_semantics_integration_test
''';

const String expectedCiyamlTestIssueComment = '''
[prod pool] flaky ratio for the past (up to) 100 commits between 2023-06-20 and 2023-06-29 is 50.00%. Flaky number: 3; total number: 10.
One recent flaky example for a same commit: https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/103
Commit: https://github.com/flutter/flutter/commit/abc
Flaky builds:
https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/103
https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/102
https://ci.chromium.org/ui/p/flutter/builders/prod/Linux%20ci_yaml%20flutter%20roller/101

Recent test runs:
https://flutter-dashboard.appspot.com/#/build?taskFilter=Linux%20ci_yaml%20flutter%20roller
''';

const String expectedStagingCiyamlTestIssueComment = '''
[staging pool] flaky ratio for the past (up to) 100 commits between 2023-06-20 and 2023-06-29 is 50.00%. Flaky number: 3; total number: 10.
One recent flaky example for a same commit: https://ci.chromium.org/ui/p/flutter/builders/staging/Linux%20ci_yaml%20flutter%20roller/103
Commit: https://github.com/flutter/flutter/commit/abc
Flaky builds:
https://ci.chromium.org/ui/p/flutter/builders/staging/Linux%20ci_yaml%20flutter%20roller/103
https://ci.chromium.org/ui/p/flutter/builders/staging/Linux%20ci_yaml%20flutter%20roller/102
https://ci.chromium.org/ui/p/flutter/builders/staging/Linux%20ci_yaml%20flutter%20roller/101

Recent test runs:
https://flutter-dashboard.appspot.com/#/build?taskFilter=Linux%20ci_yaml%20flutter%20roller
''';

const String expectedSemanticsIntegrationTestZeroFlakeIssueComment = '''
[prod pool] flaky ratio for the past (up to) 100 commits between 2023-06-20 and 2023-06-29 is 0.00%. Flaky number: 0; total number: 10.
''';

const String expectedSemanticsIntegrationTestNotEnoughDataComment = '''
Current flaky ratio is not available (< 10 commits).
''';

final List<BuilderStatistic> semanticsIntegrationTestResponseZeroFlake = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Mac_android android_semantics_integration_test',
    flakyRate: 0.0,
    flakyBuilds: <String>[],
    succeededBuilds: <String>['203', '202', '201', '200', '199', '198', '197', '196', '195', '194'],
    recentCommit: '',
    flakyBuildOfRecentCommit: '',
    flakyNumber: 0,
    totalNumber: 10,
    fromDate: "2023-06-20",
    toDate: "2023-06-29",
  ),
];

final List<BuilderStatistic> semanticsIntegrationTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Mac_android android_semantics_integration_test',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201', '200', '199', '198', '197'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
    flakyNumber: 3,
    totalNumber: 10,
    fromDate: "2023-06-20",
    toDate: "2023-06-29",
  ),
];

final List<BuilderStatistic> stagingSameBuilderSemanticsIntegrationTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Mac_android android_semantics_integration_test',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201', '200', '199', '198', '197'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
    flakyNumber: 3,
    totalNumber: 10,
    fromDate: "2023-06-20",
    toDate: "2023-06-29",
  ),
];

final List<BuilderStatistic> semanticsIntegrationTestResponseNotEnoughData = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Mac_android android_semantics_integration_test',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201', '200'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
    flakyNumber: 3,
    totalNumber: 7,
    fromDate: "2023-06-20",
    toDate: "2023-06-29",
  ),
  // This builder is flakey, but it should be
  // ignored because it has ignore_flakiness set.
  BuilderStatistic(
    name: 'Mac_android ignore_myflakiness',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201', '200'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
    flakyNumber: 3,
    totalNumber: 7,
    fromDate: "2023-06-20",
    toDate: "2023-06-29",
  ),
];

final List<BuilderStatistic> shardSemanticsIntegrationTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Mac build_tests_1_4',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201', '200', '199', '198', '197'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
    flakyNumber: 3,
    totalNumber: 10,
    fromDate: "2023-06-20",
    toDate: "2023-06-29",
  ),
];

final List<BuilderStatistic> ciyamlTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Linux ci_yaml flutter roller',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201', '200', '199', '198', '197'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
    flakyNumber: 3,
    totalNumber: 10,
    fromDate: "2023-06-20",
    toDate: "2023-06-29",
  ),
];

final List<BuilderStatistic> stagingCiyamlTestResponse = <BuilderStatistic>[
  BuilderStatistic(
    name: 'Linux ci_yaml flutter roller',
    flakyRate: 0.5,
    flakyBuilds: <String>['103', '102', '101'],
    succeededBuilds: <String>['203', '202', '201', '200', '199', '198', '197'],
    recentCommit: 'abc',
    flakyBuildOfRecentCommit: '103',
    flakyNumber: 3,
    totalNumber: 10,
    fromDate: "2023-06-20",
    toDate: "2023-06-29",
  ),
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

Recent test runs:
https://flutter-dashboard.appspot.com/#/build?taskFilter=Mac_android%20android_semantics_integration_test

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

Recent test runs:
https://flutter-dashboard.appspot.com/#/build?taskFilter=Linux%20ci_yaml_flutter%20roller

Please follow https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness#fixing-flaky-tests to fix the flakiness and enable the test back after validating the fix (internal dashboard to validate: go/flutter_test_flakiness).
''';

final CiYaml testCiYaml = CiYaml(
  slug: Config.flutterSlug,
  branch: Config.defaultBranch(Config.flutterSlug),
  config: pb.SchedulerConfig(
    enabledBranches: <String>[
      Config.defaultBranch(Config.flutterSlug),
    ],
    targets: <pb.Target>[
      pb.Target(
        name: 'Mac_android android_semantics_integration_test',
        scheduler: pb.SchedulerSystem.luci,
        presubmit: false,
        properties: <String, String>{
          'tags': jsonEncode(['devicelab']),
          'task_name': 'android_semantics_integration_test',
        },
      ),
      pb.Target(
        name: 'Mac_android ignore_myflakiness',
        scheduler: pb.SchedulerSystem.luci,
        presubmit: false,
        properties: <String, String>{
          'ignore_flakiness': 'true',
          'tags': jsonEncode(['devicelab']),
          'task_name': 'ignore_myflakiness',
        },
      ),
      pb.Target(
        name: 'Linux ci_yaml flutter roller',
        scheduler: pb.SchedulerSystem.luci,
        bringup: true,
        timeout: 30,
        runIf: ['.ci.yaml'],
        recipe: 'infra/ci_yaml',
        properties: <String, String>{
          'tags': jsonEncode(["framework", "hostonly", "shard"]),
        },
      ),
      pb.Target(
        name: 'Mac build_tests_1_4',
        scheduler: pb.SchedulerSystem.luci,
        recipe: 'flutter/flutter_drone',
        timeout: 60,
        properties: <String, String>{
          'add_recipes_cq': 'true',
          'shard': 'build_tests',
          'subshard': '1_4',
          'tags': jsonEncode(["framework", "hostonly", "shard"]),
          'dependencies': jsonEncode([
            {
              'dependency': 'android_sdk',
              'version': 'version:29.0',
            },
            {
              'dependency': 'chrome_and_driver',
              'version': 'version:84',
            },
            {
              'dependency': 'xcode',
              'version': '13a233',
            },
            {
              'dependency': 'open_jdk',
              'version': '11',
            },
            {
              'dependency': 'gems',
              'version': 'v3.3.14',
            },
            {
              'dependency': 'goldctl',
              'version': 'git_revision:3a77d0b12c697a840ca0c7705208e8622dc94603',
            },
          ]),
        },
      ),
    ],
  ),
);

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
