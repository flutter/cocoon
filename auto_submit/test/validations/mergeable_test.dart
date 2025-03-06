// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/model/auto_submit_query_result.dart' as auto;
import 'package:auto_submit/validations/mergeable.dart';
import 'package:cocoon_server/testing/mocks.dart';
import 'package:test/test.dart';

import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../utilities/utils.dart';

void main() {
  late Mergeable mergeable;
  late FakeConfig config;
  late FakeGithubService githubService;
  late FakeGraphQLClient githubGraphQLClient;

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    githubService = FakeGithubService(client: MockGitHub());
    config = FakeConfig(
      githubService: githubService,
      githubGraphQLClient: githubGraphQLClient,
    );
    mergeable = Mergeable(config: config);
  });

  test('Pull request is mergeable', () async {
    const org = 'flutter';
    const repo = 'flutter';

    final flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
    );
    final queryResult = createQueryResult(flutterRequest);

    final pullRequest = generatePullRequest(
      mergeable: true,
      login: org,
      repoName: repo,
    );

    final processMergeResult = await mergeable.validate(
      queryResult,
      pullRequest,
    );
    expect(processMergeResult.result, isTrue);
    expect(
      processMergeResult.message,
      'Pull request flutter/flutter/1347 is mergeable',
    );
  });

  test('Pull request mergeability has not been determined', () async {
    const org = 'flutter';
    const repo = 'flutter';

    final flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
      mergeableState: auto.MergeableState.UNKNOWN,
    );
    final queryResult = createQueryResult(flutterRequest);

    final pullRequest = generatePullRequest(
      mergeable: null,
      login: org,
      repoName: repo,
    );
    githubService.pullRequestData = pullRequest;

    final processMergeResult = await mergeable.validate(
      queryResult,
      pullRequest,
    );
    expect(processMergeResult.result, isFalse);
    expect(
      processMergeResult.message,
      'Mergeability of pull request flutter/flutter/1347 could not be determined at time of merge.',
    );
  });

  test('Pull request cannot be merged', () async {
    const org = 'flutter';
    const repo = 'flutter';

    final pullRequest = generatePullRequest(
      mergeable: false,
      login: org,
      repoName: repo,
    );
    githubService.pullRequestData = pullRequest;

    final flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
      mergeableState: auto.MergeableState.CONFLICTING,
    );
    final queryResult = createQueryResult(flutterRequest);

    final processMergeResult = await mergeable.validate(
      queryResult,
      pullRequest,
    );
    expect(processMergeResult.result, isFalse);
    expect(
      processMergeResult.message,
      'Pull request flutter/flutter/1347 is not in a mergeable state.',
    );
  });
}
