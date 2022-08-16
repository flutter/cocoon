// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/github.dart';

import 'revert_test_data.dart';

import 'package:auto_submit/validations/revert.dart';
import 'package:test/scaffolding.dart';

import '../utilities/utils.dart';
import '../utilities/mocks.dart';
import '../src/service/fake_config.dart';
import '../src/service/fake_github_service.dart';
import '../src/service/fake_graphql_client.dart';
import '../requests/github_webhook_test_data.dart';

void main() {
  late FakeConfig config;
  FakeGithubService githubService = FakeGithubService();
  late FakeGraphQLClient githubGraphQLClient;
  MockGitHub gitHub = MockGitHub();
  late Revert revert;
  

  /// Setup objects needed across test groups.
  setUp(() {
    githubGraphQLClient = FakeGraphQLClient();
    config = FakeConfig(githubService: githubService, githubGraphQLClient: githubGraphQLClient, githubClient: gitHub);
    revert = Revert(config: config);
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

  group('Get slug from pull request link tests.', () {
    test('Slug is successfully extracted from link.', () {
      String link = 'flutter/cocoon#123456';
      RepositorySlug? slug = revert.getSlugFromLink(link);
      assert(slug != null);
      assert(slug!.owner == 'flutter');
      assert(slug!.name == 'cocoon');
    });

    test('Slug cannot be successfully extracted from link partial.', () {
      String link = 'flutter/cocoon';
      RepositorySlug? slug = revert.getSlugFromLink(link);
      assert(slug == null);
    });
  });

  group('Get pull request id from pull requst link tests.', () {
    test('Pull Request id is successfully extracted from provided link.', () {
      String link = 'flutter/cocoon#234';
      int? id = revert.getPullRequestIdFromLink(link);
      assert(id != null);
      assert(id == 234);
    });

    test('Pull request id cannot be extracted from link.', () {
      String link = 'flutter/cocoon1234';
      int? id = revert.getPullRequestIdFromLink(link);
      assert(id == null);
    });
  });

  group('Validate pull request file sets.', () {
    test('Validate pull request file sets match.', () async {
      RepositorySlug slug = RepositorySlug('cocoon', 'flutter');

      Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      PullRequest revertPullRequest = PullRequest.fromJson(pullRequestJsonMap);
      githubService.pullRequestData = revertPullRequest;
      githubService.pullRequestFilesJsonMock = revertPullRequestFilesJson;
      List<PullRequestFile> revertPullRequestFiles = await githubService.getPullRequestFiles(slug, revertPullRequest);

      Map<String, dynamic> pullRequestJsonMap2 = jsonDecode(originalPullRequestJson) as Map<String, dynamic>;
      PullRequest originalPullRequest = PullRequest.fromJson(pullRequestJsonMap2);
      githubService.pullRequestData = originalPullRequest;
      githubService.pullRequestFilesJsonMock = originalPullRequestFilesJson;
      List<PullRequestFile> originalPullRequestFiles = await githubService.getPullRequestFiles(slug, originalPullRequest);

      assert(revert.validateFileSetsAreEqual(revertPullRequestFiles, originalPullRequestFiles));
    });

    test('Validate that a subset of files is caught in the comparison', () async {
      RepositorySlug slug = RepositorySlug('cocoon', 'flutter');

      Map<String, dynamic> pullRequestJsonMap = jsonDecode(revertPullRequestJson) as Map<String, dynamic>;
      PullRequest revertPullRequest = PullRequest.fromJson(pullRequestJsonMap);
      githubService.pullRequestData = revertPullRequest;
      githubService.pullRequestFilesJsonMock = revertPullRequestFilesJson;
      List<PullRequestFile> revertPullRequestFiles = await githubService.getPullRequestFiles(slug, revertPullRequest);

      Map<String, dynamic> pullRequestJsonMap2 = jsonDecode(originalPullRequestJson) as Map<String, dynamic>;
      PullRequest originalPullRequest = PullRequest.fromJson(pullRequestJsonMap2);
      githubService.pullRequestData = originalPullRequest;
      githubService.pullRequestFilesJsonMock = originalPullRequestFilesSubsetJson;
      List<PullRequestFile> originalPullRequestFiles = await githubService.getPullRequestFiles(slug, originalPullRequest);

      assert(!revert.validateFileSetsAreEqual(revertPullRequestFiles, originalPullRequestFiles));
    });
  });
}
