// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:cocoon_service/ci_yaml.dart';
import 'package:cocoon_service/src/request_handlers/test_ownership.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';

import '../service/bigquery.dart';
import '../service/github_service.dart';
import '../../protos.dart' as pb;

// String constants.
const String kFlakeLabel = 'c: flake';
const String kFrameworkLabel = 'team-framework';
const String kToolLabel = 'team-tool';
const String kEngineLabel = 'team-engine';
const String kWebLabel = 'team-web';
const String kInfraLabel = 'team-infra';
const String kAndroidLabel = 'team-android';
const String kIosLabel = 'team-ios';
const String kReleaseLabel = 'team-release';
const String kEcosystemLabel = 'team-ecosystem';
const String kP0Label = 'P0';
const String kP1Label = 'P1';
const String kP2Label = 'P2';
const String kP3Label = 'P3';

const String kBigQueryProjectId = 'flutter-dashboard';
const String kCiYamlTargetsKey = 'targets';
const String kCiYamlTargetNameKey = 'name';
const String kCiYamlTargetIgnoreFlakiness = 'ignore_flakiness';
const String kCiYamlTargetIsFlakyKey = 'bringup';
const String kCiYamlPropertiesKey = 'properties';
const String kCiYamlTargetTagsKey = 'tags';
const String kCiYamlTargetTagsShard = 'shard';
const String kCiYamlTargetTagsFirebaselab = 'firebaselab';
const String kCiYamlTargetTagsDevicelab = 'devicelab';
const String kCiYamlTargetTagsFramework = 'framework';
const String kCiYamlTargetTagsHostonly = 'hostonly';

const String kMasterRefs = 'heads/master';
const String kModifyMode = '100644'; // This is equivalent to mode: `-rw-r--r--`.
const String kModifyType = 'blob';

const int kSuccessBuildNumberLimit = 3;
const int kFlayRatioBuildNumberList = 10;
const double kDefaultFlakyRatioThreshold = 0.02;
const int kGracePeriodForClosedFlake = 15; // days

const String _commitPrefix = 'https://github.com/flutter/flutter/commit/';
const String _buildDashboardPrefix = 'https://flutter-dashboard.appspot.com/#/build';
const String _prodBuildPrefix = 'https://ci.chromium.org/ui/p/flutter/builders/prod/';
const String _stagingBuildPrefix = 'https://ci.chromium.org/ui/p/flutter/builders/staging/';
const String _flakeRecordPrefix =
    'https://data.corp.google.com/sites/flutter_infra_metrics_datasite/flutter_check_test_flakiness_status_dashboard/?p=BUILDER_NAME:';

/// A builder to build a new issue for a flake.
class IssueBuilder {
  IssueBuilder({
    required this.statistic,
    required this.ownership,
    required this.threshold,
    this.bringup = false,
  });

  final BuilderStatistic statistic;
  final TestOwnership ownership;
  final double threshold;
  final bool bringup;

  Bucket get buildBucket {
    return bringup ? Bucket.staging : Bucket.prod;
  }

  String get issueTitle {
    return '${statistic.name} is ${_formatRate(statistic.flakyRate)}% flaky';
  }

  String? get issueAssignee {
    return ownership.owner;
  }

  /// Return `kSuccessBuildNumberLimit` successful builds if there are more. Otherwise return what's available.
  int numberOfSuccessBuilds(int numberOfAvailableSuccessBuilds) {
    return numberOfAvailableSuccessBuilds >= kSuccessBuildNumberLimit
        ? kSuccessBuildNumberLimit
        : numberOfAvailableSuccessBuilds;
  }

  String get issueBody {
    return '''
${_buildHiddenMetaTags(name: statistic.name)}
${_issueSummary(statistic, threshold, bringup)}

One recent flaky example for a same commit: ${_issueBuildLink(builder: statistic.name, build: statistic.flakyBuildOfRecentCommit, bucket: buildBucket)}
Commit: $_commitPrefix${statistic.recentCommit}

Flaky builds:
${_issueBuildLinks(builder: statistic.name, builds: statistic.flakyBuilds!, bucket: buildBucket)}

Recent test runs:
${_issueBuilderLink(statistic.name)}

Please follow https://github.com/flutter/flutter/wiki/Reducing-Test-Flakiness#fixing-flaky-tests to fix the flakiness and enable the test back after validating the fix (internal dashboard to validate: go/flutter_test_flakiness).
''';
  }

