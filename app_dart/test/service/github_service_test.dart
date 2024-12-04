// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:cocoon_service/src/service/github_service.dart';
import 'package:cocoon_server/testing/mocks.dart';

import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../src/utilities/mocks.dart';

void main() {
  late GithubService githubService;
  MockGitHub mockGitHub;
  late RepositorySlug slug;

  const String branch = 'master';
  const int lastCommitTimestampMills = 100;

  const String authorName = 'Jane Doe';
  const String authorEmail = 'janedoe@example.com';
  const String authorDate = '2000-01-01T10:10:10Z';
  const String authorLogin = 'Username';
  const String authorAvatarUrl = 'http://example.com/avatar';
  const String commitMessage = 'commit message';

  List<String> shas;

  setUp(() {
    shas = <String>[];
    mockGitHub = MockGitHub();
    githubService = GithubService(mockGitHub);
    slug = RepositorySlug('flutter', 'flutter');
    final PostExpectation<Future<http.Response>> whenGithubRequest = when(
      mockGitHub.request(
        'GET',
        '/repos/${slug.owner}/${slug.name}/commits',
        headers: anyNamed('headers'),
        params: anyNamed('params'),
        body: anyNamed('body'),
        statusCode: anyNamed('statusCode'),
      ),
    );
    whenGithubRequest.thenAnswer((_) async {
      final List<dynamic> data = <dynamic>[];
      for (String sha in shas) {
        // https://developer.github.com/v3/repos/commits/#list-commits
        data.add(<String, dynamic>{
          'sha': sha,
          'commit': <String, dynamic>{
            'message': commitMessage,
            'author': <String, dynamic>{
              'name': authorName,
              'email': authorEmail,
              'date': authorDate,
            },
          },
          'author': <String, dynamic>{
            'login': authorLogin,
            'avatar_url': authorAvatarUrl,
          },
        });
      }
      return http.Response(json.encode(data), HttpStatus.ok);
    });
  });

  test('listCommits decodes all relevant fields of each commit', () async {
    shas = <String>['1'];
    final List<RepositoryCommit> commits = await githubService.listBranchedCommits(
      slug,
      branch,
      lastCommitTimestampMills,
    );
    expect(commits, hasLength(1));
    final RepositoryCommit commit = commits.single;
    expect(commit.sha, shas.single);
    expect(commit.author, isNotNull);
    expect(commit.author!.login, authorLogin);
    expect(commit.author!.avatarUrl, authorAvatarUrl);
    expect(commit.commit, isNotNull);
    expect(commit.commit!.message, commitMessage);
    expect(commit.commit!.committer, isNotNull);
    expect(commit.commit!.committer!.name, authorName);
    expect(commit.commit!.committer!.email, authorEmail);
  });

  test('searchIssuesAndPRs encodes query properly', () async {
    mockGitHub = MockGitHub();
    final mockSearchService = MockSearchService();
    when(mockGitHub.search).thenReturn(mockSearchService);
    when(mockSearchService.issues(any)).thenAnswer((invocation) {
      expect(
        invocation.positionalArguments[0],
        '6afa96d84e2ecf6537f8ea76341d8ba397942e80%20repo%3Aflutter%2Fflutter',
      );
      return const Stream.empty();
    });
    githubService = GithubService(mockGitHub);
    await githubService.searchIssuesAndPRs(
      slug,
      '6afa96d84e2ecf6537f8ea76341d8ba397942e80',
    );
  });
}
