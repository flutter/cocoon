// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/ci_yaml.dart';
import 'package:collection/collection.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

import '../../protos.dart' as pb;
import '../foundation/utils.dart';
import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';
import '../service/bigquery.dart';
import '../service/config.dart';
import '../service/github_service.dart';
import 'flaky_handler_utils.dart';

/// A handler to deflake builders if the builders are no longer flaky.
///
/// This handler gets flaky builders from ci.yaml in flutter/flutter and check
/// the following conditions:
/// 1. The builder is not in [ignoredBuilders].
/// 2. The flaky issue of the builder is closed if there is one.
/// 3. Does not have any existing pr against the target.
/// 4. The builder has been passing for most recent [kRecordNumber] consecutive
///    runs.
/// 5. The builder is not marked with ignore_flakiness.
///
/// If all the conditions are true, this handler will file a pull request to
/// make the builder unflaky.
@immutable
class CheckFlakyBuilders extends ApiRequestHandler<Body> {
  const CheckFlakyBuilders({
    required super.config,
    required super.authenticationProvider,
  });

  static int kRecordNumber = 50;

  static final RegExp _issueLinkRegex = RegExp(r'https://github.com/flutter/flutter/issues/(?<id>[0-9]+)');

  /// Builders that are purposefully marked flaky and should be ignored by this
  /// handler.
  static const Set<String> ignoredBuilders = <String>{
    'Mac_ios32 flutter_gallery__transition_perf_e2e_ios32',
    'Mac_ios32 native_ui_tests_ios',
  };

  @override
  Future<Body> get() async {
    final RepositorySlug slug = Config.flutterSlug;
    final GithubService gitHub = config.createGithubServiceWithToken(await config.githubOAuthToken);
    final BigqueryService bigquery = await config.createBigQueryService();
    final String ciContent = await gitHub.getFileContent(
      slug,
      kCiYamlPath,
    );
    final YamlMap? ci = loadYaml(ciContent) as YamlMap?;
    final pb.SchedulerConfig unCheckedSchedulerConfig = pb.SchedulerConfig()..mergeFromProto3Json(ci);
    final CiYaml ciYaml = CiYaml(
      slug: slug,
      branch: Config.defaultBranch(slug),
      config: unCheckedSchedulerConfig,
    );

    final pb.SchedulerConfig schedulerConfig = ciYaml.config;
    final List<pb.Target> targets = schedulerConfig.targets;

    final List<_BuilderInfo> eligibleBuilders =
        await _getEligibleFlakyBuilders(gitHub, slug, content: ciContent, ciYaml: ciYaml);
    final String testOwnerContent = await gitHub.getFileContent(
      slug,
      kTestOwnerPath,
    );

    for (final _BuilderInfo info in eligibleBuilders) {
      final BuilderType type = getTypeForBuilder(info.name, ciYaml);
      final TestOwnership testOwnership = getTestOwnership(
        targets.singleWhere((element) => element.name == info.name!),
        type,
        testOwnerContent,
      );
      final List<BuilderRecord> builderRecords =
          await bigquery.listRecentBuildRecordsForBuilder(kBigQueryProjectId, builder: info.name, limit: kRecordNumber);
      if (_shouldDeflake(builderRecords)) {
        await _deflakyPullRequest(gitHub, slug, info: info, ciContent: ciContent, testOwnership: testOwnership);
        // Manually add a 1s delay between consecutive GitHub requests to deal with secondary rate limit error.
        // https://docs.github.com/en/rest/guides/best-practices-for-integrators#dealing-with-secondary-rate-limits
        await Future.delayed(config.githubRequestDelay);
      }
    }
    return Body.forJson(const <String, dynamic>{
      'Status': 'success',
    });
  }

  /// A builder should be deflaked if satisfying three conditions.
  /// 1) There are enough data records.
  /// 2) There is no flake
  /// 3) There is no failure
  bool _shouldDeflake(List<BuilderRecord> builderRecords) {
    return builderRecords.length >= kRecordNumber &&
        builderRecords.every((BuilderRecord record) => !record.isFlaky && !record.isFailed);
  }