  List<String> get issueLabels {
    final List<String> labels = <String>[
      kFlakeLabel,
      kP0Label,
    ];
    final String? teamLabel = getTeamLabelFromTeam(ownership.team);
    if (teamLabel != null && teamLabel.isNotEmpty == true) {
      labels.add(teamLabel);
    }
    return labels;
  }
}

/// A builder to build the update comment and labels for an existing open flaky
/// issue.
class IssueUpdateBuilder {
  IssueUpdateBuilder({
    required this.statistic,
    required this.threshold,
    required this.existingIssue,
    required this.bucket,
  });

  final BuilderStatistic statistic;
  final double threshold;
  final Issue existingIssue;
  final Bucket bucket;

  bool get isBelow => statistic.flakyRate < threshold;

  String get bucketString => bucket.toString().split('.').last;

  List<String> get issueLabels {
    final List<String> existingLabels = existingIssue.labels.map<String>((IssueLabel label) => label.name).toList();
    // Update the priority.
    if (!existingLabels.contains(kP0Label) && !isBelow) {
      existingLabels.add(kP0Label);
      existingLabels.remove(kP1Label);
      existingLabels.remove(kP2Label);
      existingLabels.remove(kP3Label);
    }
    return existingLabels;
  }

  String get issueUpdateComment {
    String result =
        '[$bucketString pool] flaky ratio for the past (up to) 100 commits between ${statistic.fromDate} and ${statistic.toDate} is ${_formatRate(statistic.flakyRate)}%. Flaky number: ${statistic.flakyNumber}; total number: ${statistic.totalNumber}.\n';
    if (statistic.flakyRate > 0.0) {
      result += '''
One recent flaky example for a same commit: ${_issueBuildLink(builder: statistic.name, build: statistic.flakyBuildOfRecentCommit, bucket: bucket)}
Commit: $_commitPrefix${statistic.recentCommit}
Flaky builds:
${_issueBuildLinks(builder: statistic.name, builds: statistic.flakyBuilds!, bucket: bucket)}

Recent test runs:
${_issueBuilderLink(statistic.name)}
''';
    }
    return result;
  }
}

/// A builder to build the pull request title and body for marking test flaky
class PullRequestBuilder {
  PullRequestBuilder({
    required this.statistic,
    required this.ownership,
    required this.issue,
  });

  final BuilderStatistic statistic;
  final TestOwnership ownership;
  final Issue issue;

  String get pullRequestTitle => 'Marks ${statistic.name} to be flaky';
  String get pullRequestBody => '${_buildHiddenMetaTags(name: statistic.name)}Issue link: ${issue.htmlUrl}\n';
  String? get pullRequestReviewer => ownership.owner;
}

/// A builder to build the pull request title and body for marking test unflaky
class DeflakePullRequestBuilder {
  DeflakePullRequestBuilder({
    required this.name,
    required this.recordNumber,
    required this.ownership,
    this.issue,
  });

  final String? name;
  final Issue? issue;
  final TestOwnership ownership;
  final int recordNumber;

  String get pullRequestTitle => 'Marks $name to be unflaky';
  String get pullRequestBody {
    String body = _buildHiddenMetaTags(name: name);
    if (issue != null) {
      body +=
          'The issue ${issue!.htmlUrl} has been closed, and the test has been passing for [$recordNumber consecutive runs](${Uri.encodeFull('$_flakeRecordPrefix"$name"')}).\n';
    } else {
      body +=
          'The test has been passing for [$recordNumber consecutive runs](${Uri.encodeFull('$_flakeRecordPrefix"$name"')}).\n';
    }
    body += 'This test can be marked as unflaky.\n';
    return body;
  }

  String? get pullRequestReviewer => ownership.owner;
}

// TESTOWNER Regex

