// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_server/logging.dart';
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
    required BigQueryService bigQuery,
  }) : _bigQuery = bigQuery;

  final BigQueryService _bigQuery;

  static int kRecordNumber = 50;

  static final RegExp _issueLinkRegex = RegExp(
    r'https://github.com/flutter/flutter/issues/(?<id>[0-9]+)',
  );

  /// Builders that are purposefully marked flaky and should be ignored by this
  /// handler.
  static const Set<String> ignoredBuilders = <String>{
    'Mac_ios32 flutter_gallery__transition_perf_e2e_ios32',
    'Mac_ios32 native_ui_tests_ios',
  };

  @override
  Future<Body> get() async {
    final slug = Config.flutterSlug;
    final gitHub = config.createGithubServiceWithToken(
      await config.githubOAuthToken,
    );
    final ciContent = await gitHub.getFileContent(slug, kCiYamlPath);
    final ci = loadYaml(ciContent) as YamlMap?;
    final unCheckedSchedulerConfig =
        pb.SchedulerConfig()..mergeFromProto3Json(ci);
    final ciYaml = CiYamlSet(
      slug: slug,
      branch: Config.defaultBranch(slug),
      yamls: {CiType.any: unCheckedSchedulerConfig},
    );

    final schedulerConfig = ciYaml.configFor(CiType.any);
    final targets = schedulerConfig.targets;

    final eligibleBuilders = await _getEligibleFlakyBuilders(
      gitHub,
      slug,
      content: ciContent,
      ciYaml: ciYaml,
    );
    log.info(
      'The following builders are eligible to be marked no longer flaky:\n'
      '${eligibleBuilders.map((b) => b.name).join('\n')}',
    );
    final testOwnerContent = await gitHub.getFileContent(slug, kTestOwnerPath);

    for (final info in eligibleBuilders) {
      final type = getTypeForBuilder(info.name, ciYaml);
      final testOwnership = getTestOwnership(
        targets.singleWhere((element) => element.name == info.name!),
        type,
        testOwnerContent,
      );
      final builderRecords = await _bigQuery.listRecentBuildRecordsForBuilder(
        kBigQueryProjectId,
        builder: info.name,
        limit: kRecordNumber,
      );
      log.debug(
        builderRecords
            .map(
              (t) =>
                  '${t.commit}: ${t.isFailed
                      ? 'failed '
                      : t.isFlaky
                      ? 'flaky'
                      : 'ok'}',
            )
            .join('\n'),
      );
      if (_shouldDeflake(builderRecords)) {
        log.info('${info.name}: Build data shows flakiness reduction');
        await _deflakyPullRequest(
          gitHub,
          slug,
          info: info,
          ciContent: ciContent,
          testOwnership: testOwnership,
        );
        // Manually add a 1s delay between consecutive GitHub requests to deal with secondary rate limit error.
        // https://docs.github.com/en/rest/guides/best-practices-for-integrators#dealing-with-secondary-rate-limits
        await Future<void>.delayed(config.githubRequestDelay);
      } else {
        log.info('${info.name}: Build data inconclusive. Keeping flaky status');
      }
    }
    return Body.forJson(const <String, dynamic>{'Status': 'success'});
  }

  /// A builder should be deflaked if satisfying three conditions.
  /// 1) There are enough data records.
  /// 2) There is no flake
  /// 3) There is no failure
  bool _shouldDeflake(List<BuilderRecord> builderRecords) {
    return builderRecords.length >= kRecordNumber &&
        builderRecords.every(
          (BuilderRecord record) => !record.isFlaky && !record.isFailed,
        );
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
    required CiYamlSet ciYaml,
  }) async {
    final ci = loadYaml(content) as YamlMap;
    final targets = ci[kCiYamlTargetsKey] as YamlList;
    final flakyTargets =
        targets
            .where((dynamic target) => target[kCiYamlTargetIsFlakyKey] == true)
            .map<YamlMap?>((dynamic target) => target as YamlMap?)
            .toList();
    log.debug(
      'Possibly eligible flaky builders:\n'
      '${flakyTargets.map((t) => t![kCiYamlTargetNameKey]).join('\n')}',
    );
    final result = <_BuilderInfo>[];
    final lines = content.split('\n');
    final nameToExistingPRs = await getExistingPRs(gitHub, slug);
    for (final flakyTarget in flakyTargets) {
      final builder = flakyTarget![kCiYamlTargetNameKey] as String?;
      // If target specified ignore_flakiness, then skip.
      if (getIgnoreFlakiness(builder, ciYaml)) {
        log.debug('Skipping $builder, ignore_flakiness specified');
        continue;
      }
      if (ignoredBuilders.contains(builder)) {
        log.debug('Skipping $builder, explicitly deny-listed in Cocoon');
        continue;
      }
      // Skip the flaky target if the issue or pr for the flaky target is still
      // open.
      if (nameToExistingPRs[builder] case final pr?) {
        log.debug('Skipping $builder, an existing PR is open: ${pr.htmlUrl}');
        continue;
      }

      //TODO (ricardoamador): Refactor this so we don't need to parse the entire yaml looking for commented issues, https://github.com/flutter/flutter/issues/113232
      var builderLineNumber =
          lines.indexWhere((String line) => line.contains('name: $builder')) +
          1;

      _BuilderInfo? toBeAdded;
      final startingLineNumber = builderLineNumber;
      var skippedDueToNonClosed = false;
      while (builderLineNumber < lines.length &&
          !lines[builderLineNumber].contains('name:')) {
        if (lines[builderLineNumber].contains('$kCiYamlTargetIsFlakyKey:')) {
          final match = _issueLinkRegex.firstMatch(lines[builderLineNumber]);
          if (match == null) {
            toBeAdded = _BuilderInfo(name: builder);
            break;
          }
          final issue =
              await gitHub.getIssue(
                slug,
                issueNumber: int.parse(match.namedGroup('id')!),
              )!;
          // issue.isClosed checks for (strictly) "CLOSED", sigh.
          if (issue.state.toLowerCase() == 'closed') {
            toBeAdded = _BuilderInfo(name: builder, existingIssue: issue);
          } else {
            log.debug(
              'Skipping $builder, issue #${issue.id} ($slug) is reporting as '
              'non-closed state: ${issue.state}',
            );
            skippedDueToNonClosed = true;
          }
          break;
        }
        builderLineNumber += 1;
      }
      if (toBeAdded != null) {
        result.add(toBeAdded);
      } else if (skippedDueToNonClosed) {
        log.debug(
          'Skipping $builder, could not find matching builder line '
          'starting at line $startingLineNumber of ${lines.length} lines',
        );
      }
    }
    return result;
  }

  @visibleForTesting
  static bool getIgnoreFlakiness(String? builderName, CiYamlSet ciYaml) {
    if (builderName == null) {
      return false;
    }
    final target = ciYaml.getFirstPostsubmitTarget(builderName);
    return target == null ? false : target.getIgnoreFlakiness();
  }

  Future<void> _deflakyPullRequest(
    GithubService gitHub,
    RepositorySlug slug, {
    required _BuilderInfo info,
    required String ciContent,
    required TestOwnership testOwnership,
  }) async {
    final modifiedContent = _deflakeBuilderInContent(ciContent, info.name);
    final masterRef = await gitHub.getReference(slug, kMasterRefs);
    final prBuilder = DeflakePullRequestBuilder(
      name: info.name,
      recordNumber: kRecordNumber,
      ownership: testOwnership,
      issue: info.existingIssue,
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
    await gitHub.assignReviewer(
      slug,
      reviewer: prBuilder.pullRequestReviewer,
      pullRequestNumber: pullRequest.number,
    );
  }

  /// Removes the `bringup: true` for the builder in the ci.yaml.
  String _deflakeBuilderInContent(String content, String? builder) {
    final lines = content.split('\n');
    final builderLineNumber = lines.indexWhere(
      (String line) => line.contains('name: $builder'),
    );
    var nextLine = builderLineNumber + 1;
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
