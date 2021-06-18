// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';

import 'package:github/github.dart';

const String _commitPrefix = 'https://github.com/flutter/flutter/commit/';
const String _buildPrefix = 'https://ci.chromium.org/ui/p/flutter/builders/prod/';

const String getFlakyRateQuery = r'''
select builder_name,
       sum(is_flaky) as flaky_number,
       count(*) as total_number,
       string_agg(case when is_flaky = 1 then failed_builds end, ', ') as failed_builds,
       string_agg(succeeded_builds, ', ') as succeeded_builds,
       array_agg(case when is_flaky = 1 then sha end IGNORE NULLS ORDER BY date DESC)[ordinal(1)] as recent_flaky_commit,
       array_agg(case when is_flaky = 1 then failed_builds end IGNORE NULLS ORDER BY date DESC)[ordinal(1)] as failure_of_recent_flaky_commit,
       sum(is_flaky)/count(*) as flaky_ratio
from `flutter-dashboard.datasite.luci_prod_build_status`
where date>=date_sub(current_date(), interval 14 day) and
      date<=current_date() and
      builder_name not like '%Drone' and
      repo='flutter' and
      branch='master' and
      pool = 'luci.flutter.prod' and
      builder_name not like '%Beta%'
group by builder_name;
''';

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

class IssueBuilder {
  IssueBuilder({
    this.stats,
    this.threshold,
    this.isImportant,
  });

  final BuilderStats stats;
  final double threshold;
  final bool isImportant;
  static final RegExp issueTitleRegex = RegExp(r'(?<name>.+) is (?<rate>.+)% flaky');

  String get issueTitle {
    return '${stats.name} is ${_formatRate(stats.flakyRate)}% flaky';
  }

  String get issueBody {
    return '''
$_issueSummary
One recent flaky example for a same commit: $_issueFailedBuildOfCommit
Commit: $_issueCommit
Failed build:
$_issueFailedBuilds
Succeeded build (3 most recent):
$_issueSucceededBuilds

Please follow https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness#fixing-flaky-tests to fix the flakiness and enable the test back after validating the fix (internal dashboard to validate: go/flutter_test_flakiness).
''';
  }

  bool get isBelow => stats.flakyRate < threshold;

  List<String> get issueLabels {
    return <String>[
      kTeamFlakeLabel,
      kSevereFlakeLabel,
      if (isImportant && isBelow) kP2Label,
      if (isImportant && !isBelow) kP1Label,
    ];
  }

  String get _issueSummary {
    return '''
<!-- summary-->
The post-submit test builder `${stats.name}` had a flaky ratio ${_formatRate(stats.flakyRate)}% for the past 15 days, ${isBelow ? 'which is the flakist test below ${_formatRate(threshold)}% threshold' : 'which is above our ${_formatRate(threshold)}% threshold'}.
<!-- /summary-->
    ''';
  }

  String get _issueFailedBuildOfCommit {
    return '<!-- failedBuildOfCommit-->${_issueBuildLink(builder: stats.name, build: stats.failedBuildOfRecentCommit)}<!-- /failedBuildOfCommit-->';
  }

  String get _issueCommit => '<!-- commit-->$_commitPrefix${stats.recentCommit}<!-- /commit-->';

  String get _issueFailedBuilds {
    return '''
<!-- failedBuilds-->
${_issueBuildLinks(builder: stats.name, builds: stats.failedBuilds)}
<!-- /failedBuilds-->
    ''';
  }

  String get _issueSucceededBuilds {
    return '''
<!-- succeededBuilds-->
${_issueBuildLinks(builder: stats.name, builds: stats.succeededBuilds.sublist(0, 3))}
<!-- /succeededBuilds-->
    ''';
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
    this.stats,
    this.issue,
  });

  final BuilderStats stats;
  final Issue issue;

  String get pullRequestTitle => 'Marks ${stats.name} to be flaky';
  String get pullRequestBody => 'Issue link: ${issue.htmlUrl}';
}

final RegExp pullRequestTitleRegex = RegExp(r'Marks (?<name>.+) to be flaky');

class BuilderStats {
  BuilderStats({
    this.name,
    this.flakyRate,
    this.failedBuilds,
    this.succeededBuilds,
    this.recentCommit,
    this.failedBuildOfRecentCommit,
    this.testOwner,
  });

  final String name;
  final double flakyRate;
  final List<String> failedBuilds;
  final List<String> succeededBuilds;
  final String recentCommit;
  final String failedBuildOfRecentCommit;
  final String testOwner;
}