const String kOwnerGroupName = 'owners';
final RegExp devicelabTestOwners =
    RegExp('## Linux Android DeviceLab tests\n(?<$kOwnerGroupName>.+)## Host only framework tests', dotAll: true);
final RegExp frameworkHostOnlyTestOwners =
    RegExp('## Host only framework tests\n(?<$kOwnerGroupName>.+)## Firebase tests', dotAll: true);
final RegExp firebaselabTestOwners = RegExp('## Firebase tests\n(?<$kOwnerGroupName>.+)## Shards tests', dotAll: true);
final RegExp shardTestOwners = RegExp('## Shards tests\n(?<$kOwnerGroupName>.+)', dotAll: true);

// Utils methods

/// Gets the existing flaky issues.
///
/// The state can be 'open', 'closed', or 'all'.
Future<Map<String?, Issue>> getExistingIssues(GithubService gitHub, RepositorySlug slug, {String state = 'all'}) async {
  final Map<String?, Issue> nameToExistingIssue = <String?, Issue>{};
  for (final Issue issue in await gitHub.listIssues(slug, state: state, labels: <String>[kFlakeLabel])) {
    if (issue.htmlUrl.contains('pull') == true) {
      // For some reason, this github api may also return pull requests.
      continue;
    }
    final Map<String, dynamic>? metaTags = retrieveMetaTagsFromContent(issue.body);
    if (metaTags != null) {
      final String? name = metaTags['name'] as String?;
      if (!nameToExistingIssue.containsKey(name) || _isOtherIssueMoreImportant(nameToExistingIssue[name]!, issue)) {
        nameToExistingIssue[name] = issue;
      }
    }
  }
  return nameToExistingIssue;
}

/// Gets the existing open pull requests that make tests flaky.
Future<Map<String?, PullRequest>> getExistingPRs(GithubService gitHub, RepositorySlug slug) async {
  final Map<String?, PullRequest> nameToExistingPRs = <String?, PullRequest>{};
  for (final PullRequest pr in await gitHub.listPullRequests(slug, null)) {
    try {
      if (pr.body == null) {
        continue;
      }
      final Map<String, dynamic>? metaTags = retrieveMetaTagsFromContent(pr.body!);
      if (metaTags != null) {
        nameToExistingPRs[metaTags['name'] as String] = pr;
      }
    } catch (e) {
      throw 'Unable to parse body of ${pr.htmlUrl}\n$e';
    }
  }
  return nameToExistingPRs;
}

/// File a GitHub flaky issue based on builder details in recent prod/staging runs.
Future<Issue> fileFlakyIssue({
  required BuilderDetail builderDetail,
  required GithubService gitHub,
  required RepositorySlug slug,
  double threshold = kDefaultFlakyRatioThreshold,
  bool bringup = false,
}) async {
  final IssueBuilder issueBuilder = IssueBuilder(
    statistic: builderDetail.statistic,
    ownership: builderDetail.ownership,
    threshold: kDefaultFlakyRatioThreshold,
    bringup: bringup,
  );
  return gitHub.createIssue(
    slug,
    title: issueBuilder.issueTitle,
    body: issueBuilder.issueBody,
    labels: issueBuilder.issueLabels,
    assignee: issueBuilder.issueAssignee,
  );
}

/// Looks up the owner of a builder in TESTOWNERS file.
TestOwnership getTestOwnership(pb.Target target, BuilderType type, String testOwnersContent) {
  final TestOwner testOwner = TestOwner(type);
  return testOwner.getTestOwnership(target, testOwnersContent);
}

