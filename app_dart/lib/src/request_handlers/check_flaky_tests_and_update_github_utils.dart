// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:github/github.dart';

import '../service/bigquery.dart';

const String _commitPrefix = 'https://github.com/flutter/flutter/commit/';
const String _buildPrefix = 'https://ci.chromium.org/ui/p/flutter/builders/prod/';

// Issue
const String kCloseIssueComment = '''
Closed this issue because the flaky rate of this test has dropped to 0.0% and is considered
to be no longer flaky.

If you think otherwise, reopen this issue and assign an owner to prevent it from being closed.
''';
const String kTeamFlakeLabel = 'team: flakes';
const String kSevereFlakeLabel = 'severe: flake';
const String kP1Label = 'P1';
const String kP2Label = 'P2';

String _buildHiddenMetaTags(BuilderStatistic statistic) {
  return '''
<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY.
{
  "name": "${statistic.name}"
}
-->
''';
}

final RegExp _issueHiddenMetaTagsRegex =
    RegExp(r'<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY.\n(?<meta>.+)\n-->', dotAll: true);

Map<String, dynamic> retrieveMetaTagsFromContent(String content) {
  final RegExpMatch match = _issueHiddenMetaTagsRegex.firstMatch(content);
  if (match == null) {
    return null;
  }
  return jsonDecode(match.namedGroup('meta')) as Map<String, dynamic>;
}

class IssueBuilder {
  IssueBuilder({
    this.statistic,
    this.threshold,
    this.isImportant,
  });

  final BuilderStatistic statistic;
  final double threshold;
  final bool isImportant;

  String get issueTitle {
    return '${statistic.name} is ${_formatRate(statistic.flakyRate)}% flaky';
  }

  String get issueBody {
    return '''
${_buildHiddenMetaTags(statistic)}
The post-submit test builder `${statistic.name}` had a flaky ratio ${_formatRate(statistic.flakyRate)}% for the past 15 days, ${isBelow ? 'which is the flakist test below ${_formatRate(threshold)}% threshold' : 'which is above our ${_formatRate(threshold)}% threshold'}.

One recent flaky example for a same commit: ${_issueBuildLink(builder: statistic.name, build: statistic.failedBuildOfRecentCommit)}
Commit: $_commitPrefix${statistic.recentCommit}
Failed build:
${_issueBuildLinks(builder: statistic.name, builds: statistic.failedBuilds)}

Succeeded build (3 most recent):
${_issueBuildLinks(builder: statistic.name, builds: statistic.succeededBuilds.sublist(0, 3))}

Please follow https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness#fixing-flaky-tests to fix the flakiness and enable the test back after validating the fix (internal dashboard to validate: go/flutter_test_flakiness).
''';
  }

  bool get isBelow => statistic.flakyRate < threshold;

  List<String> get issueLabels {
    return <String>[
      kTeamFlakeLabel,
      kSevereFlakeLabel,
      if (isImportant && isBelow) kP2Label,
      if (isImportant && !isBelow) kP1Label,
    ];
  }
}

String _formatRate(double rate) => (rate * 100).toStringAsFixed(2);

String _issueBuildLinks({String builder, List<String> builds}) {
  return '${builds.map((String build) => _issueBuildLink(builder: builder, build: build)).join('\n')}';
}

String _issueBuildLink({String builder, String build}) {
  return Uri.encodeFull('$_buildPrefix$builder/$build');
}

// Pull Request
class PullRequestBuilder {
  PullRequestBuilder({
    this.statistic,
    this.issue,
  });

  final BuilderStatistic statistic;
  final Issue issue;

  String get pullRequestTitle => 'Marks ${statistic.name} to be flaky';
  String get pullRequestBody => '${_buildHiddenMetaTags(statistic)}Issue link: ${issue.htmlUrl}\n';
}

// TESTOWNER Regex

const String kOwnerGroupName = 'owners';
final RegExp devicelabTestOwners =
    RegExp('## Linux Android DeviceLab tests\n(?<$kOwnerGroupName>.+)## Host only framework tests', dotAll: true);
final RegExp frameworkHostOnlyTestOwners =
    RegExp('## Host only framework tests\n(?<$kOwnerGroupName>.+)## Shards tests', dotAll: true);
final RegExp shardTestOwners = RegExp('## Shards tests\n(?<$kOwnerGroupName>.+)', dotAll: true);
