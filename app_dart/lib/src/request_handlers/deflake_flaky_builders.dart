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
///
/// If all the conditions are true, this handler will file a pull request to
/// make the builder unflaky.
@immutable
class DeflakeFlakyBuilders extends ApiRequestHandler<Body> {
  const DeflakeFlakyBuilders(Config config, AuthenticationProvider authenticationProvider)
      : super(config: config, authenticationProvider: authenticationProvider);

  static const int kRecordNumber = 50;

  static final RegExp _issueLinkRegex = RegExp(r'https://github.com/flutter/flutter/issues/(?<id>[0-9]+)');

  /// Builders that are purposefully marked flaky and should be ignored by this
  /// handler.
  static const Set<String> ignoredBuilders = <String>{
    'Mac_ios flutter_gallery__transition_perf_e2e_ios32',
    'Mac_ios native_ui_tests_ios32',
  };

  @override
  Future<Body> get() async {
    final RepositorySlug slug = config.flutterSlug;
    final GithubService gitHub = config.createGithubServiceWithToken(await config.githubOAuthToken);
    final BigqueryService bigquery = await config.createBigQueryService();
    final String ciContent = await gitHub.getFileContent(slug, kCiYamlPath);
    final List<_BuilderInfo> eligibleBuilders = await _getEligibleFlakyBuilders(gitHub, slug, content: ciContent);
    String testOwnerContent;
    for (final _BuilderInfo info in eligibleBuilders) {
      final List<BuilderRecord> builderRecords =
          await bigquery.listRecentBuildRecordsForBuilder(kBigQueryProjectId, builder: info.name, limit: kRecordNumber);
      if (builderRecords.every((BuilderRecord record) => !record.isFlaky)) {
        testOwnerContent ??= await gitHub.getFileContent(slug, kTestOwnerPath);
        await _deflakyPullRequest(gitHub, slug, info: info, ciContent: ciContent, testOwnerContent: testOwnerContent);
      }
    }
    return Body.forJson(const <String, dynamic>{
      'Status': 'success',
    });
  }

  /// Gets the builders that match conditions:
  /// 1. The builder is flaky
  /// 2. The builder is not in [ignoredBuilders].
  /// 3. The flaky issue of the builder is closed if there is one.
  /// 4. Does not have any existing pr against the builder.
  Future<List<_BuilderInfo>> _getEligibleFlakyBuilders(GithubService gitHub, RepositorySlug slug,
      {String content}) async {
    final YamlMap ci = loadYaml(content) as YamlMap;
    final YamlList targets = ci[kCiYamlTargetsKey] as YamlList;
    final List<YamlMap> flakyTargets = targets
        .where((dynamic target) => target[kCiYamlTargetIsFlakyKey] == true)
        .map<YamlMap>((dynamic target) => target as YamlMap)
        .toList();
    final List<_BuilderInfo> result = <_BuilderInfo>[];
    final List<String> lines = content.split('\n');
    final Map<String, PullRequest> nameToExistingPRs = await getExistingPRs(gitHub, slug);
    for (final YamlMap flakyTarget in flakyTargets) {
      final String builder = flakyTarget[kCiYamlTargetBuilderKey] as String;
      if (ignoredBuilders.contains(builder)) {
        continue;
      }
      // Skip the flaky target if the issue or pr for the flaky target is still
      // open.
      if (nameToExistingPRs.containsKey(builder)) {
        continue;
      }
      int builderLineNumber = lines.indexWhere((String line) => line.contains('builder: $builder')) + 1;
      while (builderLineNumber < lines.length && !lines[builderLineNumber].contains('builder:')) {
        if (lines[builderLineNumber].contains('$kCiYamlTargetIsFlakyKey:')) {
          final RegExpMatch match = _issueLinkRegex.firstMatch(lines[builderLineNumber]);
          if (match == null) {
            result.add(_BuilderInfo(name: builder));
            break;
          }
          final Issue issue = await gitHub.getIssue(slug, issueNumber: int.parse(match.namedGroup('id')));
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

  Future<void> _deflakyPullRequest(
    GithubService gitHub,
    RepositorySlug slug, {
    @required _BuilderInfo info,
    @required String ciContent,
    @required String testOwnerContent,
  }) async {
    final String modifiedContent = _deflakeBuilderInContent(ciContent, info.name);
    final GitReference masterRef = await gitHub.getReference(slug, kMasterRefs);
    final DeflakePullRequestBuilder prBuilder =
        DeflakePullRequestBuilder(name: info.name, recordNumber: kRecordNumber, issue: info.existingIssue);
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
    await gitHub.assignReviewer(slug,
        reviewer:
            getTestOwner(info.name, getTypeForBuilder(info.name, loadYaml(ciContent) as YamlMap), testOwnerContent),
        pullRequestNumber: pullRequest.number);
  }

  /// Removes the `bringup: true` for the builder in the ci.yaml.
  String _deflakeBuilderInContent(String content, String builder) {
    final List<String> lines = content.split('\n');
    final int builderLineNumber = lines.indexWhere((String line) => line.contains('builder: $builder'));
    int nextLine = builderLineNumber + 1;
    while (nextLine < lines.length && !lines[nextLine].contains('builder:')) {
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
  final String name;
  final Issue existingIssue;
}
