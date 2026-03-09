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
import '../request_handling/request_handler.dart';
import '../request_handling/response.dart';
import '../service/big_query.dart';
import '../service/config.dart';
import '../service/github_service.dart';
import '../service/test_suppression.dart';
import 'flaky_handler_utils.dart';

/// A handler to deflake builders if the builders are no longer flaky.
///
/// This handler gets flaky builders from Firestore and check the following
/// conditions:
/// 1. The builder is not in [ignoredBuilders].
/// 2. The flaky issue of the builder is closed if there is one.
/// 3. The builder has been passing for most recent
///    [config.minimumPassingTestsToDeflake] consecutive runs.
///
/// If all the conditions are true, this handler will remove the suppression in
/// Firestore.
final class CheckFlakyBuilders extends ApiRequestHandler {
  const CheckFlakyBuilders({
    required super.config,
    required super.authenticationProvider,
    required BigQueryService bigQuery,
    required TestSuppression testSuppression,
  }) : _bigQuery = bigQuery,
       _testSuppression = testSuppression;

  final BigQueryService _bigQuery;
  final TestSuppression _testSuppression;

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
  Future<Response> get(Request request) async {
    final slug = Config.flutterSlug;
    final gitHub = config.createGithubServiceWithToken(
      await config.githubOAuthToken,
    );
    final ciContent = await gitHub.getFileContent(slug, kCiYamlPath);
    final ci = loadYaml(ciContent) as YamlMap?;
    final unCheckedSchedulerConfig = pb.SchedulerConfig()
      ..mergeFromProto3Json(ci);
    final ciYaml = CiYamlSet(
      slug: slug,
      branch: Config.defaultBranch(slug),
      yamls: {CiType.any: unCheckedSchedulerConfig},
    );

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

    for (final info in eligibleBuilders) {
      final builderRecords = await _bigQuery.listRecentBuildRecordsForBuilder(
        kBigQueryProjectId,
        builder: info.name,
        limit: config.minimumPassingTestsToDeflake,
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
        await _unsuppressTest(slug, gitHub, info: info);
        // Manually add a 1s delay between consecutive GitHub requests to deal with secondary rate limit error.
        // https://docs.github.com/en/rest/guides/best-practices-for-integrators#dealing-with-secondary-rate-limits
        await Future<void>.delayed(config.githubRequestDelay);
      } else {
        log.info('${info.name}: Build data inconclusive. Keeping flaky status');
      }
    }
    return Response.json(const <String, dynamic>{'Status': 'success'});
  }

  /// A builder should be deflaked if satisfying three conditions.
  /// 1) There are enough data records.
  /// 2) There is no flake
  /// 3) There is no failure
  bool _shouldDeflake(List<BuilderRecord> builderRecords) {
    return builderRecords.length >= config.minimumPassingTestsToDeflake &&
        builderRecords.every(
          (BuilderRecord record) => !record.isFlaky && !record.isFailed,
        );
  }

  /// Gets the builders that match conditions:
  /// 1. The builder's ignoreFlakiness is false.
  /// 2. The builder is flaky (in Firestore)
  /// 3. The builder is not in [ignoredBuilders].
  /// 4. The flaky issue of the builder is closed if there is one.
  Future<List<_BuilderInfo>> _getEligibleFlakyBuilders(
    GithubService gitHub,
    RepositorySlug slug, {
    required String content,
    required CiYamlSet ciYaml,
  }) async {
    final result = <_BuilderInfo>[];

    // Check Firestore for suppressed tests
    final suppressedTests = await _testSuppression.listSuppressedTests(
      repository: slug,
    );

    for (final test in suppressedTests) {
      if (ignoredBuilders.contains(test.testName)) {
        continue;
      }
      if (getIgnoreFlakiness(test.testName, ciYaml)) {
        continue;
      }

      // Check if issue is closed
      final issueLink = test.issueLink;
      final match = _issueLinkRegex.firstMatch(issueLink);
      if (match == null) {
        // If no valid issue link, we treat it as eligible if green.
        result.add(_BuilderInfo(name: test.testName));
        continue;
      }

      final issue = await gitHub.getIssue(
        slug,
        issueNumber: int.parse(match.namedGroup('id')!),
      )!;
      if (issue.state.toLowerCase() == 'closed') {
        result.add(_BuilderInfo(name: test.testName, existingIssue: issue));
      } else {
        log.debug(
          'Skipping ${test.testName}, issue #${issue.id} ($slug) is reporting as '
          'non-closed state: ${issue.state}',
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

  Future<void> _unsuppressTest(
    RepositorySlug slug,
    GithubService gitHub, {
    required _BuilderInfo info,
  }) async {
    log.info('Unsuppressing ${info.name} in Firestore');
    await _testSuppression.updateSuppression(
      testName: info.name!,
      email: 'fluttergithubbot',
      repository: slug,
      action: SuppressingAction.unsuppress,
      note: 'Build data shows flakiness reduction and issue is closed',
    );

    if (info.existingIssue != null) {
      final issueNumber = info.existingIssue!.number;
      log.info('Closing issue #$issueNumber for ${info.name}');
      final comment =
          'The test has been passing for [${config.minimumPassingTestsToDeflake} consecutive runs]'
          '(${Uri.encodeFull('$kFlakeRecordPrefix"${info.name}"')}).\n'
          'This test has been unsuppressed in Firestore and this issue is being closed.';
      await gitHub.createComment(slug, issueNumber: issueNumber, body: comment);
      await gitHub.closeIssue(slug, issueNumber: issueNumber);
    }
  }
}

/// The info of the builder's name and if there is any existing issue opened
/// for the builder.
class _BuilderInfo {
  _BuilderInfo({this.name, this.existingIssue});
  final String? name;
  final Issue? existingIssue;
}
