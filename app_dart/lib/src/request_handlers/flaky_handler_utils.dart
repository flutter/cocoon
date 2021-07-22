// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../service/bigquery.dart';
import '../service/github_service.dart';

// String constants.
const String kTeamFlakeLabel = 'team: flakes';
const String kSevereFlakeLabel = 'severe: flake';
const String kP1Label = 'P1';
const String kP2Label = 'P2';
const String kBigQueryProjectId = 'flutter-dashboard';
const String kCiYamlPath = '.ci.yaml';
const String kTestOwnerPath = 'TESTOWNERS';
const String kCiYamlTargetsKey = 'targets';
const String kCiYamlTargetBuilderKey = 'builder';
const String kCiYamlTargetIsFlakyKey = 'bringup';
const String kCiYamlPropertiesKey = 'properties';
const String kCiYamlTargetTagsKey = 'tags';
const String kCiYamlTargetTagsShard = 'shard';
const String kCiYamlTargetTagsDevicelab = 'devicelab';
const String kCiYamlTargetTagsFramework = 'framework';
const String kCiYamlTargetTagsHostonly = 'hostonly';

const String kMasterRefs = 'heads/master';
const String kModifyMode = '100755';
const String kModifyType = 'blob';

const String _commitPrefix = 'https://github.com/flutter/flutter/commit/';
const String _buildPrefix = 'https://ci.chromium.org/ui/p/flutter/builders/prod/';
const String _flakeRecordPrefix = 'https://dashboards.corp.google.com/flutter_check_prod_test_flakiness_status_dashboard?p=BUILDER_NAME:';

/// A builder to build a new issue for a flake.
class IssueBuilder {
  IssueBuilder({
    @required this.statistic,
    @required this.threshold,
  });

  final BuilderStatistic statistic;
  final double threshold;

  String get issueTitle {
    return '${statistic.name} is ${_formatRate(statistic.flakyRate)}% flaky';
  }

  String get issueBody {
    return '''
${_buildHiddenMetaTags(name: statistic.name)}
The post-submit test builder `${statistic.name}` had a flaky ratio ${_formatRate(statistic.flakyRate)}% for the past 15 days, which is above our ${_formatRate(threshold)}% threshold.

One recent flaky example for a same commit: ${_issueBuildLink(builder: statistic.name, build: statistic.failedBuildOfRecentCommit)}
Commit: $_commitPrefix${statistic.recentCommit}
Failed build:
${_issueBuildLinks(builder: statistic.name, builds: statistic.failedBuilds)}

Succeeded build (3 most recent):
${_issueBuildLinks(builder: statistic.name, builds: statistic.succeededBuilds.sublist(0, 3))}

Please follow https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness#fixing-flaky-tests to fix the flakiness and enable the test back after validating the fix (internal dashboard to validate: go/flutter_test_flakiness).
''';
  }

  List<String> get issueLabels {
    return <String>[
      kTeamFlakeLabel,
      kSevereFlakeLabel,
      kP1Label,
    ];
  }
}

/// A builder to build the update comment and labels for an existing open flaky
/// issue.
class IssueUpdateBuilder {
  IssueUpdateBuilder({
    @required this.statistic,
    @required this.threshold,
    @required this.existingIssue,
  });

  final BuilderStatistic statistic;
  final double threshold;
  final Issue existingIssue;

  bool get isBelow => statistic.flakyRate < threshold;

  List<String> get issueLabels {
    final List<String> existingLabels =
        existingIssue.labels?.map<String>((IssueLabel label) => label.name)?.toList() ?? <String>[];
    if (statistic.flakyRate == 0.0) {
      return existingLabels;
    }
    // Only update the labels if there is already a priority label.
    if (existingLabels.contains(kP1Label) && !existingLabels.contains(kP2Label) && isBelow) {
      existingLabels.remove(kP1Label);
      existingLabels.add(kP2Label);
    } else if (!existingLabels.contains(kP1Label) && existingLabels.contains(kP2Label) && !isBelow) {
      existingLabels.remove(kP2Label);
      existingLabels.add(kP1Label);
    }
    return existingLabels;
  }

  String get issueUpdateComment {
    String result = 'Current flaky ratio for the past 15 days is ${_formatRate(statistic.flakyRate)}%.\n';
    if (statistic.flakyRate > 0.0) {
      result = result +
          '''
One recent flaky example for a same commit: ${_issueBuildLink(builder: statistic.name, build: statistic.failedBuildOfRecentCommit)}
Commit: $_commitPrefix${statistic.recentCommit}
Failed build:
${_issueBuildLinks(builder: statistic.name, builds: statistic.failedBuilds)}
''';
    }
    return result;
  }
}

/// A builder to build the pull request title and body for marking test flaky
class PullRequestBuilder {
  PullRequestBuilder({
    this.statistic,
    this.issue,
  });

  final BuilderStatistic statistic;
  final Issue issue;

  String get pullRequestTitle => 'Marks ${statistic.name} to be flaky';
  String get pullRequestBody => '${_buildHiddenMetaTags(name: statistic.name)}Issue link: ${issue.htmlUrl}\n';
}

