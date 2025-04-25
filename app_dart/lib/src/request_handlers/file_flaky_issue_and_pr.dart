// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../../ci_yaml.dart';
import '../../protos.dart' as pb;
import '../foundation/utils.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';
import '../service/big_query.dart';
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
  const FileFlakyIssueAndPR({
    required super.config,
    required super.authenticationProvider,
    required BigQueryService bigQuery,
  }) : _bigQuery = bigQuery;

  static const String kThresholdKey = 'threshold';

  final BigQueryService _bigQuery;

  @override
  Future<Body> get() async {
    final slug = Config.flutterSlug;
    final gitHub = config.createGithubServiceWithToken(
      await config.githubOAuthToken,
    );
    final builderStatisticList = await _bigQuery.listBuilderStatistic(
      kBigQueryProjectId,
    );
    final ci =
        loadYaml(await gitHub.getFileContent(slug, kCiYamlPath)) as YamlMap?;
    final unCheckedSchedulerConfig =
        pb.SchedulerConfig()..mergeFromProto3Json(ci);
    final ciYaml = CiYamlSet(
      slug: slug,
      branch: Config.defaultBranch(slug),
      yamls: {CiType.any: unCheckedSchedulerConfig},
    );

    final schedulerConfig = ciYaml.configFor(CiType.any);
    final targets = schedulerConfig.targets;

    final testOwnerContent = await gitHub.getFileContent(slug, kTestOwnerPath);
    final nameToExistingIssue = await getExistingIssues(gitHub, slug);
    final nameToExistingPR = await getExistingPRs(gitHub, slug);
    var filedIssueAndPRCount = 0;
    for (final statistic in builderStatisticList) {
      if (shouldSkip(statistic, ciYaml, targets)) {
        continue;
      }

      final type = getTypeForBuilder(statistic.name, ciYaml);
      final issueAndPRFiled = await _fileIssueAndPR(
        gitHub,
        slug,
        builderDetail: BuilderDetail(
          statistic: statistic,
          existingIssue: nameToExistingIssue[statistic.name],
          existingPullRequest: nameToExistingPR[statistic.name],
          isMarkedFlaky: _getIsMarkedFlaky(statistic.name, ci!),
          type: type,
          ownership: getTestOwnership(
            targets.singleWhere((element) => element.name == statistic.name),
            type,
            testOwnerContent,
          ),
        ),
      );
      if (issueAndPRFiled) {
        filedIssueAndPRCount++;
      }
      if (filedIssueAndPRCount == config.issueAndPRLimit) {
        break;
      }
    }
    return Body.forJson(<String, dynamic>{
      'Status': 'success',
      'NumberOfCreatedIssuesAndPRs': filedIssueAndPRCount,
    });
  }

  bool shouldSkip(
    BuilderStatistic statistic,
    CiYamlSet ciYaml,
    List<pb.Target> targets,
  ) {
    // Skips if the target has been removed from .ci.yaml.
    if (!targets.map((e) => e.name).toList().contains(statistic.name)) {
      return true;
    }
    // Skips if ignore_flakiness is specified.
    if (getIgnoreFlakiness(statistic.name, ciYaml)) {
      return true;
    }
    // Skips if the flaky percentage is below the threshold.
    final threshold =
        ciYaml.getFirstPostsubmitTarget(statistic.name)?.flakinessThreshold ??
        _threshold;
    if (statistic.flakyRate < threshold) {
      return true;
    }
    return false;
  }

  double get _threshold =>
      double.parse(request!.uri.queryParameters[kThresholdKey]!);

  Future<bool> _fileIssueAndPR(
    GithubService gitHub,
    RepositorySlug slug, {
    required BuilderDetail builderDetail,
  }) async {
    var issue = builderDetail.existingIssue;
    if (_shouldNotFileIssueAndPR(builderDetail, issue)) {
      return false;
    }
    // Manually add a 1s delay between consecutive GitHub requests to deal with secondary rate limit error.
    // https://docs.github.com/en/rest/guides/best-practices-for-integrators#dealing-with-secondary-rate-limits
    await Future<void>.delayed(config.githubRequestDelay);
    issue = await fileFlakyIssue(
      builderDetail: builderDetail,
      gitHub: gitHub,
      slug: slug,
      threshold: _threshold,
    );

    if (builderDetail.type == BuilderType.shard ||
        builderDetail.type == BuilderType.unknown ||
        builderDetail.existingPullRequest != null) {
      return true;
    }
    final modifiedContent = _marksBuildFlakyInContent(
      await gitHub.getFileContent(slug, kCiYamlPath),
      builderDetail.statistic.name,
      issue.htmlUrl,
    );
    final masterRef = await gitHub.getReference(slug, kMasterRefs);
    final prBuilder = PullRequestBuilder(
      statistic: builderDetail.statistic,
      ownership: builderDetail.ownership,
      issue: issue,
    );
    final pullRequest = await gitHub.createPullRequest(
      slug,
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
        ),
      ],
    );
    final label = getTeamLabelFromTeam(builderDetail.ownership.team);
    await gitHub.assignReviewer(
      slug,
      reviewer: prBuilder.pullRequestReviewer,
      pullRequestNumber: pullRequest.number,
    );
    if (label != null) {
      await gitHub.addIssueLabels(slug, pullRequest.number!, <String>[label]);
    }
    return true;
  }

  bool _shouldNotFileIssueAndPR(BuilderDetail builderDetail, Issue? issue) {
    // Don't create a new issue or deflake PR using prod builds statuses if the builder has been marked as flaky.
    // If the builder is `bringup: true`, but still hit flakes, a new bug will be filed in `/api/check_flaky_builders`
    // based on staging builds statuses.
    if (builderDetail.isMarkedFlaky) {
      return true;
    }

    // Don't create a new issue or deflake PR if there is an open issue or a recent closed
    // issue within kGracePeriodForClosedFlake days. It takes time for the flaky ratio to go
    // down after the fix is merged.
    if (issue != null &&
        (issue.state != 'closed' ||
            DateTime.now().difference(issue.closedAt!) <=
                const Duration(days: kGracePeriodForClosedFlake))) {
      return true;
    }

    return false;
  }

  bool _getIsMarkedFlaky(String builderName, YamlMap ci) {
    final targets = ci[kCiYamlTargetsKey] as YamlList;
    final target =
        targets.firstWhere(
              (dynamic element) => element[kCiYamlTargetNameKey] == builderName,
              orElse: () => null,
            )
            as YamlMap?;
    return target != null && target[kCiYamlTargetIsFlakyKey] == true;
  }

  @visibleForTesting
  static bool getIgnoreFlakiness(String builderName, CiYamlSet ciYaml) {
    final target = ciYaml.postsubmitTargets().singleWhereOrNull(
      (Target target) => target.name == builderName,
    );
    return target == null ? false : target.getIgnoreFlakiness();
  }

  String _marksBuildFlakyInContent(
    String content,
    String builder,
    String issueUrl,
  ) {
    final lines = content.split('\n');
    final builderLineNumber = lines.indexWhere(
      (String line) => line.contains('name: $builder'),
    );
    // Takes care the case if is kCiYamlTargetIsFlakyKey is already defined to false
    var nextLine = builderLineNumber + 1;
    while (nextLine < lines.length && !lines[nextLine].contains('name:')) {
      if (lines[nextLine].contains('$kCiYamlTargetIsFlakyKey:')) {
        lines[nextLine] = lines[nextLine].replaceFirst(
          'false',
          'true # Flaky $issueUrl',
        );
        return lines.join('\n');
      }
      nextLine += 1;
    }
    lines.insert(
      builderLineNumber + 1,
      '    $kCiYamlTargetIsFlakyKey: true # Flaky $issueUrl',
    );
    return lines.join('\n');
  }

  Future<RepositorySlug> getSlugFor(GitHub client, String repository) async {
    return RepositorySlug(
      (await client.users.getCurrentUser()).login!,
      repository,
    );
  }
}
