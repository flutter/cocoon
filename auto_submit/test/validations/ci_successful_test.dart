// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/github.dart' as github;
import 'package:test/test.dart';
import 'package:auto_submit/validations/ci_successful.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';

import '../utilities/utils.dart';
import '../utilities/mocks.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../requests/github_webhook_test_data.dart';

void main() {
  late CiSuccessful ciSuccessful;
  late FakeConfig config;
  FakeGithubService githubService = FakeGithubService();
  late FakeGraphQLClient githubGraphQLClient;
  MockGitHub gitHub = MockGitHub();
  late github.RepositorySlug slug;
  late Set<FailureDetail> failures;

  List<ContextNode> _getContextNodeListFromJson(final String repositoryStatuses) {
    List<ContextNode> contextNodeList = [];

    Map<String, dynamic> contextNodeMap = jsonDecode(repositoryStatuses) as Map<String, dynamic>;

    dynamic statuses = contextNodeMap['statuses'];
    for (Map<String, dynamic> map in statuses) {
      contextNodeList.add(ContextNode.fromJson(map));
    }

    return contextNodeList;
  }

  void _convertContextNodeStatuses(List<ContextNode> contextNodeList) {
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
  });

  group('validateCheckRuns', () {
    test('ValidateCheckRuns no failures for skipped conclusion.', () {
      githubService.checkRunsData = skippedCheckRunsMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isTrue);
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns no failures for successful conclusion.', () {
      githubService.checkRunsData = checkRunsMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isTrue);
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns no failure for status completed and neutral conclusion.', () {
      githubService.checkRunsData = neutralCheckRunsMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isTrue);
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns failure detected on status completed no neutral conclusion.', () {
      githubService.checkRunsData = failedCheckRunsMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isFalse);
        expect(failures, isNotEmpty);
        expect((failures.length == 1), isTrue);
      });
    });

    test('ValidateCheckRuns succes with multiple successful check runs.', () {
      githubService.checkRunsData = multipleCheckRunsMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isTrue);
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns failed with multiple check runs.', () {
      githubService.checkRunsData = multipleCheckRunsWithFailureMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isFalse);
        expect(failures, isNotEmpty);
        expect((failures.length == 1), isTrue);
      });
    });

    test('ValidateCheckRuns allSucces false but no failures recorded.', () {
      /// This test just checks that a checkRun that has not yet completed and
      /// does not cause failure is a candidate to be temporarily ignored.
      githubService.checkRunsData = inprogressAndNotFailedCheckRunMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isFalse);
        expect(failures, isEmpty);
      });
    });

    test('ValidateCheckRuns allSuccess false is preserved.', () {
      githubService.checkRunsData = multipleCheckRunsWithFailureMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = false;
      checkRunFuture.then((checkRuns) {
        expect(ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess), isFalse);
        expect(failures, isNotEmpty);
        expect((failures.length == 1), isTrue);
      });
    });
  });

  group('validateStatuses', () {
    test('Validate successful statuses show as successful.', () {
      List<ContextNode> contextNodeList = [];
      bool allSuccess = true;

      contextNodeList = _getContextNodeListFromJson(repositoryStatusesMock);

      /// The status must be uppercase as the original code is expecting this.
      _convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, [], contextNodeList, failures, allSuccess), isTrue);
      expect(failures, isEmpty);
    });

    test('Validate statuses that are not successful but do not cause failure.', () {
      List<ContextNode> contextNodeList = [];
      bool allSuccess = true;

      contextNodeList = _getContextNodeListFromJson(failedAuthorsStatusesMock);
      List<String> labelNames = [];
      labelNames.add('warning: land on red to fix tree breakage');
      labelNames.add('Other label');
      _convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, labelNames, contextNodeList, failures, allSuccess), isTrue);
      expect(failures, isEmpty);
    });

    test('Validate failure statuses cause failure with not in authors control.', () {
      List<ContextNode> contextNodeList = [];
      bool allSuccess = true;

      List<String> labelNames = [];
      labelNames.add('Compelling label');
      labelNames.add('Another Compelling label');
      contextNodeList = _getContextNodeListFromJson(failedAuthorsStatusesMock);
      _convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, labelNames, contextNodeList, failures, allSuccess), isFalse);
      expect(failures, isEmpty);
    });

    test('Validate failure statuses cause failures with not in authors control.', () {
      List<ContextNode> contextNodeList = [];
      bool allSuccess = true;

      List<String> labelNames = [];
      labelNames.add('Compelling label');
      labelNames.add('Another Compelling label');
      contextNodeList = _getContextNodeListFromJson(failedNonAuthorsStatusesMock);
      _convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, labelNames, contextNodeList, failures, allSuccess), isFalse);
      expect(failures, isNotEmpty);
      expect((failures.length == 2), isTrue);
    });

    test('Validate failure statuses cause failures and preserves false allSuccess.', () {
      List<ContextNode> contextNodeList = [];
      bool allSuccess = false;

      List<String> labelNames = [];
      labelNames.add('Compelling label');
      labelNames.add('Another Compelling label');
      contextNodeList = _getContextNodeListFromJson(failedNonAuthorsStatusesMock);
      _convertContextNodeStatuses(contextNodeList);
      expect(ciSuccessful.validateStatuses(slug, labelNames, contextNodeList, failures, allSuccess), isFalse);
      expect(failures, isNotEmpty);
      expect((failures.length == 2), isTrue);
    });
  });

  group('validateTreeStatusIsSet', () {
    test('Validate tree status is set contains slug.', () {
      slug = github.RepositorySlug('octocat', 'flutter');
      List<ContextNode> contextNodeList = [];

      contextNodeList = _getContextNodeListFromJson(repositoryStatusesMock);

      /// The status must be uppercase as the original code is expecting this.
      _convertContextNodeStatuses(contextNodeList);
      ciSuccessful.validateTreeStatusIsSet(slug, contextNodeList, failures);
      expect(failures, isEmpty);
    });

    test('Validate tree status is set does not contain slug.', () {
      slug = github.RepositorySlug('octocat', 'infra');
      List<ContextNode> contextNodeList = [];

      contextNodeList = _getContextNodeListFromJson(repositoryStatusesMock);

      /// The status must be uppercase as the original code is expecting this.
      _convertContextNodeStatuses(contextNodeList);
      ciSuccessful.validateTreeStatusIsSet(slug, contextNodeList, failures);
      expect(failures, isEmpty);
    });

    test('Validate tree status is set but context does not match slug.', () {
      slug = github.RepositorySlug('flutter', 'flutter');
      List<ContextNode> contextNodeList = [];

      contextNodeList = _getContextNodeListFromJson(repositoryStatusesNonLuciFlutterMock);

      /// The status must be uppercase as the original code is expecting this.
      _convertContextNodeStatuses(contextNodeList);
      ciSuccessful.validateTreeStatusIsSet(slug, contextNodeList, failures);
      expect(failures, isNotEmpty);
      expect((failures.length == 1), isTrue);
    });
  });

  const String nullStatusCommitRepositoryJson = """
  {
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
        "authorAssociation": "MEMBER",
        "id": "PR_kwDOA8VHis43rs4_",
        "title": "[dependabot] Remove human reviewers",
        "commits": {
          "nodes":[
            {
              "commit": {
                "abbreviatedOid": "4009ecc",
                "oid": "4009ecc0b6dbf5cb19cb97472147063e7368ec10",
                "committedDate": "2022-05-11T22:35:02Z",
                "pushedDate": "2022-05-11T22:35:03Z",
                "status": null
              }
            }
          ]
        },
        "reviews": {
          "nodes": [
            {
              "author": {
                "login": "keyonghan"
              },
              "authorAssociation": "MEMBER",
              "state": "APPROVED"
            }
          ]
        }
      }
    }
  }
  """;

  const String nonNullStatusSUCCESSCommitRepositoryJson = """
  {
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
        "authorAssociation": "MEMBER",
        "id": "PR_kwDOA8VHis43rs4_",
        "title": "[dependabot] Remove human reviewers",
        "commits": {
          "nodes":[
            {
              "commit": {
                "abbreviatedOid": "4009ecc",
                "oid": "4009ecc0b6dbf5cb19cb97472147063e7368ec10",
                "committedDate": "2022-05-11T22:35:02Z",
                "pushedDate": "2022-05-11T22:35:03Z",
                "status": {
                  "contexts":[
                    {
                      "context":"luci-flutter",
                      "state":"SUCCESS",
                      "targetUrl":"https://ci.example.com/1000/output"
                    }
                  ]
                }
              }
            }
          ]
        },
        "reviews": {
          "nodes": [
            {
              "author": {
                "login": "keyonghan"
              },
              "authorAssociation": "MEMBER",
              "state": "APPROVED"
            }
          ]
        }
      }
    }
  }
  """;

  const String nonNullStatusFAILURECommitRepositoryJson = """
  {
    "repository": {
      "pullRequest": {
        "author": {
          "login": "author1"
        },
        "authorAssociation": "MEMBER",
        "id": "PR_kwDOA8VHis43rs4_",
        "title": "[dependabot] Remove human reviewers",
        "commits": {
          "nodes":[
            {
              "commit": {
                "abbreviatedOid": "4009ecc",
                "oid": "4009ecc0b6dbf5cb19cb97472147063e7368ec10",
                "committedDate": "2022-05-11T22:35:02Z",
                "pushedDate": "2022-05-11T22:35:03Z",
                "status": {
                  "contexts":[
                    {
                      "context":"luci-flutter",
                      "state":"FAILURE",
                      "targetUrl":"https://ci.example.com/1000/output"
                    }
                  ]
                }
              }
            }
          ]
        },
        "reviews": {
          "nodes": [
            {
              "author": {
                "login": "keyonghan"
              },
              "authorAssociation": "MEMBER",
              "state": "APPROVED"
            }
          ]
        }
      }
    }
  }
  """;

  group('validate', () {
    test('Commit has a null status, no statuses to verify.', () {
      Map<String, dynamic> queryResultJsonDecode = jsonDecode(nullStatusCommitRepositoryJson) as Map<String, dynamic>;
      QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      PullRequest pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);
      Commit commit = pr.commits!.nodes!.single.commit!;
      expect(commit, isNotNull);
      expect(commit.status, isNull);

      github.PullRequest npr = generatePullRequest(labelName: 'needs tests');
      githubService.checkRunsData = checkRunsMock;
      ciSuccessful.validate(queryResult, npr).then((value) {
        // No failure.
        expect(true, value.result);
        // Remove label.
        expect((value.action == Action.REMOVE_LABEL), isTrue);
        expect(value.message,
            '- The status or check suite [tree status luci-flutter](https://flutter-dashboard.appspot.com/#/build) has failed. Please fix the issues identified (or deflake) before re-applying this label.\n');
      });
    });

    test('Commit has statuses to verify, action remove label, no message.', () {
      Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(nonNullStatusSUCCESSCommitRepositoryJson) as Map<String, dynamic>;
      QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      PullRequest pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);
      Commit commit = pr.commits!.nodes!.single.commit!;
      expect(commit, isNotNull);
      expect(commit.status, isNotNull);

      github.PullRequest npr = generatePullRequest(labelName: 'needs tests');
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
      Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(nonNullStatusFAILURECommitRepositoryJson) as Map<String, dynamic>;
      QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      PullRequest pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);
      Commit commit = pr.commits!.nodes!.single.commit!;
      expect(commit, isNotNull);
      expect(commit.status, isNotNull);

      github.PullRequest npr = generatePullRequest(labelName: 'warning: land on red to fix tree breakage');
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
      Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(nonNullStatusFAILURECommitRepositoryJson) as Map<String, dynamic>;
      QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      expect(queryResult, isNotNull);
      PullRequest pr = queryResult.repository!.pullRequest!;
      expect(pr, isNotNull);
      Commit commit = pr.commits!.nodes!.single.commit!;
      expect(commit, isNotNull);
      expect(commit.status, isNotNull);

      github.PullRequest npr = generatePullRequest();
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
    });

    test('returns correct message when validation fails', () async {
      PullRequestHelper flutterRequest = PullRequestHelper(
        prNumber: 0,
        lastCommitHash: oid,
        reviews: <PullRequestReviewHelper>[],
      );

      githubService.checkRunsData = failedCheckRunsMock;
      final github.PullRequest pullRequest = generatePullRequest(prNumber: 0, repoName: slug.name);
      QueryResult queryResult = createQueryResult(flutterRequest);

      final ValidationResult validationResult = await ciSuccessful.validate(queryResult, pullRequest);

      expect(validationResult.result, false);
      expect(validationResult.message,
          '- The status or check suite [failed_checkrun](https://example.com) has failed. Please fix the issues identified (or deflake) before re-applying this label.\n');
    });
  });
}
