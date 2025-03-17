// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/model/pull_request_data_types.dart';
import 'package:auto_submit/service/config.dart';
import 'package:auto_submit/validations/ci_successful.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:cocoon_server/logging.dart';
import 'package:cocoon_server_test/mocks.dart';
import 'package:github/github.dart' as github;
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import '../configuration/repository_configuration_data.dart';
import '../requests/github_webhook_test_data.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../utilities/utils.dart';
import 'ci_successful_test_data.dart';

void main() {
  late CiSuccessful ciSuccessful;
  late FakeConfig config;
  var githubService = FakeGithubService();
  late FakeGraphQLClient githubGraphQLClient;
  final gitHub = MockGitHub();
  late github.RepositorySlug slug;
  late Set<FailureDetail> failures;
  const prNumber = 1;

  List<ContextNode> getContextNodeListFromJson(
    final String repositoryStatuses,
  ) {
    final contextNodeList = <ContextNode>[];

    final contextNodeMap =
        jsonDecode(repositoryStatuses) as Map<String, dynamic>;

    final statuses = contextNodeMap['statuses'] as List<Object?>;
    for (final map in statuses.cast<Map<String, dynamic>>()) {
      contextNodeList.add(ContextNode.fromJson(map));
    }

    return contextNodeList;
  }

  void convertContextNodeStatuses(List<ContextNode> contextNodeList) {
    for (var contextNode in contextNodeList) {
      contextNode.state = contextNode.state!.toUpperCase();
    }
  }

  /// Setup objects needed across test groups.
  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    config = FakeConfig(
      githubService: githubService,
      githubGraphQLClient: githubGraphQLClient,
      githubClient: gitHub,
    );
    ciSuccessful = CiSuccessful(config: config);
    slug = github.RepositorySlug('octocat', 'flutter');
    failures = <FailureDetail>{};
    config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(
      sampleConfigNoOverride,
    );
  });

  group('validateCheckRuns', () {
    test('ValidateCheckRuns no failures for skipped conclusion.', () {
      githubService.checkRunsData = skippedCheckRunsMock;
      final checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(
          ciSuccessful.validateCheckRuns(
            slug,
            prNumber,
            PullRequestState.open,
            checkRuns,
            failures,
            allSuccess,
            Author(login: 'testAuthor'),
          ),
          isTrue,
        );
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns no failures for successful conclusion.', () {
      githubService.checkRunsData = checkRunsMock;
      final checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(
          ciSuccessful.validateCheckRuns(
            slug,
            prNumber,
            PullRequestState.open,
            checkRuns,
            failures,
            allSuccess,
            Author(login: 'testAuthor'),
          ),
          isTrue,
        );
        expect(failures, isEmpty);
      });
    });

    test(
      'ValidateCheckRuns no failure for status completed and neutral conclusion.',
      () {
        githubService.checkRunsData = neutralCheckRunsMock;
        final checkRunFuture = githubService.getCheckRuns(slug, 'ref');
        const allSuccess = true;

        checkRunFuture.then((checkRuns) {
          expect(
            ciSuccessful.validateCheckRuns(
              slug,
              prNumber,
              PullRequestState.open,
              checkRuns,
              failures,
              allSuccess,
              Author(login: 'testAuthor'),
            ),
            isTrue,
          );
          expect(failures, isEmpty);
        });
      },
    );

    test(
      'ValidateCheckRuns failure detected on status completed no neutral conclusion.',
      () {
        githubService.checkRunsData = failedCheckRunsMock;
        final checkRunFuture = githubService.getCheckRuns(slug, 'ref');
        const allSuccess = true;

        checkRunFuture.then((checkRuns) {
          expect(
            ciSuccessful.validateCheckRuns(
              slug,
              prNumber,
              PullRequestState.open,
              checkRuns,
              failures,
              allSuccess,
              Author(login: 'testAuthor'),
            ),
            isFalse,
          );
          expect(failures, isNotEmpty);
          expect(failures.length, 1);
        });
      },
    );

    test('ValidateCheckRuns succes with multiple successful check runs.', () {
      githubService.checkRunsData = multipleCheckRunsMock;
      final checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(
          ciSuccessful.validateCheckRuns(
            slug,
            prNumber,
            PullRequestState.open,
            checkRuns,
            failures,
            allSuccess,
            Author(login: 'testAuthor'),
          ),
          isTrue,
        );
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns failed with multiple check runs.', () {
      githubService.checkRunsData = multipleCheckRunsWithFailureMock;
      final checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(
          ciSuccessful.validateCheckRuns(
            slug,
            prNumber,
            PullRequestState.open,
            checkRuns,
            failures,
            allSuccess,
            Author(login: 'testAuthor'),
          ),
          isFalse,
        );
        expect(failures, isNotEmpty);
        expect(failures.length, 1);
      });
    });

    test('ValidateCheckRuns allSucces false but no failures recorded.', () {
      /// This test just checks that a checkRun that has not yet completed and
      /// does not cause failure is a candidate to be temporarily ignored.
      githubService.checkRunsData = inprogressAndNotFailedCheckRunMock;
      final checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const allSuccess = true;

      checkRunFuture.then((checkRuns) {
        expect(
          ciSuccessful.validateCheckRuns(
            slug,
            prNumber,
            PullRequestState.open,
            checkRuns,
            failures,
            allSuccess,
            Author(login: 'testAuthor'),
          ),
          isFalse,
        );
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns allSuccess false is preserved.', () {
      githubService.checkRunsData = multipleCheckRunsWithFailureMock;
      final checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      const allSuccess = false;

      checkRunFuture.then((checkRuns) {
        expect(
          ciSuccessful.validateCheckRuns(
            slug,
            prNumber,
            PullRequestState.open,
            checkRuns,
            failures,
            allSuccess,
            Author(login: 'testAuthor'),
          ),
          isFalse,
        );
        expect(failures, isNotEmpty);
        expect(failures.length, 1);
      });
    });
  });

  group('validateStatuses', () {
    test('Validate successful statuses show as successful.', () {
      final contextNodeList = getContextNodeListFromJson(
        repositoryStatusesMock,
      );
      const allSuccess = true;
      final author = Author(login: 'ricardoamador');

      /// The status must be uppercase as the original code is expecting this.
      convertContextNodeStatuses(contextNodeList);
      expect(
        ciSuccessful.validateStatuses(
          slug,
          prNumber,
          PullRequestState.open,
          author,
          [],
          contextNodeList,
          failures,
          allSuccess,
        ),
        isTrue,
      );
      expect(failures, isEmpty);
    });

    test(
      'Validate statuses that are not successful but do not cause failure.',
      () {
        final contextNodeList = getContextNodeListFromJson(
          failedAuthorsStatusesMock,
        );
        const allSuccess = true;
        final author = Author(login: 'ricardoamador');

        final labelNames = <String>[];
        labelNames.add(Config.kEmergencyLabel);
        labelNames.add('Other label');

        convertContextNodeStatuses(contextNodeList);
        expect(
          ciSuccessful.validateStatuses(
            slug,
            prNumber,
            PullRequestState.open,
            author,
            labelNames,
            contextNodeList,
            failures,
            allSuccess,
          ),
          isTrue,
        );
        expect(failures, isEmpty);
      },
    );

    test(
      'Validate failure statuses do not cause failure with not in authors control.',
      () {
        final contextNodeList = getContextNodeListFromJson(
          failedAuthorsStatusesMock,
        );
        const allSuccess = true;
        final author = Author(login: 'ricardoamador');

        final labelNames = <String>[];
        labelNames.add('Compelling label');
        labelNames.add('Another Compelling label');

        convertContextNodeStatuses(contextNodeList);
        expect(
          ciSuccessful.validateStatuses(
            slug,
            prNumber,
            PullRequestState.open,
            author,
            labelNames,
            contextNodeList,
            failures,
            allSuccess,
          ),
          isFalse,
        );
        expect(failures, isEmpty);
      },
    );

    test(
      'Validate failure statuses cause failures with not in authors control.',
      () {
        final contextNodeList = getContextNodeListFromJson(
          failedNonAuthorsStatusesMock,
        );
        const allSuccess = true;
        final author = Author(login: 'ricardoamador');

        final labelNames = <String>[];
        labelNames.add('Compelling label');
        labelNames.add('Another Compelling label');

        convertContextNodeStatuses(contextNodeList);
        expect(
          ciSuccessful.validateStatuses(
            slug,
            prNumber,
            PullRequestState.open,
            author,
            labelNames,
            contextNodeList,
            failures,
            allSuccess,
          ),
          isFalse,
        );
        expect(failures, isNotEmpty);
        expect(failures.length, 2);
      },
    );

    test(
      'Validate failure statuses cause failures and preserves false allSuccess.',
      () {
        final contextNodeList = getContextNodeListFromJson(
          failedNonAuthorsStatusesMock,
        );
        const allSuccess = false;
        final author = Author(login: 'ricardoamador');

        final labelNames = <String>[];
        labelNames.add('Compelling label');
        labelNames.add('Another Compelling label');

        convertContextNodeStatuses(contextNodeList);
        expect(
          ciSuccessful.validateStatuses(
            slug,
            prNumber,
            PullRequestState.open,
            author,
            labelNames,
            contextNodeList,
            failures,
            allSuccess,
          ),
          isFalse,
        );
        expect(failures, isNotEmpty);
        expect(failures.length, 2);
      },
    );

    test(
      'Validate flutter-gold is checked for engine auto roller pull requests.',
      () {
        final contextNodeList = getContextNodeListFromJson(
          repositoryStatusesWithGoldMock,
        );
        const allSuccess = true;
        final author = Author(login: 'skia-flutter-autoroll');
        slug = github.RepositorySlug('flutter', 'flutter');

        final labelNames = <String>[];
        labelNames.add('Compelling label');
        labelNames.add('Another Compelling label');

        convertContextNodeStatuses(contextNodeList);
        expect(
          ciSuccessful.validateStatuses(
            slug,
            prNumber,
            PullRequestState.open,
            author,
            labelNames,
            contextNodeList,
            failures,
            allSuccess,
          ),
          isFalse,
        );
        expect(failures, isEmpty);
        expect(failures.length, 0);
      },
    );

    test(
      'Validate flutter-gold is checked even if failing for engine auto roller pull requests.',
      () {
        final contextNodeList = getContextNodeListFromJson(
          repositoryStatusesWithFailedGoldMock,
        );
        const allSuccess = true;
        final author = Author(login: 'skia-flutter-autoroll');
        slug = github.RepositorySlug('flutter', 'flutter');

        final labelNames = <String>[];
        labelNames.add('Compelling label');
        labelNames.add('Another Compelling label');

        convertContextNodeStatuses(contextNodeList);
        expect(
          ciSuccessful.validateStatuses(
            slug,
            prNumber,
            PullRequestState.open,
            author,
            labelNames,
            contextNodeList,
            failures,
            allSuccess,
          ),
          isFalse,
        );
        expect(failures, isNotEmpty);
        expect(failures.length, 1);
      },
    );

    test(
      'Validate flutter-gold is checked for non engine auto roller pull requests.',
      () {
        final contextNodeList = getContextNodeListFromJson(
          repositoryStatusesWithFailedGoldMock,
        );
        const allSuccess = true;
        final author = Author(login: 'ricardoamador');
        slug = github.RepositorySlug('flutter', 'flutter');

        final labelNames = <String>[];
        labelNames.add('Compelling label');
        labelNames.add('Another Compelling label');

        convertContextNodeStatuses(contextNodeList);
        expect(
          ciSuccessful.validateStatuses(
            slug,
            prNumber,
            PullRequestState.open,
            author,
            labelNames,
            contextNodeList,
            failures,
            allSuccess,
          ),
          isFalse,
        );
        expect(failures, isNotEmpty);
        expect(failures.length, 1);
      },
    );

    test(
      'Validate that stale PR warnings are only generated for open PRs.',
      () async {
        final contextNodeList = getContextNodeListFromJson(
          repositoryStatusesWithStaleGoldMock,
        );
        const allSuccess = true;
        final author = Author(login: 'engine-flutter-autoroll');
        slug = github.RepositorySlug('flutter', 'flutter');

        final labelNames = <String>[];
        labelNames.add('Compelling label');
        labelNames.add('Another Compelling label');

        convertContextNodeStatuses(contextNodeList);

        final logWarnings = <LogRecord>[];
        final subscription = log.onRecord.listen((record) {
          if (record.level == Level.WARNING) {
            logWarnings.add(record);
          }
        });

        try {
          ciSuccessful.validateStatuses(
            slug,
            prNumber,
            PullRequestState.open,
            author,
            labelNames,
            contextNodeList,
            failures,
            allSuccess,
          );
          expect(logWarnings.length, 1);

          logWarnings.clear();
          ciSuccessful.validateStatuses(
            slug,
            prNumber,
            PullRequestState.closed,
            author,
            labelNames,
            contextNodeList,
            failures,
            allSuccess,
          );
          expect(logWarnings.length, 0);
        } finally {
          await subscription.cancel();
        }
      },
    );
  });

  group('treeStatusCheck', () {
    test('Validate tree status is set contains slug.', () {
      slug = github.RepositorySlug('flutter', 'flutter');
      final contextNodeList = getContextNodeListFromJson(
        repositoryStatusesMock,
      );
      expect(contextNodeList.isEmpty, false);

      /// The status must be uppercase as the original code is expecting this.
      convertContextNodeStatuses(contextNodeList);
      final treeStatusFlag = ciSuccessful.isTreeStatusReporting(
        slug,
        prNumber,
        contextNodeList,
      );
      expect(treeStatusFlag, true);
    });

    test('Validate tree status is set does not contain slug.', () {
      slug = github.RepositorySlug('flutter', 'infra');
      final contextNodeList = getContextNodeListFromJson(
        repositoryStatusesMock,
      );
      expect(contextNodeList.isEmpty, false);

      /// The status must be uppercase as the original code is expecting this.
      convertContextNodeStatuses(contextNodeList);
      final treeStatusFlag = ciSuccessful.isTreeStatusReporting(
        slug,
        prNumber,
        contextNodeList,
      );
      expect(treeStatusFlag, true);
    });

    test('Validate tree status is set but context does not match slug.', () {
      slug = github.RepositorySlug('flutter', 'flutter');
      final contextNodeList = getContextNodeListFromJson(
        repositoryStatusesNonLuciFlutterMock,
      );

      /// The status must be uppercase as the original code is expecting this.
      convertContextNodeStatuses(contextNodeList);
      final treeStatusFlag = ciSuccessful.isTreeStatusReporting(
        slug,
        prNumber,
        contextNodeList,
      );
      expect(treeStatusFlag, false);
    });
  });

  group('validate', () {
    test('Commit has a null status, no statuses to verify.', () {
      final queryResultJsonDecode =
          jsonDecode(nullStatusCommitRepositoryJson) as Map<String, dynamic>;
      final queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);
      final commit = pr.commits!.nodes!.single.commit!;
      expect(commit, isNotNull);
      expect(commit.status, isNull);

      final npr = generatePullRequest();
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
      final queryResultJsonDecode =
          jsonDecode(noStatusInCommitJson) as Map<String, dynamic>;
      final queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);

      final npr = generatePullRequest();
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
      final queryResultJsonDecode =
          jsonDecode(noStatusInCommitJson) as Map<String, dynamic>;
      final queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);

      final npr = generatePullRequest();
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
    test(
      'Commit has no statuses to verify and base branch is not default.',
      () {
        final queryResultJsonDecode =
            jsonDecode(noStatusInCommitJson) as Map<String, dynamic>;
        final queryResult = QueryResult.fromJson(queryResultJsonDecode);
        expect(queryResult, isNotNull);
        final pr = queryResult.repository!.pullRequest!;
        expect(pr, isNotNull);

        final npr = generatePullRequest(baseRef: 'test_feature');
        githubService.checkRunsData = checkRunsMock;

        ciSuccessful.validate(queryResult, npr).then((value) {
          expect(true, value.result);
          // Remove label.
          expect(value.action, Action.REMOVE_LABEL);
          expect(value.message, isEmpty);
        });
      },
    );

    test('Commit has statuses to verify, action remove label, no message.', () {
      final queryResultJsonDecode =
          jsonDecode(nonNullStatusSUCCESSCommitRepositoryJson)
              as Map<String, dynamic>;
      final queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);
      final commit = pr.commits!.nodes!.single.commit!;
      expect(commit, isNotNull);
      expect(commit.status, isNotNull);

      final npr = generatePullRequest();
      githubService.checkRunsData = checkRunsMock;

      ciSuccessful.validate(queryResult, npr).then((value) {
        // No failure.
        expect(value.result, isTrue);
        // Remove label.
        expect(value.action == Action.REMOVE_LABEL, isTrue);
        expect(value.message, isEmpty);
      });
    });

    test(
      'Commit has statuses to verify, action ignore failure, no message.',
      () {
        final queryResultJsonDecode =
            jsonDecode(nonNullStatusFAILURECommitRepositoryJson)
                as Map<String, dynamic>;
        final queryResult = QueryResult.fromJson(queryResultJsonDecode);
        expect(queryResult, isNotNull);
        final pr = queryResult.repository!.pullRequest!;
        expect(pr, isNotNull);
        final commit = pr.commits!.nodes!.single.commit!;
        expect(commit, isNotNull);
        expect(commit.status, isNotNull);

        final npr = generatePullRequest(labelName: Config.kEmergencyLabel);
        githubService.checkRunsData = checkRunsMock;

        ciSuccessful.validate(queryResult, npr).then((value) {
          // No failure.
          expect(value.result, isTrue);
          // Remove label.
          expect(value.action == Action.IGNORE_FAILURE, isTrue);
          expect(value.message, isEmpty);
        });
      },
    );

    test('Commit has statuses to verify, action failure, no message.', () {
      final queryResultJsonDecode =
          jsonDecode(nonNullStatusFAILURECommitRepositoryJson)
              as Map<String, dynamic>;
      final queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      final pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);
      final commit = pr.commits!.nodes!.single.commit!;
      expect(commit, isNotNull);
      expect(commit.status, isNotNull);

      final npr = generatePullRequest();
      githubService.checkRunsData = checkRunsMock;

      ciSuccessful.validate(queryResult, npr).then((value) {
        // No failure.
        expect(false, value.result);
        // Remove label.
        expect(value.action == Action.IGNORE_TEMPORARILY, isTrue);
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
      config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(
        sampleConfigNoOverride,
      );
    });

    test('returns correct message when validation fails', () async {
      final flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      githubService.checkRunsData = failedCheckRunsMock;
      final pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      final queryResult = createQueryResult(flutterRequest);

      final validationResult = await ciSuccessful.validate(
        queryResult,
        pullRequest,
      );

      expect(validationResult.result, false);
      expect(
        validationResult.message,
        '- The status or check suite [failed_checkrun](https://example.com) has failed. Please fix the issues identified (or deflake) before re-applying this label.\n',
      );
    });
  });
  group('Validate if a datetime is stale', () {
    setUp(() {
      githubService = FakeGithubService(client: MockGitHub());
      config = FakeConfig(githubService: githubService);
      ciSuccessful = CiSuccessful(config: config);
    });

    test('when it is stale', () async {
      final isStale = ciSuccessful.isStale(
        DateTime.now().subtract(const Duration(hours: 3)),
      );
      expect(isStale, true);
    });
    test('when it is not stale', () async {
      final isStale = ciSuccessful.isStale(
        DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(isStale, false);
    });
  });

  group('Validate if an engine to framework roller', () {
    setUp(() {
      githubService = FakeGithubService(client: MockGitHub());
      config = FakeConfig(githubService: githubService);
      ciSuccessful = CiSuccessful(config: config);
    });

    test('when it is engine roller', () async {
      final isEngineRoller = ciSuccessful.isEngineToFrameworkRoller(
        Author(login: 'engine-flutter-autoroll'),
        github.RepositorySlug('flutter', 'flutter'),
      );
      expect(isEngineRoller, true);
    });
    test('when it is not from roller', () async {
      final isEngineRoller = ciSuccessful.isEngineToFrameworkRoller(
        Author(login: 'testAuthor'),
        github.RepositorySlug('flutter', 'flutter'),
      );
      expect(isEngineRoller, false);
    });
  });
}