  /// Gets the builders that match conditions:
  /// 1. The builder's ignoreFlakiness is false.
  /// 2. The builder is flaky
  /// 3. The builder is not in [ignoredBuilders].
  /// 4. The flaky issue of the builder is closed if there is one.
  /// 5. Does not have any existing pr against the builder.
  Future<List<_BuilderInfo>> _getEligibleFlakyBuilders(
    GithubService gitHub,
    RepositorySlug slug, {
    required String content,
    required CiYaml ciYaml,
  }) async {
    final YamlMap ci = loadYaml(content) as YamlMap;
    final YamlList targets = ci[kCiYamlTargetsKey] as YamlList;
    final List<YamlMap?> flakyTargets = targets
        .where((dynamic target) => target[kCiYamlTargetIsFlakyKey] == true)
        .map<YamlMap?>((dynamic target) => target as YamlMap?)
        .toList();
    final List<_BuilderInfo> result = <_BuilderInfo>[];
    final List<String> lines = content.split('\n');
    final Map<String?, PullRequest> nameToExistingPRs = await getExistingPRs(gitHub, slug);
    for (final YamlMap? flakyTarget in flakyTargets) {
      final String? builder = flakyTarget![kCiYamlTargetNameKey] as String?;
      // If target specified ignore_flakiness, then skip.
      if (getIgnoreFlakiness(builder, ciYaml)) {
        continue;
      }
      if (ignoredBuilders.contains(builder)) {
        continue;
      }
      // Skip the flaky target if the issue or pr for the flaky target is still
      // open.
      if (nameToExistingPRs.containsKey(builder)) {
        continue;
      }

      //TODO (ricardoamador): Refactor this so we don't need to parse the entire yaml looking for commented issues, https://github.com/flutter/flutter/issues/113232
      int builderLineNumber = lines.indexWhere((String line) => line.contains('name: $builder')) + 1;
      while (builderLineNumber < lines.length && !lines[builderLineNumber].contains('name:')) {
        if (lines[builderLineNumber].contains('$kCiYamlTargetIsFlakyKey:')) {
          final RegExpMatch? match = _issueLinkRegex.firstMatch(lines[builderLineNumber]);
          if (match == null) {
            result.add(_BuilderInfo(name: builder));
            break;
          }
          final Issue issue = await gitHub.getIssue(slug, issueNumber: int.parse(match.namedGroup('id')!))!;
          if (issue.isClosed) {
            result.add(_BuilderInfo(name: builder, existingIssue: issue));
          }
          break;
        }
        builderLineNumber += 1;
      }
    }
    return result;
  }

  @visibleForTesting
  static bool getIgnoreFlakiness(String? builderName, CiYaml ciYaml) {
    if (builderName == null) {
      return false;
    }
    final Target? target = ciYaml.getFirstPostsubmitTarget(builderName);
    return target == null ? false : target.getIgnoreFlakiness();
  }

  Future<void> _deflakyPullRequest(
    GithubService gitHub,
    RepositorySlug slug, {
    required _BuilderInfo info,
    required String ciContent,
    required TestOwnership testOwnership,
  }) async {
    final String modifiedContent = _deflakeBuilderInContent(ciContent, info.name);
    final GitReference masterRef = await gitHub.getReference(slug, kMasterRefs);
    final DeflakePullRequestBuilder prBuilder = DeflakePullRequestBuilder(
      name: info.name,
      recordNumber: kRecordNumber,
      ownership: testOwnership,
      issue: info.existingIssue,
    );
    final PullRequest pullRequest = await gitHub.createPullRequest(
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
    await gitHub.assignReviewer(slug, reviewer: prBuilder.pullRequestReviewer, pullRequestNumber: pullRequest.number);
  }

  /// Removes the `bringup: true` for the builder in the ci.yaml.
  String _deflakeBuilderInContent(String content, String? builder) {
    final List<String> lines = content.split('\n');
    final int builderLineNumber = lines.indexWhere((String line) => line.contains('name: $builder'));
    int nextLine = builderLineNumber + 1;
    while (nextLine < lines.length && !lines[nextLine].contains('name:')) {
      if (lines[nextLine].contains('$kCiYamlTargetIsFlakyKey:')) {
        lines.removeAt(nextLine);
        return lines.join('\n');
      }
      nextLine += 1;
    }
    throw 'Cannot find the flaky flag, is the test really marked flaky?';
  }
}

/// The info of the builder's name and if there is any existing issue opened
/// for the builder.
class _BuilderInfo {
  _BuilderInfo({this.name, this.existingIssue});
  final String? name;
  final Issue? existingIssue;
}
