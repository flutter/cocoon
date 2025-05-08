// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../../ci_yaml.dart';
import '../../protos.dart' as pb;
import '../foundation/utils.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';
import '../service/big_query.dart';
import '../service/config.dart';
import '../service/github_service.dart';
import 'flaky_handler_utils.dart';

/// This handler updates existing open flaky issues with the latest build
/// statistics.
///
/// The query parameter kThresholdKey is required in order for the handler to
/// properly adjusts the priority labels.
final class UpdateExistingFlakyIssue extends ApiRequestHandler {
  const UpdateExistingFlakyIssue({
    required super.config,
    required super.authenticationProvider,
    required BigQueryService bigQuery,
    @visibleForTesting this.ciYamlForTesting,
  }) : _bigQuery = bigQuery;

  static const String kThresholdKey = 'threshold';
  static const int kFreshPeriodForOpenFlake = 7; // days

  final BigQueryService _bigQuery;

  // TODO(matanlurey): Use `CiYamlFetcher` instead.
  final CiYamlSet? ciYamlForTesting;

  @override
  Future<Response> get(Request request) async {
    final slug = Config.flutterSlug;
    final gitHub = config.createGithubServiceWithToken(
      await config.githubOAuthToken,
    );

    var localCiYaml = ciYamlForTesting;
    if (localCiYaml == null) {
      final ci =
          loadYaml(await gitHub.getFileContent(slug, kCiYamlPath)) as YamlMap?;
      final unCheckedSchedulerConfig =
          pb.SchedulerConfig()..mergeFromProto3Json(ci);
      localCiYaml = CiYamlSet(
        slug: slug,
        branch: Config.defaultBranch(slug),
        yamls: {CiType.any: unCheckedSchedulerConfig},
      );
    }

    final prodBuilderStatisticList = await _bigQuery.listBuilderStatistic(
      kBigQueryProjectId,
      bucket: 'prod',
    );
    final stagingBuilderStatisticList = await _bigQuery.listBuilderStatistic(
      kBigQueryProjectId,
      bucket: 'staging',
    );
    final nameToExistingIssue = await getExistingIssues(
      gitHub,
      slug,
      state: 'open',
    );
    final threshold = double.parse(request.uri.queryParameters[kThresholdKey]!);
    await _updateExistingFlakyIssue(
      gitHub,
      slug,
      localCiYaml,
      prodBuilderStatisticList: prodBuilderStatisticList,
      stagingBuilderStatisticList: stagingBuilderStatisticList,
      nameToExistingIssue: nameToExistingIssue,
      threshold: threshold,
    );
    return Response.json(const <String, dynamic>{'Status': 'success'});
  }

  /// Adds an update comment and adjusts the labels of the existing issue based
  /// on the latest statistics.
  ///
  /// This method skips issues that are created within kFreshPeriodForOpenFlake
  /// days.
  Future<void> _addCommentToExistingIssue(
    GithubService gitHub,
    RepositorySlug slug, {
    required Bucket bucket,
    required bool bringup,
    required BuilderStatistic statistic,
    required Issue existingIssue,
    required CiYamlSet ciYaml,
    required double threshold,
  }) async {
    if (DateTime.now().difference(existingIssue.createdAt!) <
        const Duration(days: kFreshPeriodForOpenFlake)) {
      return;
    }
    final computedThreshold =
        ciYaml.getFirstPostsubmitTarget(statistic.name)?.flakinessThreshold ??
        threshold;
    final updateBuilder = IssueUpdateBuilder(
      statistic: statistic,
      threshold: computedThreshold,
      existingIssue: existingIssue,
      bucket: bucket,
    );
    await gitHub.createComment(
      slug,
      issueNumber: existingIssue.number,
      body: updateBuilder.issueUpdateComment,
    );
    // No need to bump priority and reassign if this is already marked as `bringup: true`.
    if (bringup) {
      return;
    }
    await gitHub.replaceLabelsForIssue(
      slug,
      issueNumber: existingIssue.number,
      labels: updateBuilder.issueLabels,
    );
    if (existingIssue.assignee == null && !updateBuilder.isBelow) {
      final testOwnerContent = await gitHub.getFileContent(
        slug,
        kTestOwnerPath,
      );

      final schedulerConfig = ciYaml.configFor(CiType.any);
      final targets = schedulerConfig.targets;

      final testOwner =
          getTestOwnership(
            targets.singleWhere((element) => element.name == statistic.name),
            getTypeForBuilder(statistic.name, ciYaml),
            testOwnerContent,
          ).owner;
      if (testOwner != null) {
        await gitHub.assignIssue(
          slug,
          issueNumber: existingIssue.number,
          assignee: testOwner,
        );
      }
    }
  }

  /// Updates existing flaky issues based on corrresponding builder stats.
  Future<void> _updateExistingFlakyIssue(
    GithubService gitHub,
    RepositorySlug slug,
    CiYamlSet ciYaml, {
    required List<BuilderStatistic> prodBuilderStatisticList,
    required List<BuilderStatistic> stagingBuilderStatisticList,
    required Map<String?, Issue> nameToExistingIssue,
    required double threshold,
  }) async {
    final builderFlakyMap = <String, bool>{};
    final ignoreFlakyMap = <String, bool>{};
    for (var target in ciYaml.postsubmitTargets()) {
      builderFlakyMap[target.name] = target.isBringup;
      if (target.getIgnoreFlakiness()) {
        ignoreFlakyMap[target.name] = true;
      }
    }
    // Update an existing flaky bug with only prod stats if the builder is with `bringup: false`, such as a shard builder.
    //
    // Update an existing flaky bug with both prod and staging stats if the builder is with `bringup: true`. When a builder
    // is newly identified as flaky, there is a gap between the builder is marked as `bringup: true` and the flaky bug is filed.
    // For this case, there will be builds still running in `prod` pool, and we need to append `prod` stats as well.
    for (final statistic in prodBuilderStatisticList) {
      if (nameToExistingIssue.containsKey(statistic.name) &&
          builderFlakyMap.containsKey(statistic.name) &&
          !ignoreFlakyMap.containsKey(statistic.name)) {
        await _addCommentToExistingIssue(
          gitHub,
          slug,
          bucket: Bucket.prod,
          bringup: builderFlakyMap[statistic.name]!,
          statistic: statistic,
          existingIssue: nameToExistingIssue[statistic.name]!,
          ciYaml: ciYaml,
          threshold: threshold,
        );
      }
    }
    // For all staging builder stats, updates any existing flaky bug.
    for (final statistic in stagingBuilderStatisticList) {
      if (nameToExistingIssue.containsKey(statistic.name) &&
          builderFlakyMap[statistic.name] == true &&
          !ignoreFlakyMap.containsKey(statistic.name)) {
        await _addCommentToExistingIssue(
          gitHub,
          slug,
          bucket: Bucket.staging,
          bringup: builderFlakyMap[statistic.name]!,
          statistic: statistic,
          existingIssue: nameToExistingIssue[statistic.name]!,
          ciYaml: ciYaml,
          threshold: threshold,
        );
      }
    }
  }
}
