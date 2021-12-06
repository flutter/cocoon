// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../../protos.dart' as pb;
import '../foundation/utils.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/authentication.dart';
import '../request_handling/body.dart';
import '../service/bigquery.dart';
import '../service/config.dart';
import '../service/github_service.dart';
import '../service/scheduler/graph.dart';
import 'flaky_handler_utils.dart';

/// This handler updates existing open flaky issues with the latest build
/// statistics.
///
/// The query parameter kThresholdKey is required in order for the handler to
/// properly adjusts the priority labels.
@immutable
class UpdateExistingFlakyIssue extends ApiRequestHandler<Body> {
  const UpdateExistingFlakyIssue(Config config, AuthenticationProvider authenticationProvider)
      : super(config: config, authenticationProvider: authenticationProvider);

  static const String kThresholdKey = 'threshold';
  static const int kFreshPeriodForOpenFlake = 7; // days

  @override
  Future<Body> get() async {
    final RepositorySlug slug = Config.flutterSlug;
    final GithubService gitHub = config.createGithubServiceWithToken(await config.githubOAuthToken);
    final BigqueryService bigquery = await config.createBigQueryService();
    final YamlMap? ci = loadYaml(await gitHub.getFileContent(slug, kCiYamlPath)) as YamlMap?;
    final pb.SchedulerConfig schedulerConfig = schedulerConfigFromYaml(ci);

    final List<BuilderStatistic> prodBuilderStatisticList =
        await bigquery.listBuilderStatistic(kBigQueryProjectId, bucket: 'prod');
    final List<BuilderStatistic> stagingBuilderStatisticList =
        await bigquery.listBuilderStatistic(kBigQueryProjectId, bucket: 'staging');
    final Map<String?, Issue> nameToExistingIssue = await getExistingIssues(gitHub, slug, state: 'open');
    await _updateExistingFlakyIssue(
      gitHub,
      slug,
      schedulerConfig,
      prodBuilderStatisticList: prodBuilderStatisticList,
      stagingBuilderStatisticList: stagingBuilderStatisticList,
      nameToExistingIssue: nameToExistingIssue,
    );
    return Body.forJson(const <String, dynamic>{
      'Status': 'success',
    });
  }

  double get _threshold => double.parse(request!.uri.queryParameters[kThresholdKey]!);

  /// Adds an update comment and adjusts the labels of the existing issue based
  /// on the latest statistics.
  ///
  /// This method skips issues that are created within kFreshPeriodForOpenFlake
  /// days.
  Future<void> _addCommentToExistingIssue(
    GithubService gitHub,
    RepositorySlug slug, {
    required Bucket bucket,
    required BuilderStatistic statistic,
    required Issue existingIssue,
  }) async {
    if (DateTime.now().difference(existingIssue.createdAt!) < const Duration(days: kFreshPeriodForOpenFlake)) {
      return;
    }
    final IssueUpdateBuilder updateBuilder =
        IssueUpdateBuilder(statistic: statistic, threshold: _threshold, existingIssue: existingIssue, bucket: bucket);
    await gitHub.createComment(slug, issueNumber: existingIssue.number, body: updateBuilder.issueUpdateComment);
    await gitHub.replaceLabelsForIssue(slug, issueNumber: existingIssue.number, labels: updateBuilder.issueLabels);
    if (existingIssue.assignee == null && !updateBuilder.isBelow) {
      final String ciContent = await gitHub.getFileContent(slug, kCiYamlPath);
      final String testOwnerContent = await gitHub.getFileContent(slug, kTestOwnerPath);
      final String? testOwner = getTestOwnership(
              statistic.name, getTypeForBuilder(statistic.name, loadYaml(ciContent) as YamlMap), testOwnerContent)
          .owner;
      if (testOwner != null) {
        await gitHub.assignIssue(slug, issueNumber: existingIssue.number, assignee: testOwner);
      }
    }
  }

  /// Updates existing flaky issues based on corrresponding builder stats.
  Future<void> _updateExistingFlakyIssue(
    GithubService gitHub,
    RepositorySlug slug,
    pb.SchedulerConfig schedulerConfig, {
    required List<BuilderStatistic> prodBuilderStatisticList,
    required List<BuilderStatistic> stagingBuilderStatisticList,
    required Map<String?, Issue> nameToExistingIssue,
  }) async {
    final Map<String, bool> builderFlakyMap = <String, bool>{};
    for (pb.Target target in schedulerConfig.targets) {
      builderFlakyMap[target.name] = target.bringup;
    }
    // For prod builder stats, updates an existing flaky bug when the builder is not marked as flaky.
    //
    // If a builder is marked as flaky, it is expected to run in `staging` pool.
    // It is possible that a flaky bug exists for a builder, but the builder is not marked as flaky,
    // such as a shard builder. For this case, it is still running in `prod` pool.
    for (final BuilderStatistic statistic in prodBuilderStatisticList) {
      if (nameToExistingIssue.containsKey(statistic.name) &&
          builderFlakyMap.containsKey(statistic.name) &&
          builderFlakyMap[statistic.name] == false &&
          _buildsAreEnough(statistic)) {
        await _addCommentToExistingIssue(gitHub, slug,
            bucket: _getBucket(builderFlakyMap, statistic.name),
            statistic: statistic,
            existingIssue: nameToExistingIssue[statistic.name]!);
      }
    }
    // For all staging builder stats, updates any existing flaky bug.
    for (final BuilderStatistic statistic in stagingBuilderStatisticList) {
      if (nameToExistingIssue.containsKey(statistic.name) && _buildsAreEnough(statistic)) {
        await _addCommentToExistingIssue(gitHub, slug,
            bucket: _getBucket(builderFlakyMap, statistic.name),
            statistic: statistic,
            existingIssue: nameToExistingIssue[statistic.name]!);
      }
    }
  }

  /// Check if there are enough builds to calculate the flaky ratio.
  ///
  /// Default threshold is [kFlayRatioBuildNumberList].
  bool _buildsAreEnough(BuilderStatistic statistic) {
    return statistic.flakyBuilds!.length + statistic.succeededBuilds!.length >= kFlayRatioBuildNumberList;
  }

  /// Return bucket info for the builder runs.
  Bucket _getBucket(Map<String, bool> builderFlakyMap, String builderName) {
    return builderFlakyMap[builderName] == true ? Bucket.staging : Bucket.prod;
  }
}
