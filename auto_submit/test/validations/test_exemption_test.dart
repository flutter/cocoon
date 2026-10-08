// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/validations/test_exemption.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:cocoon_common/labels.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../utilities/utils.dart';

void main() {
  useTestLoggerPerTest();

  late TestExemption testExemption;
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
    testExemption = TestExemption(config: config);
  });

  test('Pull request without missing-tests label passes validation', () async {
    final flutterRequest = PullRequestHelper(
      prNumber: 0,
      lastCommitHash: oid,
      reviews: <PullRequestReviewHelper>[],
    );
    final queryResult = createQueryResult(flutterRequest);
    final pullRequest = generatePullRequest();

    final validationResult = await testExemption.validate(
      queryResult,
      pullRequest,
    );
    expect(validationResult.result, isTrue);
    expect(validationResult.message, isEmpty);
  });

  test(
    'Pull request with missing-tests and test-exempt labels passes validation',
    () async {
      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );
      final queryResult = createQueryResult(flutterRequest);
      final pullRequest = generatePullRequest();
      pullRequest.labels = <IssueLabel>[
        IssueLabel(name: kAutosubmitLabel),
        IssueLabel(name: kMissingTestsLabel),
        IssueLabel(name: kTestExemptLabel),
      ];

      final validationResult = await testExemption.validate(
        queryResult,
        pullRequest,
      );
      expect(validationResult.result, isTrue);
      expect(validationResult.message, isEmpty);
    },
  );

  test(
    'Pull request with missing-tests label and without test-exempt label fails validation',
    () async {
      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );
      final queryResult = createQueryResult(flutterRequest);
      final pullRequest = generatePullRequest();
      pullRequest.labels = <IssueLabel>[
        IssueLabel(name: kAutosubmitLabel),
        IssueLabel(name: kMissingTestsLabel),
      ];

      final validationResult = await testExemption.validate(
        queryResult,
        pullRequest,
      );
      expect(validationResult.result, isFalse);
      expect(validationResult.action, Action.REMOVE_LABEL);
      expect(
        validationResult.message,
        '- This pull request has the `missing-tests` label and does not have '
        'the `test-exempt` label. Please add tests or obtain a test exemption '
        'from a tech lead before re-applying the `autosubmit` label.',
      );
    },
  );

  test(
    'Pull request with missing-tests and emergency labels ignores failure',
    () async {
      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );
      final queryResult = createQueryResult(flutterRequest);
      final pullRequest = generatePullRequest();
      pullRequest.labels = <IssueLabel>[
        IssueLabel(name: kAutosubmitLabel),
        IssueLabel(name: kMissingTestsLabel),
        IssueLabel(name: kEmergencyLabel),
      ];

      final validationResult = await testExemption.validate(
        queryResult,
        pullRequest,
      );
      expect(validationResult.result, isFalse);
      expect(validationResult.action, Action.IGNORE_FAILURE);
    },
  );
}