/// A builder to build the pull request title and body for marking test flaky
class DeflakePullRequestBuilder {
  DeflakePullRequestBuilder({
    @required this.name,
    @required this.recordsAmount,
    this.issue,
  });

  final String name;
  final Issue issue;
  final int recordsAmount;

  String get pullRequestTitle => 'Marks $name to be not flaky';
  String get pullRequestBody {
    String body = _buildHiddenMetaTags(name: name);
    if (issue != null) {
      body += 'The issue ${issue.htmlUrl} has been closed, and the test has been passing for [$recordsAmount consecutive runs](${Uri.encodeFull('$_flakeRecordPrefix"$name"')}).\n';
    } else {
      body += 'The test has been passing for [$recordsAmount consecutive runs](${Uri.encodeFull('$_flakeRecordPrefix"$name"')}).\n';
    }
    body += 'This test can be marked as not flaky.\n';
    return body;
  }
}

// TESTOWNER Regex

const String kOwnerGroupName = 'owners';
final RegExp devicelabTestOwners =
    RegExp('## Linux Android DeviceLab tests\n(?<$kOwnerGroupName>.+)## Host only framework tests', dotAll: true);
final RegExp frameworkHostOnlyTestOwners =
    RegExp('## Host only framework tests\n(?<$kOwnerGroupName>.+)## Shards tests', dotAll: true);
final RegExp shardTestOwners = RegExp('## Shards tests\n(?<$kOwnerGroupName>.+)', dotAll: true);

// Utils methods

/// Gets the existing flaky issues.
///
/// The state can be 'open', 'closed', or 'all'.
Future<Map<String, Issue>> getExistingIssues(GithubService gitHub, RepositorySlug slug, {String state = 'all'}) async {
  final Map<String, Issue> nameToExistingIssue = <String, Issue>{};
  for (final Issue issue in await gitHub.listIssues(slug, state: state, labels: <String>[kTeamFlakeLabel])) {
    if (issue.htmlUrl?.contains('pull') == true) {
      // For some reason, this github api may also return pull requests.
      continue;
    }
    final Map<String, dynamic> metaTags = retrieveMetaTagsFromContent(issue.body);
    if (metaTags != null) {
      final String name = metaTags['name'] as String;
      if (!nameToExistingIssue.containsKey(name) || _isOtherIssueMoreImportant(nameToExistingIssue[name], issue)) {
        nameToExistingIssue[name] = issue;
      }
    }
  }
  return nameToExistingIssue;
}

/// Gets the existing open pull requests that make tests flaky.
Future<Map<String, PullRequest>> getExistingPRs(GithubService gitHub, RepositorySlug slug) async {
  final Map<String, PullRequest> nameToExistingPRs = <String, PullRequest>{};
  for (final PullRequest pr in await gitHub.listPullRequests(slug, null)) {
    final Map<String, dynamic> metaTags = retrieveMetaTagsFromContent(pr.body);
    if (metaTags != null) {
      nameToExistingPRs[metaTags['name'] as String] = pr;
    }
  }
  return nameToExistingPRs;
}

String getTestOwner(String builderName, BuilderType type, String testOwnersContent) {
  final String testName = _getTestNameFromBuilderName(builderName);
  String owner;
  switch (type) {
    case BuilderType.shard:
      {
        // The format looks like this:
        //   # build_tests @zanderso @flutter/tool
        final RegExpMatch match = shardTestOwners.firstMatch(testOwnersContent);
        if (match != null && match.namedGroup(kOwnerGroupName) != null) {
          final List<String> lines =
          match.namedGroup(kOwnerGroupName).split('\n').where((String line) => line.contains('@')).toList();

          for (final String line in lines) {
            final List<String> words = line.trim().split(' ');
            // e.g. words = ['#', 'build_test', '@zanderso' '@flutter/tool']
            if (testName.contains(words[1])) {
              owner = words[2].substring(1); // Strip out the lead '@'
              break;
            }
          }
        }
        break;
      }
    case BuilderType.devicelab:
      {
        // The format looks like this:
        //   /dev/devicelab/bin/tasks/dart_plugin_registry_test.dart @stuartmorgan @flutter/plugin
        final RegExpMatch match = devicelabTestOwners.firstMatch(testOwnersContent);
        if (match != null && match.namedGroup(kOwnerGroupName) != null) {
          final List<String> lines = match
              .namedGroup(kOwnerGroupName)
              .split('\n')
              .where((String line) => line.isNotEmpty || !line.startsWith('#'))
              .toList();

          for (final String line in lines) {
            final List<String> words = line.trim().split(' ');
            // e.g. words = ['/xxx/xxx/xxx_test.dart', '@stuartmorgan' '@flutter/tool']
            if (words[0].endsWith('$testName.dart')) {
              owner = words[1].substring(1); // Strip out the lead '@'
              break;
            }
          }
        }
        break;
      }
    case BuilderType.frameworkHostOnly:
      {
        // The format looks like this:
        //   # Linux analyze
        //   /dev/bots/analyze.dart @HansMuller @flutter/framework
        final RegExpMatch match = frameworkHostOnlyTestOwners.firstMatch(testOwnersContent);
        if (match != null && match.namedGroup(kOwnerGroupName) != null) {
          final List<String> lines =
          match.namedGroup(kOwnerGroupName).split('\n').where((String line) => line.isNotEmpty).toList();
          int index = 0;
          while (index < lines.length) {
            if (lines[index].startsWith('#') && index + 1 < lines.length) {
              final List<String> commentWords = lines[index].trim().split(' ');
              // e.g. commentWords = ['#', 'Linux' 'analyze']
              index += 1;
              if (lines[index].startsWith('#')) {
                // The next line should not be a comment. This can happen if
                // someone adds an additional comment to framework host only
                // session.
                continue;
              }
              if (testName.contains(commentWords[2])) {
                final List<String> ownerWords = lines[index].trim().split(' ');
                // e.g. ownerWords = ['/xxx/xxx/xxx_test.dart', '@HansMuller' '@flutter/framework']
                owner = ownerWords[1].substring(1); // Strip out the lead '@'
                break;
              }
            }
            index += 1;
          }
        }
        break;
      }
    case BuilderType.unknown:
      break;
  }
  return owner;
}

