// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/service/github_service.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:cocoon_server/testing/mocks.dart';

import '../requests/github_webhook_test_data.dart';

void main() {
  late GithubService githubService;
  late RepositorySlug slug;
  late RepositoryCommit testCommit;
  final MockGitHub mockGitHub = MockGitHub();
  final MockRepositoriesService mockRepositoriesService = MockRepositoriesService();
  final MockGitHubComparison mockGitHubComparison = MockGitHubComparison();
  final MockResponse mockResponse = MockResponse();

  const String author = '''{"login": "octocat", "id": 1}''';
  const String url = 'testUrl';
  const String sha = '6dcb09b5b57875f334f61aebed695e2e4193db5e';

  setUp(() {
    githubService = GithubService(mockGitHub);
    slug = RepositorySlug('flutter', 'cocoon');
    testCommit = RepositoryCommit.fromJson(
      jsonDecode('{"url": "$url", "author": $author, "sha": "$sha"}') as Map<String, dynamic>,
    );

    when(mockGitHubComparison.behindBy).thenReturn(10);
    when(
      mockGitHub.request(
        any,
        any,
        headers: anyNamed('headers'),
        params: anyNamed('params'),
        body: anyNamed('body'),
        statusCode: anyNamed('statusCode'),
        fail: anyNamed('fail'),
        preview: anyNamed('preview'),
      ),
    ).thenAnswer((_) => Future.value(mockResponse));
    when(mockResponse.statusCode).thenReturn(200);
    when(mockGitHub.repositories).thenReturn(mockRepositoriesService);
    when(mockRepositoriesService.getCommit(any, any)).thenAnswer((_) => Future.value(testCommit));
    when(mockRepositoriesService.compareCommits(any, any, any)).thenAnswer((_) => Future.value(mockGitHubComparison));
  });

  test('listReviews retrieves all reviews of the pull request', () async {
    final RepositoryCommit commit = await githubService.getCommit(slug, sha);
    expect(commit.author!.login, 'octocat');
    expect(commit.url, 'testUrl');
    expect(commit.sha, '6dcb09b5b57875f334f61aebed695e2e4193db5e');
  });

  test('Merges branch', () async {
    when(mockGitHubComparison.behindBy).thenReturn(10);
    final PullRequest pullRequest = generatePullRequest();
    await githubService.autoMergeBranch(pullRequest);
    verify(mockResponse.statusCode).called(1);
  });

  test('Does not merge branch', () async {
    when(mockGitHubComparison.behindBy).thenReturn(9);
    final PullRequest pullRequest = generatePullRequest();
    await githubService.autoMergeBranch(pullRequest);
    verifyNever(mockResponse.statusCode);
  });
}
