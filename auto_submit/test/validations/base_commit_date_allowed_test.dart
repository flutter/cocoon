// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/validations/base_commit_date_allowed.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:test/test.dart';

import '../configuration/repository_configuration_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../utilities/utils.dart';
import 'base_commit_date_allowed_test_data.dart';

void main() {
  useTestLoggerPerTest();

  late BaseCommitDateAllowed validator;
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
    config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(
      sampleConfigNoOverride,
    );
    validator = BaseCommitDateAllowed(config: config);
  });

  test('Pull request is valid then base_commit_expiration is empty', () async {
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

    githubService.commitData = constructCommit(
      date: DateTime.now().subtract(const Duration(days: 100)),
    );

    final processValidationResult = await validator.validate(
      queryResult,
      pullRequest,
    );
    expect(processValidationResult.result, isTrue);
    expect(
      processValidationResult.message,
      'PR base commit creation date validation turned off',
    );
  });

  test(
    'Pull request is valid then base is earlier than 7 days with config override',
    () async {
      const org = 'flutter';
      const repo = 'flutter';

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(
        sampleConfigWithOverride,
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        mergeable: true,
        login: org,
        repoName: repo,
      );

      githubService.commitData = constructCommit(
        date: DateTime.now().subtract(const Duration(days: 6)),
      );

      final processValidationResult = await validator.validate(
        queryResult,
        pullRequest,
      );
      expect(processValidationResult.result, isTrue);
      expect(
        processValidationResult.message,
        'The base commit of the PR is recent enough for merging.',
      );
    },
  );

  test(
    'Pull request is valid then branch is not that configured for validation',
    () async {
      const org = 'flutter';
      const repo = 'flutter';

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(
        sampleConfigWithOverride,
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        mergeable: true,
        login: org,
        repoName: repo,
        baseRef: 'not-main',
      );

      githubService.commitData = constructCommit(
        date: DateTime.now().subtract(const Duration(days: 6)),
      );

      final processValidationResult = await validator.validate(
        queryResult,
        pullRequest,
      );
      expect(processValidationResult.result, isTrue);
      expect(
        processValidationResult.message,
        'The base commit expiration validation is not configured for this '
        'branch.',
      );
    },
  );
  test('Pull request base is expired if older than 7 days', () async {
    const org = 'flutter';
    const repo = 'flutter';

    final flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
    );

    config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(
      sampleConfigWithOverride,
    );

    final queryResult = createQueryResult(flutterRequest);

    final pullRequest = generatePullRequest(
      mergeable: true,
      login: org,
      repoName: repo,
    );

    githubService.commitData = constructCommit(
      date: DateTime.now().subtract(const Duration(days: 7)),
    );

    final processValidationResult = await validator.validate(
      queryResult,
      pullRequest,
    );
    expect(processValidationResult.result, isFalse);
    expect(processValidationResult.action, Action.REMOVE_LABEL);
    expect(
      processValidationResult.message,
      'The base commit of the PR is older than 7 days and can not be merged. '
      'Please merge the latest changes from the main into this branch and '
      'resubmit the PR.',
    );
  });

  test(
    'Pull request is validation ignored if no base commit date is found',
    () async {
      const org = 'flutter';
      const repo = 'flutter';

      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(
        sampleConfigWithOverride,
      );

      final queryResult = createQueryResult(flutterRequest);

      final pullRequest = generatePullRequest(
        mergeable: true,
        login: org,
        repoName: repo,
      );

      githubService.commitData = constructEmptyCommit();

      final processValidationResult = await validator.validate(
        queryResult,
        pullRequest,
      );
      expect(processValidationResult.result, isFalse);
      expect(processValidationResult.action, Action.IGNORE_FAILURE);
      expect(
        processValidationResult.message,
        'Could not find the base commit creation date of the PR flutter/flutter/1347.',
      );
    },
  );
}