BuilderType getTypeForBuilder(String builderName, YamlMap ci) {
  final List<dynamic> tags = _getTags(builderName, ci);
  if (tags == null) {
    return BuilderType.unknown;
  }
  bool hasFrameworkTag = false;
  bool hasHostOnlyTag = false;
  // If tags contain 'shard', it must be a shard test.
  // If tags contain 'devicelab', it must be a devicelab test.
  // Otherwise, it is framework host only test if its tags contain both
  // 'framework' and 'hostonly'.
  for (dynamic tag in tags) {
    if (tag == kCiYamlTargetTagsShard) {
      return BuilderType.shard;
    } else if (tag == kCiYamlTargetTagsDevicelab) {
      return BuilderType.devicelab;
    } else if (tag == kCiYamlTargetTagsFramework) {
      hasFrameworkTag = true;
    } else if (tag == kCiYamlTargetTagsHostonly) {
      hasHostOnlyTag = true;
    }
  }
  return hasFrameworkTag && hasHostOnlyTag ? BuilderType.frameworkHostOnly : BuilderType.unknown;
}

List<dynamic> _getTags(String builderName, YamlMap ci) {
  final YamlList targets = ci[kCiYamlTargetsKey] as YamlList;
  final YamlMap target = targets.firstWhere(
        (dynamic element) => element[kCiYamlTargetBuilderKey] == builderName,
    orElse: () => null,
  ) as YamlMap;
  if (target == null) {
    return null;
  }
  return jsonDecode(target[kCiYamlPropertiesKey][kCiYamlTargetTagsKey] as String) as List<dynamic>;
}

String _getTestNameFromBuilderName(String builderName) {
  // The builder names is in the format '<platform> <test name>'.
  final List<String> words = builderName.split(' ');
  return words.length < 2 ? words[0] : words[1];
}

bool _isOtherIssueMoreImportant(Issue original, Issue other) {
  // Open issues are always more important than closed issues. If both issue
  // are closed, the one that is most recently created is more important.
  if (original.isOpen && other.isOpen) {
    throw 'There should not be two open issues for the same test';
  } else if (original.isOpen && other.isClosed) {
    return false;
  } else if (original.isClosed && other.isOpen) {
    return true;
  } else {
    return other.createdAt.isAfter(original.createdAt);
  }
}

String _buildHiddenMetaTags({String name}) {
  return '''<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY.
{
  "name": "$name"
}
-->
''';
}

final RegExp _issueHiddenMetaTagsRegex =
    RegExp(r'<!-- meta-tags: To be used by the automation script only, DO NOT MODIFY\.(?<meta>.+)-->', dotAll: true);

/// Checks whether the github content contains meta tags and returns the meta
/// tags if it does.
///
/// The script generated contents for issue bodies or pull request bodies
/// contain the meta tags. Using this method is a reliable way to check whether
/// a issue or pull request is generated by this script.
Map<String, dynamic> retrieveMetaTagsFromContent(String content) {
  final RegExpMatch match = _issueHiddenMetaTagsRegex.firstMatch(content);
  if (match == null) {
    return null;
  }
  return jsonDecode(match.namedGroup('meta')) as Map<String, dynamic>;
}

String _formatRate(double rate) => (rate * 100).toStringAsFixed(2);

String _issueBuildLinks({String builder, List<String> builds}) {
  return '${builds.map((String build) => _issueBuildLink(builder: builder, build: build)).join('\n')}';
}

String _issueBuildLink({String builder, String build}) {
  return Uri.encodeFull('$_buildPrefix$builder/$build');
}

enum BuilderType {
  devicelab,
  frameworkHostOnly,
  shard,
  unknown,
}