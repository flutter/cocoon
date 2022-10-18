// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import 'revert_test_data.dart';

import 'package:auto_submit/validations/revert.dart';

import '../utilities/mocks.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';

void main() {
  late FakeConfig config;
  late FakeGithubService githubService;
  late FakeGraphQLClient githubGraphQLClient;
  MockGitHub gitHub = MockGitHub();
  late Revert revert;

  /// Setup objects needed across test groups.
  setUp(() {
    githubService = FakeGithubService();
    githubGraphQLClient = FakeGraphQLClient();
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient, githubClient: gitHub);
    revert = Revert(
      config: config,
      retryOptions: const RetryOptions(delayFactor: Duration.zero, maxDelay: Duration.zero, maxAttempts: 1),
    );
  });

  group('Author validation tests.', () {
    test('Validate author association member is valid.', () {
      String authorAssociation = 'MEMBER';
      assert(revert.isValidAuthor('octocat', authorAssociation));
    });

    test('Validate author association owner is valid.', () {
      String authorAssociation = 'OWNER';
      assert(revert.isValidAuthor('octocat', authorAssociation));
    });

    test('Validate author dependabot is valid.', () {
      String author = 'dependabot';
      String authorAssociation = 'NON_MEMBER';
      assert(revert.isValidAuthor(author, authorAssociation));
    });

    test('Validate autoroller account is valid.', () {
      String author = 'engine-flutter-autoroll';
      String authorAssociation = 'CONTRIBUTOR';
      assert(revert.isValidAuthor(author, authorAssociation));
    });
  });

  group('Pattern matching for revert text link', () {
    test('Link extraction from description is successful.', () {
      // input, expected
      Map<String, String> tests = <String, String>{};
      tests['Reverts flutter/cocoon#123456'] = 'flutter/cocoon#123456';
      tests['Reverts    flutter/cocoon#123456'] = 'flutter/cocoon#123456';
      tests['Reverts flutter/flutter-intellij#123456'] = 'flutter/flutter-intellij#123456';
      tests['Reverts flutter/platform_tests#123456'] = 'flutter/platform_tests#123456';
      tests['Reverts flutter/.github#123456'] = 'flutter/.github#123456';
      tests['Reverts flutter/assets-for-api-docs#123456'] = 'flutter/assets-for-api-docs#123456';
      tests['Reverts flutter/flutter.github.io#123456'] = 'flutter/flutter.github.io#123456';
      tests['Reverts flutter/flutter_gallery_assets#123456'] = 'flutter/flutter_gallery_assets#123456';
      tests['reverts flutter/cocoon#12323'] = 'flutter/cocoon#12323';
      tests['reverts flutter/cocoon#223'] = 'flutter/cocoon#223';
      tests["""Reverts flutter/cocoon#123456

      Some other notes in the description a developer might add.
      And another note."""] = 'flutter/cocoon#123456';

      tests.forEach((key, value) {
        String? linkFound = revert.extractLinkFromText(key);
        assert(linkFound != null);
        assert(linkFound == value);
      });
    });

    test('Link extraction from description returns null', () {
      // input, expected
      Map<String, String> tests = <String, String>{};
      tests['Revert flutter/cocoon#123456'] = '';
      tests['revert flutter/cocoon#123456'] = '';
      tests['Reverts flutter/cocoon#'] = '';
      tests['Reverts flutter123'] = '';

      tests.forEach((key, value) {
        String? linkFound = revert.extractLinkFromText(key);
        assert(linkFound == null);
      });
    });
  });

  group('Validate Pull Requests.', () {
    test('Validation fails on author validation, returns error.', () async {
      Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      revertPullRequest.authorAssociation = 'CONTRIBUTOR';
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryContributorJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);
      assert(!validationResult.result);
      assert(validationResult.action == Action.REMOVE_LABEL);
      assert(validationResult.message.contains(RegExp(r'The author.*does not have permissions to make this request.')));
    });

    test('Validation fails on merge conflict flag.', () async {
      Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      revertPullRequest.mergeable = false;
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryOwnerJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);
      assert(!validationResult.result);
      assert(validationResult.action == Action.REMOVE_LABEL);
      assert(
        validationResult.message ==
            'This pull request cannot be merged due to conflicts. Please resolve conflicts and re-add the revert label.',
      );
    });

    test('Validation fails on malformed reverts link in the pr body.', () async {
      Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      revertPullRequest.body = 'Reverting flutter/cocoon#1234';
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryOwnerJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);
      assert(!validationResult.result);
      assert(validationResult.action == Action.REMOVE_LABEL);
      assert(
        validationResult.message ==
            'A reverts link could not be found or was formatted incorrectly. Format is \'Reverts owner/repo#id\'',
      );
    });

    test('Validation returns on checkRun that has not completed.', () async {
      Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryOwnerJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);

      Map<String, dynamic> originalPullRequestJsonMap = jsonDecode(originalPullRequestJson) as Map<String, dynamic>;
      github.PullRequest originalPullRequest = github.PullRequest.fromJson(originalPullRequestJsonMap);
      githubService.pullRequestData = originalPullRequest;

      // code gets the original file list then the current file list.
      githubService.usePullRequestFilesList = true;
      githubService.pullRequestFilesMockList.add(originalPullRequestFilesJson);
      githubService.pullRequestFilesMockList.add(revertPullRequestFilesJson);

      // Need to set the mock checkRuns for required CheckRun validation
      githubService.checkRunsData = ciyamlCheckRunNotComplete;

      revert = Revert(
        config: config,
        retryOptions: const RetryOptions(
          delayFactor: Duration.zero,
          maxDelay: Duration.zero,
          maxAttempts: 1,
        ),
      );
      ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);

      expect(validationResult.result, isFalse);
      expect(validationResult.action, Action.IGNORE_TEMPORARILY);
      expect(validationResult.message, 'Some of the required checks did not complete in time.');
    });

    test('Validation fails on pull request file lists not matching.', () async {
      Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryOwnerJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);

      Map<String, dynamic> originalPullRequestJsonMap = jsonDecode(originalPullRequestJson) as Map<String, dynamic>;
      github.PullRequest originalPullRequest = github.PullRequest.fromJson(originalPullRequestJsonMap);
      githubService.pullRequestData = originalPullRequest;

      // code gets the original file list then the current file list.
      githubService.usePullRequestFilesList = true;
      githubService.pullRequestFilesMockList.add(originalPullRequestFilesSubsetJson);
      githubService.pullRequestFilesMockList.add(revertPullRequestFilesJson);

      // Need to set the mock checkRuns for required CheckRun validation
      githubService.checkRunsData = ciyamlCheckRun;

      ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);
      assert(!validationResult.result);
      assert(validationResult.action == Action.REMOVE_LABEL);
      assert(
        validationResult.message ==
            'Validation of the revert request has failed. Verify the files in the revert request are the same as the original PR and resubmit the revert request.',
      );
    });

    test('Validation is successful.', () async {
      Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryOwnerJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);

      Map<String, dynamic> originalPullRequestJsonMap = jsonDecode(originalPullRequestJson) as Map<String, dynamic>;
      github.PullRequest originalPullRequest = github.PullRequest.fromJson(originalPullRequestJsonMap);
      githubService.pullRequestData = originalPullRequest;

      // code gets the original file list then the current file list.
      githubService.usePullRequestFilesList = true;
      githubService.pullRequestFilesMockList.add(originalPullRequestFilesJson);
      githubService.pullRequestFilesMockList.add(revertPullRequestFilesJson);

      // Need to set the mock checkRuns for required CheckRun validation
      githubService.checkRunsData = ciyamlCheckRun;

      ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);
      assert(validationResult.result);
      assert(validationResult.message == 'Revert request has been verified and will be queued for merge.');
    });
  });
}
