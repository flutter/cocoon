// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../foundation/utils.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/bigquery.dart';
import '../service/config.dart';
import '../service/github_service.dart';
import 'flaky_handler_utils.dart';

/// A handler that queries build statistics from luci and file issues and pull
/// requests for tests that have high flaky ratios.
///
/// The query parameter kThresholdKey is required for this handler to use it as
/// the standard when compares the flaky ratios.
@immutable
class FileFlakyIssueAndPR extends ApiRequestHandler<Body> {
  const FileFlakyIssueAndPR(Config config, AuthenticationProvider authenticationProvider)
      : super(config: config, authenticationProvider: authenticationProvider);

  static const String kThresholdKey = 'threshold';

  static const int kGracePeriodForClosedFlake = 15; // days

  @override
  Future<Body> get() async {
    final RepositorySlug slug = config.flutterSlug;
    final GithubService gitHub = config.createGithubServiceWithToken(await config.githubOAuthToken);
    final BigqueryService bigquery = await config.createBigQueryService();
    final List<BuilderStatistic> builderStatisticList = await bigquery.listBuilderStatistic(kBigQueryProjectId);
    final YamlMap ci = loadYaml(await gitHub.getFileContent(slug, kCiYamlPath)) as YamlMap;
    final String testOwnerContent = await gitHub.getFileContent(slug, kTestOwnerPath);
    final Map<String, Issue> nameToExistingIssue = await getExistingIssues(gitHub, slug);
    final Map<String, PullRequest> nameToExistingPR = await getExistingPRs(gitHub, slug);
    for (final BuilderStatistic statistic in builderStatisticList) {
      if (statistic.flakyRate < _threshold) {
        continue;
      }
      final BuilderType type = getTypeForBuilder(statistic.name, ci);
      await _fileIssueAndPR(
        gitHub,
        slug,
        builderDetail: _BuilderDetail(
            statistic: statistic,
            existingIssue: nameToExistingIssue[statistic.name],
            existingPullRequest: nameToExistingPR[statistic.name],
            isMarkedFlaky: _getIsMarkedFlaky(statistic.name, ci),
            type: type,
            owner: getTestOwner(statistic.name, type, testOwnerContent)),
      );
    }
    return Body.forJson(const <String, dynamic>{
      'Status': 'success',
    });
  }

  double get _threshold => double.parse(request.uri.queryParameters[kThresholdKey]);

  Future<void> _fileIssueAndPR(
    GithubService gitHub,
    RepositorySlug slug, {
    @required _BuilderDetail builderDetail,
  }) async {
    Issue issue = builderDetail.existingIssue;
    // Don't create a new issue if there is a recent closed issue within
    // kGracePeriodForClosedFlake days. It takes time for the flaky ratio to go
    // down after the fix is merged.
    if (issue == null ||
        (issue.state == 'closed' &&
            DateTime.now().difference(issue.closedAt) > const Duration(days: kGracePeriodForClosedFlake))) {
      final IssueBuilder issueBuilder = IssueBuilder(statistic: builderDetail.statistic, threshold: _threshold);
      issue = await gitHub.createIssue(
        slug,
        title: issueBuilder.issueTitle,
        body: issueBuilder.issueBody,
        labels: issueBuilder.issueLabels,
        assignee: builderDetail.owner,
      );
    }

    if (issue == null ||
        builderDetail.type == BuilderType.shard ||
        builderDetail.existingPullRequest != null ||
        builderDetail.isMarkedFlaky) {
      return;
    }
    final String modifiedContent = _marksBuildFlakyInContent(
        await gitHub.getFileContent(slug, kCiYamlPath), builderDetail.statistic.name, issue.htmlUrl);
    final GitReference masterRef = await gitHub.getReference(slug, kMasterRefs);
    final PullRequestBuilder prBuilder = PullRequestBuilder(statistic: builderDetail.statistic, issue: issue);
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
    await gitHub.assignReviewer(slug, reviewer: builderDetail.owner, pullRequestNumber: pullRequest.number);
  }

  bool _getIsMarkedFlaky(String builderName, YamlMap ci) {
    final YamlList targets = ci[kCiYamlTargetsKey] as YamlList;
    final YamlMap target = targets.firstWhere(
      (dynamic element) => element[kCiYamlTargetNameKey] == builderName,
      orElse: () => null,
    ) as YamlMap;
    return target != null && target[kCiYamlTargetIsFlakyKey] == true;
  }

  String _marksBuildFlakyInContent(String content, String builder, String issueUrl) {
    final List<String> lines = content.split('\n');
    final int builderLineNumber = lines.indexWhere((String line) => line.contains('builder: $builder'));
    // Takes care the case if is kCiYamlTargetIsFlakyKey is already defined to false
    int nextLine = builderLineNumber + 1;
    while (nextLine < lines.length && !lines[nextLine].contains('builder:')) {
      if (lines[nextLine].contains('$kCiYamlTargetIsFlakyKey:')) {
        lines[nextLine] = lines[nextLine].replaceFirst('false', 'true # Flaky $issueUrl');
        return lines.join('\n');
      }
      nextLine += 1;
    }
    lines.insert(builderLineNumber + 1, '    $kCiYamlTargetIsFlakyKey: true # Flaky $issueUrl');
    return lines.join('\n');
  }

  Future<RepositorySlug> getSlugFor(GitHub client, String repository) async {
    return RepositorySlug((await client.users.getCurrentUser()).login, repository);
  }
}

class _BuilderDetail {
  const _BuilderDetail({
    @required this.statistic,
    @required this.existingIssue,
    @required this.existingPullRequest,
    @required this.isMarkedFlaky,
    @required this.owner,
    @required this.type,
  });
  final BuilderStatistic statistic;
  final Issue existingIssue;
  final PullRequest existingPullRequest;
  final String owner;
  final bool isMarkedFlaky;
  final BuilderType type;
}