/// Gets the [BuilderType] of the builder by looking up the information in the
/// ci.yaml.
BuilderType getTypeForBuilder(String? targetName, CiYaml ciYaml, {bool unfilteredTargets = false}) {
  final List<String>? tags = _getTags(targetName, ciYaml, unfilteredTargets: unfilteredTargets);
  if (tags == null || tags.isEmpty) {
    return BuilderType.unknown;
  }

  bool hasFrameworkTag = false;
  bool hasHostOnlyTag = false;
  // If tags contain 'shard', it must be a shard test.
  // If tags contain 'devicelab', it must be a devicelab test.
  // If tags contain 'firebaselab`, it must be a firebase tests.
  // Otherwise, it is framework host only test if its tags contain both
  // 'framework' and 'hostonly'.
  for (String tag in tags) {
    if (tag == kCiYamlTargetTagsFirebaselab) {
      return BuilderType.firebaselab;
    } else if (tag == kCiYamlTargetTagsShard) {
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

List<String>? _getTags(String? targetName, CiYaml ciYaml, {bool unfilteredTargets = false}) {
  final Set<Target> allUniqueTargets = {};
  if (!unfilteredTargets) {
    allUniqueTargets.addAll(ciYaml.presubmitTargets);
    allUniqueTargets.addAll(ciYaml.postsubmitTargets);
  } else {
    allUniqueTargets.addAll(ciYaml.targets);
  }

  final Target? target = allUniqueTargets.firstWhereOrNull((element) => element.value.name == targetName);
  return target?.tags;
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
    return other.createdAt!.isAfter(original.createdAt!);
  }
}

String _buildHiddenMetaTags({String? name}) {
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
Map<String, dynamic>? retrieveMetaTagsFromContent(String content) {
  final RegExpMatch? match = _issueHiddenMetaTagsRegex.firstMatch(content);
  if (match == null) {
    return null;
  }
  return jsonDecode(match.namedGroup('meta')!) as Map<String, dynamic>?;
}

String _formatRate(double rate) => (rate * 100).toStringAsFixed(2);

String _issueBuildLinks({String? builder, required List<String> builds, Bucket bucket = Bucket.prod}) {
  return builds.map((String build) => _issueBuildLink(builder: builder, build: build, bucket: bucket)).join('\n');
}

String _issueSummary(BuilderStatistic statistic, double threshold, bool bringup) {
  final String summary;
  if (bringup) {
    summary =
        'The post-submit test builder `${statistic.name}`, which has been marked `bringup: true`, had ${statistic.flakyNumber} flakes over past ${statistic.totalNumber} commits.';
  } else {
    summary =
        'The post-submit test builder `${statistic.name}` had a flaky ratio ${_formatRate(statistic.flakyRate)}% for the past (up to) 100 commits, which is above our ${_formatRate(threshold)}% threshold.';
  }
  return summary;
}

String _issueBuildLink({String? builder, String? build, Bucket bucket = Bucket.prod}) {
  final String buildPrefix = bucket == Bucket.staging ? _stagingBuildPrefix : _prodBuildPrefix;
  return Uri.encodeFull('$buildPrefix$builder/$build');
}

String _issueBuilderLink(String? builder) {
  return Uri.encodeFull('$_buildDashboardPrefix?taskFilter=$builder');
}

String? getTeamLabelFromTeam(Team? team) {
  return switch (team) {
    Team.framework => kFrameworkLabel,
    Team.engine => kEngineLabel,
    Team.tool => kToolLabel,
    Team.web => kWebLabel,
    Team.infra => kInfraLabel,
    Team.android => kAndroidLabel,
    Team.ios => kIosLabel,
    Team.release => kReleaseLabel,
    Team.plugins => kEcosystemLabel,
    Team.unknown => null,
    null => null,
  };
}

enum BuilderType {
  devicelab,
  frameworkHostOnly,
  shard,
  firebaselab,
  unknown,
}

enum Bucket {
  prod,
  staging,
}

enum Team {
  framework,
  engine,
  tool,
  web,
  infra,
  android,
  ios,
  release,
  plugins,
  unknown,
}

class TestOwnership {
  TestOwnership(
    this.owner,
    this.team,
  );
  String? owner;
  Team? team;
}

class BuilderDetail {
  const BuilderDetail({
    required this.statistic,
    required this.existingIssue,
    required this.existingPullRequest,
    required this.isMarkedFlaky,
    required this.ownership,
    required this.type,
  });
  final BuilderStatistic statistic;
  final Issue? existingIssue;
  final PullRequest? existingPullRequest;
  final TestOwnership ownership;
  final bool isMarkedFlaky;
  final BuilderType type;
}
