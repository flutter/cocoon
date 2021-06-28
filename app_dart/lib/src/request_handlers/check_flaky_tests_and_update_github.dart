// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/bigquery.dart';
import '../service/config.dart';
import '../service/github_service.dart';

import 'check_flaky_tests_and_update_github_utils.dart';

@immutable
class CheckForFlakyTestAndUpdateGithub extends ApiRequestHandler<Body> {
  const CheckForFlakyTestAndUpdateGithub(Config config, AuthenticationProvider authenticationProvider)
      : super(config: config, authenticationProvider: authenticationProvider);

  static const String kBigQueryProjectId = 'flutter-dashboard';

  static const String kThresholdKey = 'threshold';
  static const String kCiYamlPath = '.ci.yaml';
  static const String _ciYamlTargetsKey = 'targets';
  static const String _ciYamlTargetBuilderKey = 'builder';
  static const String _ciYamlTargetIsFlakyKey = 'bringup';
  static const String kTestOwnerPath = 'TESTOWNERS';
  static const String kMasterRefs = 'heads/master';
  static const String kModifyMode = '100755';
  static const String kModifyType = 'blob';

  static const int kGracePeriodForClosedFlake = 15; // days

  @override
  Future<Body> get() async {
    try {
      final RepositorySlug slug = config.flutterSlug;
      final GithubService gitHub = config.createGithubServiceWithToken(await config.githubFlakyBotOAuthToken);
      final BigqueryService bigquery = await config.createBigQueryService();
      final List<BuilderStatistic> builderStatisticList = await bigquery.listBuilderStatistic(kBigQueryProjectId);
      final Map<String, String> builderNameToOwner =
          await _findTestOwners(gitHub, slug, builderStatisticList.map((BuilderStatistic s) => s.name).toList());
      final Map<String, Issue> nameToExistingIssue = await _getExistingIssues(gitHub, slug);
      final Map<String, PullRequest> nameToExistingPR = await _getExistingPRs(gitHub, slug);
      // Finds the important flakes whose flaky rate > threshold or the most flaky test
      // if all of the flakes < threshold.
      final Set<String> importantFlakes = _getImportantFlakes(builderStatisticList, _threshold);
      // Makes sure every important flake has an github issue and a pr to mark
      // the test flaky.
      for (final BuilderStatistic statistic in builderStatisticList) {
        if (importantFlakes.contains(statistic.name)) {
          await _updateFlakes(
            gitHub,
            slug,
            owner: builderNameToOwner[statistic.name],
            existingIssues: nameToExistingIssue[statistic.name],
            hasExistingPR: nameToExistingPR.containsKey(statistic.name),
            statistic: statistic,
          );
        }
      }
    } catch (e, stack) {
      return Body.forJson(<String, dynamic>{
        'Statuses': e.toString(),
        'stack': stack.toString(),
      });
    }
    return Body.forJson(const <String, dynamic>{
      'Statuses': 'success',
    });
  }

  double get _threshold => double.parse(request.uri.queryParameters[kThresholdKey]);

  Future<Map<String, String>> _findTestOwners(GithubService gitHub, RepositorySlug slug, List<String> builders) async {
    final String testOwnerContent = await gitHub.getFileContent(slug, kTestOwnerPath);
    final Map<String, String> result = <String, String>{};
    for (final String builder in builders) {
      final String testName = _getTestNameFromBuilderName(builder);
      result[builder] = _findTestOwner(testName, testOwnerContent);
    }
    return result;
  }

  Future<Map<String, Issue>> _getExistingIssues(GithubService gitHub, RepositorySlug slug) async {
    final Map<String, Issue> nameToExistingIssue = <String, Issue>{};
    for (final Issue issue in await gitHub.listIssues(slug, state: 'all', labels: <String>[kTeamFlakeLabel])) {
      final RegExpMatch match = IssueBuilder.issueTitleRegex.firstMatch(issue.title);
      if (match != null) {
        if (!nameToExistingIssue.containsKey(match.namedGroup('name')) ||
            _isOtherIssueMoreImportant(nameToExistingIssue[match.namedGroup('name')], issue)) {
          nameToExistingIssue[match.namedGroup('name')] = issue;
        }
      }
    }
    return nameToExistingIssue;
  }

  Future<Map<String, PullRequest>> _getExistingPRs(GithubService gitHub, RepositorySlug slug) async {
    final Map<String, PullRequest> nameToExistingPRs = <String, PullRequest>{};
    for (final PullRequest pr in await gitHub.listPullRequests(slug, null)) {
      final RegExpMatch match = pullRequestTitleRegex.firstMatch(pr.title);
      if (match != null) {
        nameToExistingPRs[match.namedGroup('name')] = pr;
      }
    }
    return nameToExistingPRs;
  }

