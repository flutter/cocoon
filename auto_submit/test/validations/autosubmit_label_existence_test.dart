// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/github.dart' as github;
import 'package:test/test.dart';
import 'package:auto_submit/validations/autosubmit_label_existence.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';

import 'validation_test_data.dart';
import '../utilities/mocks.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../requests/github_webhook_test_data.dart';

void main() {
  late AutosubmitLabelExistence autosubmitLabelExistence;
  late FakeConfig config;
  FakeGithubService githubService = FakeGithubService();
  late FakeGraphQLClient githubGraphQLClient;
  MockGitHub gitHub = MockGitHub();

  /// Setup objects needed across test groups.
  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient, githubClient: gitHub);
    autosubmitLabelExistence = AutosubmitLabelExistence(config: config);
  });

  group('validate', () {
    test('passes validate when autosubmit label still exists.', () {
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(nullStatusCommitRepositoryJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);

      final github.PullRequest npr = generatePullRequest(labelName: 'needs tests');
      githubService.checkRunsData = checkRunsMock;

      autosubmitLabelExistence.validate(queryResult, npr).then((value) {
        // fails because in this case there is only a single fail status
        expect(value.result, true);
      });
    });

    test('fails validate when autosubmit label does not exist.', () {
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(nullStatusCommitRepositoryJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);

      final github.PullRequest npr = generatePullRequest(autosubmitLabel: null);
      githubService.checkRunsData = checkRunsMock;

      autosubmitLabelExistence.validate(queryResult, npr).then((value) {
        // fails because in this case there is only a single fail status
        expect(value.result, false);
        expect(value.message, '- The autosubmit label has been removed. Please add it back when ready.');
      });
    });
  });
}
