// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/service/github_service.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../utilities/mocks.dart';

void main() {
  late GithubService githubService;
  late RepositorySlug slug;
  late RepositoryCommit testCommit;
  final MockGitHub mockGitHub = MockGitHub();
  final MockRepositoriesService mockRepositoriesService = MockRepositoriesService();

  const String author = '''{"login": "octocat", "id": 1}''';
  const String url = 'testUrl';
  const String sha = '6dcb09b5b57875f334f61aebed695e2e4193db5e';

  setUp(() {
    githubService = GithubService(mockGitHub);
    slug = RepositorySlug('flutter', 'cocoon');
    testCommit = RepositoryCommit.fromJson(
      jsonDecode('{"url": "$url", "author": $author, "sha": "$sha"}') as Map<String, dynamic>,
    );

    when(mockGitHub.repositories).thenReturn(mockRepositoriesService);
    when(mockRepositoriesService.getCommit(slug, sha)).thenAnswer((_) => Future.value(testCommit));
  });

  test('listReviews retrieves all reviews of the pull request', () async {
    final RepositoryCommit commit = await githubService.getCommit(slug, sha);
    expect(commit.author!.login, 'octocat');
    expect(commit.url, 'testUrl');
    expect(commit.sha, '6dcb09b5b57875f334f61aebed695e2e4193db5e');
  });
}
