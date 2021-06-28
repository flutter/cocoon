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

/dev/devicelab/bin/tasks/android_semantics_integration_test.dart @HansMuller @flutter/framework
''';

const String jobNotCompleteResponse = '''
{
  "jobComplete" : false
}
''';

//
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

const String expectedSemanticsIntegrationTestResponseTitle =
    'Mac_android android_semantics_integration_test is 50.00% flaky';
const String expectedSemanticsIntegrationTestResponseBody = '''
<!-- summary-->
The post-submit test builder `Mac_android android_semantics_integration_test` had a flaky ratio 50.00% for the past 15 days, which is above our 2.00% threshold.
<!-- /summary-->
    
One recent flaky example for a same commit: <!-- failedBuildOfCommit-->https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/103<!-- /failedBuildOfCommit-->
Commit: <!-- commit-->https://github.com/flutter/flutter/commit/abc<!-- /commit-->
Failed build:
<!-- failedBuilds-->
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/103
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/102
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/101
<!-- /failedBuilds-->
    
Succeeded build (3 most recent):
<!-- succeededBuilds-->
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/203
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/202
https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_android%20android_semantics_integration_test/201
<!-- /succeededBuilds-->
    

Please follow https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness#fixing-flaky-tests to fix the flakiness and enable the test back after validating the fix (internal dashboard to validate: go/flutter_test_flakiness).
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
    bringup: true // Flaky $expectedSemanticsIntegrationTestNewIssueURL
    presubmit: false
    scheduler: luci
''';
const String expectedSemanticsIntegrationTestPullRequestTitle =
    'Marks Mac_android android_semantics_integration_test to be flaky';
const String expectedSemanticsIntegrationTestPullRequestBody =
    'Issue link: $expectedSemanticsIntegrationTestNewIssueURL';

String gitHubEncode(String source) {
  final List<int> utf8Characters = utf8.encode(source);
  final String base64encoded = base64Encode(utf8Characters);
  return base64encoded;
}
