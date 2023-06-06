// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'ci_successful_test_data.dart';

import 'package:github/github.dart' as github;
import 'package:test/test.dart';
import 'package:auto_submit/validations/ci_successful.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:auto_submit/configuration/repository_configuration.dart';

import '../utilities/utils.dart';
import '../utilities/mocks.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../requests/github_webhook_test_data.dart';
import '../configuration/repository_configuration_data.dart';

void main() {
  late CiSuccessful ciSuccessful;
  late FakeConfig config;
  FakeGithubService githubService = FakeGithubService();
  late FakeGraphQLClient githubGraphQLClient;
  final MockGitHub gitHub = MockGitHub();
  late github.RepositorySlug slug;
  late Set<FailureDetail> failures;

  List<ContextNode> getContextNodeListFromJson(final String repositoryStatuses) {
    final List<ContextNode> contextNodeList = [];

    final Map<String, dynamic> contextNodeMap = jsonDecode(repositoryStatuses) as Map<String, dynamic>;

    final dynamic statuses = contextNodeMap['statuses'];
    for (Map<String, dynamic> map in statuses) {
      contextNodeList.add(ContextNode.fromJson(map));
    }

    return contextNodeList;
  }

  void convertContextNodeStatuses(List<ContextNode> contextNodeList) {
    for (ContextNode contextNode in contextNodeList) {
      contextNode.state = contextNode.state!.toUpperCase();
    }
  }

  /// Setup objects needed across test groups.
  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient, githubClient: gitHub);
    ciSuccessful = CiSuccessful(config: config);
    slug = github.RepositorySlug('octocat', 'flutter');
    failures = <FailureDetail>{};
    config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(sampleConfigNoOverride);
  });

  group('validateCheckRuns', () {
    test('ValidateCheckRuns no failures for skipped conclusion.', () {
      githubService.checkRunsData = skippedCheckRunsMock;
      final Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const bool allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isTrue);
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns no failures for successful conclusion.', () {
      githubService.checkRunsData = checkRunsMock;
      final Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const bool allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isTrue);
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns no failure for status completed and neutral conclusion.', () {
      githubService.checkRunsData = neutralCheckRunsMock;
      final Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const bool allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isTrue);
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns failure detected on status completed no neutral conclusion.', () {
      githubService.checkRunsData = failedCheckRunsMock;
      final Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const bool allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isFalse);
        expect(failures, isNotEmpty);
        expect(failures.length, 1);
      });
    });

    test('ValidateCheckRuns succes with multiple successful check runs.', () {
      githubService.checkRunsData = multipleCheckRunsMock;
      final Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const bool allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isTrue);
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns failed with multiple check runs.', () {
      githubService.checkRunsData = multipleCheckRunsWithFailureMock;
      final Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const bool allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isFalse);
        expect(failures, isNotEmpty);
        expect(failures.length, 1);
      });
    });

    test('ValidateCheckRuns allSucces false but no failures recorded.', () {
      /// This test just checks that a checkRun that has not yet completed and
      /// does not cause failure is a candidate to be temporarily ignored.
      githubService.checkRunsData = inprogressAndNotFailedCheckRunMock;
      final Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const bool allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isFalse);
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns allSuccess false is preserved.', () {
      githubService.checkRunsData = multipleCheckRunsWithFailureMock;
      final Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const bool allSuccess = false;

      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isFalse);
        expect(failures, isNotEmpty);
        expect(failures.length, 1);
      });
    });
  });

  group('validateStatuses', () {
    test('Validate successful statuses show as successful.', () {
      final List<ContextNode> contextNodeList = getContextNodeListFromJson(repositoryStatusesMock);
      const bool allSuccess = true;
      final Author author = Author(login: 'ricardoamador');

      /// The status must be uppercase as the original code is expecting this.
      convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, author, [], contextNodeList, failures, allSuccess), isTrue);
      expect(failures, isEmpty);
    });

    test('Validate statuses that are not successful but do not cause failure.', () {
      final List<ContextNode> contextNodeList = getContextNodeListFromJson(failedAuthorsStatusesMock);
      const bool allSuccess = true;
      final Author author = Author(login: 'ricardoamador');

      final List<String> labelNames = [];
      labelNames.add('warning: land on red to fix tree breakage');
      labelNames.add('Other label');

      convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, author, labelNames, contextNodeList, failures, allSuccess), isTrue);
      expect(failures, isEmpty);
    });

    test('Validate failure statuses do not cause failure with not in authors control.', () {
      final List<ContextNode> contextNodeList = getContextNodeListFromJson(failedAuthorsStatusesMock);
      const bool allSuccess = true;
      final Author author = Author(login: 'ricardoamador');

      final List<String> labelNames = [];
      labelNames.add('Compelling label');
      labelNames.add('Another Compelling label');

      convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, author, labelNames, contextNodeList, failures, allSuccess), isFalse);
      expect(failures, isEmpty);
    });

    test('Validate failure statuses cause failures with not in authors control.', () {
      final List<ContextNode> contextNodeList = getContextNodeListFromJson(failedNonAuthorsStatusesMock);
      const bool allSuccess = true;
      final Author author = Author(login: 'ricardoamador');

      final List<String> labelNames = [];
      labelNames.add('Compelling label');
      labelNames.add('Another Compelling label');

      convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, author, labelNames, contextNodeList, failures, allSuccess), isFalse);
      expect(failures, isNotEmpty);
      expect(failures.length, 2);
    });

    test('Validate failure statuses cause failures and preserves false allSuccess.', () {
      final List<ContextNode> contextNodeList = getContextNodeListFromJson(failedNonAuthorsStatusesMock);
      const bool allSuccess = false;
      final Author author = Author(login: 'ricardoamador');

      final List<String> labelNames = [];
      labelNames.add('Compelling label');
      labelNames.add('Another Compelling label');

      convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, author, labelNames, contextNodeList, failures, allSuccess), isFalse);
      expect(failures, isNotEmpty);
      expect(failures.length, 2);
    });

    test('Validate flutter-gold is not checked for engine auto roller pull requests.', () {
      final List<ContextNode> contextNodeList = getContextNodeListFromJson(repositoryStatusesWithGoldMock);
      const bool allSuccess = true;
      final Author author = Author(login: 'skia-flutter-autoroll');
      slug = github.RepositorySlug('flutter', 'engine');

      final List<String> labelNames = [];
      labelNames.add('Compelling label');
      labelNames.add('Another Compelling label');

      convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, author, labelNames, contextNodeList, failures, allSuccess), isTrue);
      expect(failures, isEmpty);
      expect(failures.length, 0);
    });

    test('Validate flutter-gold is not checked even if failing for engine auto roller pull requests.', () {
      final List<ContextNode> contextNodeList = getContextNodeListFromJson(repositoryStatusesWithFailedGoldMock);
      const bool allSuccess = true;
      final Author author = Author(login: 'skia-flutter-autoroll');
      slug = github.RepositorySlug('flutter', 'engine');

      final List<String> labelNames = [];
      labelNames.add('Compelling label');
      labelNames.add('Another Compelling label');

      convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, author, labelNames, contextNodeList, failures, allSuccess), isTrue);
      expect(failures, isEmpty);
      expect(failures.length, 0);
    });

    test('Validate flutter-gold is checked for non engine auto roller pull requests.', () {
      final List<ContextNode> contextNodeList = getContextNodeListFromJson(repositoryStatusesWithFailedGoldMock);
      const bool allSuccess = true;
      final Author author = Author(login: 'ricardoamador');
      slug = github.RepositorySlug('flutter', 'engine');

      final List<String> labelNames = [];
      labelNames.add('Compelling label');
      labelNames.add('Another Compelling label');

      convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, author, labelNames, contextNodeList, failures, allSuccess), isFalse);
      expect(failures, isNotEmpty);
      expect(failures.length, 1);
    });
  });

  group('treeStatusCheck', () {
    test('Validate tree status is set contains slug.', () {
      slug = github.RepositorySlug('flutter', 'flutter');
      final List<ContextNode> contextNodeList = getContextNodeListFromJson(repositoryStatusesMock);
      expect(contextNodeList.isEmpty, false);

      /// The status must be uppercase as the original code is expecting this.
      convertContextNodeStatuses(contextNodeList);
      final bool treeStatusFlag = ciSuccessful.treeStatusCheck(slug, contextNodeList);
      expect(treeStatusFlag, true);
    });

    test('Validate tree status is set does not contain slug.', () {
      slug = github.RepositorySlug('flutter', 'infra');
      final List<ContextNode> contextNodeList = getContextNodeListFromJson(repositoryStatusesMock);
      expect(contextNodeList.isEmpty, false);

      /// The status must be uppercase as the original code is expecting this.
      convertContextNodeStatuses(contextNodeList);
      final bool treeStatusFlag = ciSuccessful.treeStatusCheck(slug, contextNodeList);
      expect(treeStatusFlag, true);
    });

    test('Validate tree status is set but context does not match slug.', () {
      slug = github.RepositorySlug('flutter', 'flutter');
      final List<ContextNode> contextNodeList = getContextNodeListFromJson(repositoryStatusesNonLuciFlutterMock);

      /// The status must be uppercase as the original code is expecting this.
      convertContextNodeStatuses(contextNodeList);
      final bool treeStatusFlag = ciSuccessful.treeStatusCheck(slug, contextNodeList);
      expect(treeStatusFlag, false);
    });
  });

  group('validate', () {
    test('Commit has a null status, no statuses to verify.', () {
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(nullStatusCommitRepositoryJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final PullRequest pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);
      final Commit commit = pr.commits!.nodes!.single.commit!;
      expect(commit, isNotNull);
      expect(commit.status, isNull);

      final github.PullRequest npr = generatePullRequest(labelName: 'needs tests');
      githubService.checkRunsData = checkRunsMock;

      ciSuccessful.validate(queryResult, npr).then((value) {
        // fails because in this case there is only a single fail status
        expect(false, value.result);
        // Remove label.
        expect(value.action, Action.IGNORE_TEMPORARILY);
        expect(value.message, 'Hold to wait for the tree status ready.');
      });
    });

    test('Commit has no statuses to verify.', () {
      final Map<String, dynamic> queryResultJsonDecode = jsonDecode(noStatusInCommitJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final PullRequest pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);

      final github.PullRequest npr = generatePullRequest(labelName: 'needs tests');
      githubService.checkRunsData = checkRunsMock;

      ciSuccessful.validate(queryResult, npr).then((value) {
        // fails because in this case there is only a single fail status
        expect(false, value.result);
        // Remove label.
        expect(value.action, Action.IGNORE_TEMPORARILY);
        expect(value.message, 'Hold to wait for the tree status ready.');
      });
    });

    // When branch is default we need to wait for the tree status if it is not
    // present.
    test('Commit has no statuses to verify.', () {
      final Map<String, dynamic> queryResultJsonDecode = jsonDecode(noStatusInCommitJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final PullRequest pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);

      final github.PullRequest npr = generatePullRequest();
      githubService.checkRunsData = checkRunsMock;

      ciSuccessful.validate(queryResult, npr).then((value) {
        // fails because in this case there is only a single fail status
        expect(false, value.result);
        // Remove label.
        expect(value.action, Action.IGNORE_TEMPORARILY);
        expect(value.message, 'Hold to wait for the tree status ready.');
      });
    });

    // Test for when the base branch is not default, we should not check the
    // tree status as it does not apply.
    test('Commit has no statuses to verify and base branch is not default.', () {
      final Map<String, dynamic> queryResultJsonDecode = jsonDecode(noStatusInCommitJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final PullRequest pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);

      final github.PullRequest npr = generatePullRequest(baseRef: 'test_feature');
      githubService.checkRunsData = checkRunsMock;

      ciSuccessful.validate(queryResult, npr).then((value) {
        expect(true, value.result);
        // Remove label.
        expect(value.action, Action.REMOVE_LABEL);
        expect(value.message, isEmpty);
      });
    });

    test('Commit has statuses to verify, action remove label, no message.', () {
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(nonNullStatusSUCCESSCommitRepositoryJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final PullRequest pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);
      final Commit commit = pr.commits!.nodes!.single.commit!;
      expect(commit, isNotNull);
      expect(commit.status, isNotNull);

      final github.PullRequest npr = generatePullRequest(labelName: 'needs tests');
      githubService.checkRunsData = checkRunsMock;

      ciSuccessful.validate(queryResult, npr).then((value) {
        // No failure.
        expect(value.result, isTrue);
        // Remove label.
        expect((value.action == Action.REMOVE_LABEL), isTrue);
        expect(value.message, isEmpty);
      });
    });

    test('Commit has statuses to verify, action ignore failure, no message.', () {
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(nonNullStatusFAILURECommitRepositoryJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final PullRequest pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);
      final Commit commit = pr.commits!.nodes!.single.commit!;
      expect(commit, isNotNull);
      expect(commit.status, isNotNull);

      final github.PullRequest npr = generatePullRequest(labelName: 'warning: land on red to fix tree breakage');
      githubService.checkRunsData = checkRunsMock;

      ciSuccessful.validate(queryResult, npr).then((value) {
        // No failure.
        expect(value.result, isTrue);
        // Remove label.
        expect((value.action == Action.IGNORE_FAILURE), isTrue);
        expect(value.message, isEmpty);
      });
    });

    test('Commit has statuses to verify, action failure, no message.', () {
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(nonNullStatusFAILURECommitRepositoryJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final PullRequest pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);
      final Commit commit = pr.commits!.nodes!.single.commit!;
      expect(commit, isNotNull);
      expect(commit.status, isNotNull);

      final github.PullRequest npr = generatePullRequest();
      githubService.checkRunsData = checkRunsMock;

      ciSuccessful.validate(queryResult, npr).then((value) {
        // No failure.
        expect(false, value.result);
        // Remove label.
        expect((value.action == Action.IGNORE_TEMPORARILY), isTrue);
        expect(value.message, isEmpty);
      });
    });
  });

  group('Validate empty message is not returned.', () {
    setUp(() {
      githubService = FakeGithubService(client: MockGitHub());
      config = FakeConfig(githubService: githubService);
      ciSuccessful = CiSuccessful(config: config);
      slug = github.RepositorySlug('flutter', 'cocoon');
      config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(sampleConfigNoOverride);
    });

    test('returns correct message when validation fails', () async {
      final PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      githubService.checkRunsData = failedCheckRunsMock;
      final github.PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      final QueryResult queryResult = createQueryResult(flutterRequest);

      final ValidationResult validationResult = await ciSuccessful.validate(queryResult, pullRequest);

      expect(validationResult.result, false);
      expect(
        validationResult.message,
        '- The status or check suite [ci.yaml validation](https://example.com) has failed. Please fix the issues identified (or deflake) before re-applying this label.\n',
      );
    });
  });
}