  Set<String> _getImportantFlakes(List<BuilderStatistic> statisticList, double threshold) {
    final Set<String> importantFlakes = <String>{};
    for (final BuilderStatistic statistic in statisticList) {
      if (statistic.flakyRate > threshold) {
        importantFlakes.add(statistic.name);
      }
    }
    if (importantFlakes.isNotEmpty) {
      return importantFlakes;
    }
    // No flake is above threshold.
    BuilderStatistic mostImportant;
    for (final BuilderStatistic statistic in statisticList) {
      if (mostImportant == null || mostImportant.flakyRate < statistic.flakyRate) {
        mostImportant = statistic;
      }
    }
    return <String>{
      if (mostImportant != null) mostImportant.name,
    };
  }

  Future<void> _updateFlakes(
    GithubService gitHub,
    RepositorySlug slug, {
    @required BuilderStatistic statistic,
    @required String owner,
    @required Issue existingIssues,
    @required bool hasExistingPR,
  }) async {
    // Don't create a new issue if there is a recent closed issue within
    // kGracePeriodForClosedFlake days. It takes time for the flaky ratio to go
    // down after the fix is merged.
    Issue issue = existingIssues;
    if (issue == null ||
        (issue.state == 'closed' &&
            DateTime.now().difference(issue.closedAt) > const Duration(days: kGracePeriodForClosedFlake))) {
      final IssueBuilder issueBuilder = IssueBuilder(statistic: statistic, threshold: _threshold, isImportant: true);
      issue = await gitHub.createIssue(
        slug,
        title: issueBuilder.issueTitle,
        body: issueBuilder.issueBody,
        labels: issueBuilder.issueLabels,
        assignee: owner,
      );
    }
    if (issue != null) {
      if (!hasExistingPR && !await _isAlreadyMarkedFlaky(gitHub, slug, statistic.name)) {
        final String modifiedContent =
            _marksBuildFlakyInContent(await gitHub.getFileContent(slug, kCiYamlPath), statistic.name, issue.htmlUrl);
        final GitReference masterRef = await gitHub.getReference(slug, kMasterRefs);
        final PullRequestBuilder prBuilder = PullRequestBuilder(statistic: statistic, issue: issue);
        final PullRequest pullRequest = await gitHub.createPullRequest(slug,
            title: prBuilder.pullRequestTitle,
            body: prBuilder.pullRequestBody,
            commitMessage: prBuilder.pullRequestTitle,
            baseRef: masterRef,
            entries: <CreateGitTreeEntry>[
              CreateGitTreeEntry(
                kCiYamlPath,
                kModifyMode,
                kModifyType,
                content: modifiedContent,
              )
            ]);
        await gitHub.assignReviewer(slug, reviewer: owner, pullRequestNumber: pullRequest.number);
      }
    }
  }

  Future<bool> _isAlreadyMarkedFlaky(GithubService gitHub, RepositorySlug slug, String builderName) async {
    final YamlMap content = loadYaml(await gitHub.getFileContent(slug, kCiYamlPath)) as YamlMap;
    final YamlList targets = content[_ciYamlTargetsKey] as YamlList;
    final YamlMap target = targets.firstWhere(
      (dynamic element) => element[_ciYamlTargetBuilderKey] == builderName,
    ) as YamlMap;
    return target[_ciYamlTargetIsFlakyKey] == true;
  }

  bool _isOtherIssueMoreImportant(Issue original, Issue other) {
    // Open issues are always more important than closed issues. If both issue
    // are closed, the one that is most recent created is more important.
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

  String _getTestNameFromBuilderName(String builderName) {
    // The builder names is in the format '<platform> <test name>'.
    final List<String> words = builderName.split(' ');
    return words.length < 2 ? words[0] : words[1];
  }

  String _findTestOwner(String testName, String testOwnersContent) {
    final List<String> lines = testOwnersContent.split('\n');
    String owner;
    for (final String line in lines) {
      if (line.startsWith('#')) {
        continue;
      }
      if (line.trim().isEmpty) {
        continue;
      }
      final List<String> words = line.trim().split(' ');
      if (words[0].contains(testName)) {
        owner = words[1].substring(1); // Strip out the lead '@'
      }
    }
    return owner;
  }

  String _marksBuildFlakyInContent(String content, String builder, String issueUrl) {
    final List<String> lines = content.split('\n');
    final int builderLineNumber = lines.indexWhere((String line) => line.contains('builder: $builder'));
    // Takes care the case if is _ciYamlTargetIsFlakyKey is already defined to false
    int nextLine = builderLineNumber + 1;
    while (nextLine < lines.length && !lines[nextLine].contains('builder:')) {
      if (lines[nextLine].contains('$_ciYamlTargetIsFlakyKey:')) {
        lines[nextLine] = lines[nextLine].replaceFirst('false', 'true // Flaky $issueUrl');
        return lines.join('\n');
      }
      nextLine += 1;
    }
    lines.insert(builderLineNumber + 1, '    $_ciYamlTargetIsFlakyKey: true // Flaky $issueUrl');
    return lines.join('\n');
  }

  Future<RepositorySlug> getSlugFor(GitHub client, String repository) async {
    return RepositorySlug((await client.users.getCurrentUser()).login, repository);
  }
}
