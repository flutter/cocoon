// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/github.dart' as github;
import 'package:test/test.dart';
import 'package:auto_submit/validations/ci_successful.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';

import '../utilities/mocks.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../requests/github_webhook_test_data.dart';


void main() {
  late CiSuccessful ciSuccessful;
  late FakeConfig config;
  final FakeGithubService githubService = FakeGithubService();
  late FakeGraphQLClient githubGraphQLClient;
  final MockGitHub gitHub = MockGitHub();
  late github.RepositorySlug slug;
  late Set<FailureDetail> failures;

  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient, githubClient: gitHub);
    ciSuccessful = CiSuccessful(config: config);
    slug = github.RepositorySlug('owner', 'name');
    failures = <FailureDetail>{};
  });


  group('validateCheckRuns', () {
    test('validateCheckRuns no failures for skipped conclusion', () {
      githubService.checkRunsData = skippedCheckRunsMock;
      
      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(true, ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess));
        expect(true, failures.isEmpty);
      });
    });

    test('validateCheckRuns no failures for successful conclusion', () {
      githubService.checkRunsData = checkRunsMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(true, ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess));
        expect(true, failures.isEmpty);
      });
    });

    test('validateCheckRuns no failure for status completed and neutral conclusion', () {
      githubService.checkRunsData = neutralCheckRunsMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(true, ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess));
        expect(true, failures.isEmpty);
      });
    });

    test('validateCheckRuns failure detected on status completed no neutral conclusion', () {
      githubService.checkRunsData = failedCheckRunsMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(false, ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess));
        expect(false, failures.isEmpty);
        expect(1, failures.length);
      });
    });

    test('validateCheckRuns succes with multiple successful check runs', () {
      githubService.checkRunsData = multipleCheckRunsMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(true, ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess));
        expect(true, failures.isEmpty);
      });
    });

    test('validateCheckRuns failed with multiple check runs', () {
      githubService.checkRunsData = multipleCheckRunsWithFailureMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(false, ciSuccessful.validateCheckRuns(slug ,checkRuns, failures, allSuccess));
        expect(false, failures.isEmpty);
        expect(1, failures.length);
      });
    });

    test('validateCheckRuns allSucces false but no failures recorded', () {
      /// This test just checks that a checkRun that has not yet completed and 
      /// does not cause failure is a candidate to be temporarily ignored.
      githubService.checkRunsData = inprogressAndNotFailedCheckRunMock;

      Future<List<github.CheckRun>> checkRunFuture = githubService.getCheckRuns(slug, 'ref');
      bool allSuccess = true;
      checkRunFuture.then((checkRuns) {
        expect(false, ciSuccessful.validateCheckRuns(slug, checkRuns, failures, allSuccess));
        expect(true, failures.isEmpty);
      });
    });
  });

  group('validateStatuses', () {
    void convertContextNodeStatuses(List<ContextNode> contextNodeList) {
      for (ContextNode contextNode in contextNodeList) {
        contextNode.state = contextNode.state!.toUpperCase();
      }
    }

    List<ContextNode> getContextNodeListFromJson(final String repositoryStatuses) {
      List<ContextNode> contextNodeList = [];

      Map<String, dynamic> contextNodeMap = jsonDecode(repositoryStatuses) as Map<String, dynamic>;

      dynamic statuses = contextNodeMap['statuses'];
      for (Map<String, dynamic> map in statuses) {
        contextNodeList.add(ContextNode.fromJson(map));
      }

      return contextNodeList;
    }

    test('validate successful statuses', () {
      List<ContextNode> contextNodeList = [];
      bool allSuccess = true;

      contextNodeList = getContextNodeListFromJson(repositoryStatusesMock);

      /// The status must be uppercase as the original code is expecting this.
      convertContextNodeStatuses(contextNodeList);
      expect(true, ciSuccessful.validateStatuses(slug, [], contextNodeList, failures, allSuccess));
      expect(true, failures.isEmpty);
    });
  });
}