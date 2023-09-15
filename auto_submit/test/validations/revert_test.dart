// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/configuration/repository_configuration.dart';
import 'package:auto_submit/model/auto_submit_query_result.dart';
import 'package:auto_submit/validations/validation.dart';
import 'package:github/github.dart' as github;
import 'package:retry/retry.dart';
import 'package:test/test.dart';

import '../configuration/repository_configuration_data.dart';
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
  final MockGitHub gitHub = MockGitHub();
  late Revert revert;

  /// Setup objects needed across test groups.
  setUp(() {
    githubService = FakeGithubService();
    githubGraphQLClient = FakeGraphQLClient();
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient, githubClient: gitHub);
    config.repositoryConfigurationMock = RepositoryConfiguration.fromYaml(sampleConfigNoOverride);
    revert = Revert(
      config: config,
      retryOptions: const RetryOptions(delayFactor: Duration.zero, maxDelay: Duration.zero, maxAttempts: 1),
    );
  });

  group('Pattern matching for revert text link', () {
    test('Link extraction from description is successful.', () {
      // input, expected
      final Map<String, String> tests = <String, String>{};
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
      tests['''Reverts flutter/cocoon#123456

      Some other notes in the description a developer might add.
      And another note.'''] = 'flutter/cocoon#123456';
      tests['Pull request Reverts flutter/flutter#12334 is happening continuously.'] = 'flutter/flutter#12334';
      tests['Reverts reverts flutter/flutter#9876'] = 'flutter/flutter#9876';
      tests['''Some junk reverts flutter/cocoon#4563 is happening continuously.
      Some other tests in the description that someone might add.
      '''] = 'flutter/cocoon#4563';
      tests['This some text to add flavor before reverts flutter/flutter#8888.'] = 'flutter/flutter#8888';

      tests.forEach((key, value) {
        final String? linkFound = revert.extractLinkFromText(key);
        assert(linkFound != null);
        assert(linkFound == value);
      });
    });

    test('Link extraction from description returns null', () {
      final Map<String, String> tests = <String, String>{};
      tests['Revert flutter/cocoon#123456'] = '';
      tests['revert flutter/cocoon#123456'] = '';
      tests['Reverts flutter/cocoon#'] = '';
      tests['Reverts flutter123'] = '';
      // We should not allow processing of more than one link as this can be cause
      // suspicion of other non revert changes in the pull request.
      tests['''Reverts flutter/flutter#12345
      Reverts flutter/flutter#34543'''] = '';
      tests['''This some text to add flavor before reverts flutter/flutter#8888.
      Also please reverts flutter/flutter#7678.
      And reverts flutter/flutter#8763.
      '''] = '';
      tests['This is some text flutter/flutter#456...44'] = '';

      tests.forEach((key, value) {
        final String? linkFound = revert.extractLinkFromText(key);
        assert(linkFound == null);
      });
    });
  });

  group('Validate Pull Requests.', () {
    test('Validation fails on author validation, returns error.', () async {
      githubService.fileContentsMockList = [sampleConfigNoOverride, sampleConfigNoOverride];
      githubService.isTeamMemberMockMap['author1'] = false;
      final Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      final github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      revertPullRequest.authorAssociation = 'CONTRIBUTOR';
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryContributorJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      githubService.pullRequestMock = revertPullRequest;
      final ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);
      assert(!validationResult.result);
      assert(validationResult.action == Action.REMOVE_LABEL);
      assert(validationResult.message.contains(RegExp(r'The author.*does not have permissions to make this request.')));
    });

    test('Validation fails on merge conflict flag.', () async {
      githubService.fileContentsMockList = [sampleConfigNoOverride, sampleConfigNoOverride];
      githubService.isTeamMemberMockMap['author1'] = true;
      final Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      final github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      revertPullRequest.mergeable = false;
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryOwnerJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      githubService.pullRequestMock = revertPullRequest;
      final ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);
      assert(!validationResult.result);
      assert(validationResult.action == Action.REMOVE_LABEL);
      assert(
        validationResult.message ==
            'This pull request cannot be merged due to conflicts. Please resolve conflicts and re-add the revert label.',
      );
    });

    test('Validation is postponed on null mergeable value', () async {
      githubService.fileContentsMockList = [sampleConfigNoOverride, sampleConfigNoOverride];
      githubService.isTeamMemberMockMap['author1'] = true;
      final Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      final github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      revertPullRequest.mergeable = null;
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryOwnerJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      githubService.pullRequestMock = revertPullRequest;
      final ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);
      assert(!validationResult.result);
      assert(validationResult.action == Action.IGNORE_TEMPORARILY);
      assert(validationResult.message.contains('Github is still calculating mergeability of pr# '));
    });

    test('Validation fails on malformed reverts link in the pr body.', () async {
      githubService.fileContentsMockList = [sampleConfigNoOverride, sampleConfigNoOverride];
      githubService.isTeamMemberMockMap['author1'] = true;
      final Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      final github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      revertPullRequest.body = 'Reverting flutter/cocoon#1234';
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryOwnerJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);
      githubService.pullRequestMock = revertPullRequest;
      final ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);
      assert(!validationResult.result);
      assert(validationResult.action == Action.REMOVE_LABEL);
      assert(
        validationResult.message ==
            'A reverts link could not be found or was formatted incorrectly. Format is \'Reverts owner/repo#id\'',
      );
    });

    test('Validation returns on checkRun that has not completed.', () async {
      githubService.fileContentsMockList = [sampleConfigNoOverride, sampleConfigNoOverride];
      githubService.isTeamMemberMockMap['author1'] = true;
      final Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      final github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryOwnerJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);

      final Map<String, dynamic> originalPullRequestJsonMap =
          jsonDecode(originalPullRequestJson) as Map<String, dynamic>;
      final github.PullRequest originalPullRequest = github.PullRequest.fromJson(originalPullRequestJsonMap);
      githubService.pullRequestData = originalPullRequest;

      // code gets the original file list then the current file list.
      githubService.usePullRequestFilesList = true;
      githubService.pullRequestFilesMockList.add(originalPullRequestFilesJson);
      githubService.pullRequestFilesMockList.add(revertPullRequestFilesJson);

      // Need to set the mock checkRuns for required CheckRun validation
      githubService.checkRunsData = ciyamlCheckRunNotComplete;
      githubService.pullRequestMock = revertPullRequest;
      revert = Revert(
        config: config,
        retryOptions: const RetryOptions(
          delayFactor: Duration.zero,
          maxDelay: Duration.zero,
          maxAttempts: 1,
        ),
      );
      final ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);

      expect(validationResult.result, isFalse);
      expect(validationResult.action, Action.IGNORE_TEMPORARILY);
      expect(validationResult.message, 'Some of the required checks did not complete in time.');
    });

    test('Validation fails on pull request file lists not matching.', () async {
      githubService.fileContentsMockList = [sampleConfigNoOverride, sampleConfigNoOverride];
      githubService.isTeamMemberMockMap['author1'] = true;
      final Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      final github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryOwnerJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);

      final Map<String, dynamic> originalPullRequestJsonMap =
          jsonDecode(originalPullRequestJson) as Map<String, dynamic>;
      final github.PullRequest originalPullRequest = github.PullRequest.fromJson(originalPullRequestJsonMap);
      githubService.pullRequestData = originalPullRequest;

      // code gets the original file list then the current file list.
      githubService.usePullRequestFilesList = true;
      githubService.pullRequestFilesMockList.add(originalPullRequestFilesSubsetJson);
      githubService.pullRequestFilesMockList.add(revertPullRequestFilesJson);

      // Need to set the mock checkRuns for required CheckRun validation
      githubService.checkRunsData = ciyamlCheckRun;

      githubService.pullRequestMock = revertPullRequest;

      final ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);
      assert(!validationResult.result);
      assert(validationResult.action == Action.REMOVE_LABEL);
      assert(
        validationResult.message ==
            'Validation of the revert request has failed. Verify the files in the revert request are the same as the original PR and resubmit the revert request.',
      );
    });

    test('Validation is successful.', () async {
      githubService.fileContentsMockList = [sampleConfigNoOverride, sampleConfigNoOverride];
      githubService.isTeamMemberMockMap['author1'] = true;
      final Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      final github.PullRequest revertPullRequest = github.PullRequest.fromJson(pullRequestJsonMap);
      final Map<String, dynamic> queryResultJsonDecode =
          jsonDecode(queryResultRepositoryOwnerJson) as Map<String, dynamic>;
      final QueryResult queryResult = QueryResult.fromJson(queryResultJsonDecode);

      final Map<String, dynamic> originalPullRequestJsonMap =
          jsonDecode(originalPullRequestJson) as Map<String, dynamic>;
      final github.PullRequest originalPullRequest = github.PullRequest.fromJson(originalPullRequestJsonMap);
      githubService.pullRequestData = originalPullRequest;

      // code gets the original file list then the current file list.
      githubService.usePullRequestFilesList = true;
      githubService.pullRequestFilesMockList.add(originalPullRequestFilesJson);
      githubService.pullRequestFilesMockList.add(revertPullRequestFilesJson);

      // Need to set the mock checkRuns for required CheckRun validation
      githubService.checkRunsData = ciyamlCheckRun;

      githubService.pullRequestMock = revertPullRequest;

      final ValidationResult validationResult = await revert.validate(queryResult, revertPullRequest);
      assert(validationResult.result);
      assert(validationResult.message == 'Revert request has been verified and will be queued for merge.');
    });
  });
}
