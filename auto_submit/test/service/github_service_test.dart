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
  late MockPullRequestsService mockPullRequestsService;
  late RepositorySlug slug;
  late PullRequest testPr;
  final MockGitHub mockGitHub = MockGitHub();

  const int number = 1347;
  const int id = 1;
  const bool mergeable = true;
  const String labelName = 'autosubmit';

  setUp(() {
    mockPullRequestsService = MockPullRequestsService();
    githubService = GithubService(mockGitHub);
    slug = RepositorySlug('flutter', 'cocoon');
    testPr = PullRequest.fromJson(
      jsonDecode('{"id": $id, "number": $number, "mergeable": $mergeable, "labels": [{"name": "$labelName"}]}')
          as Map<String, dynamic>,
    );

    when(mockGitHub.pullRequests).thenReturn(mockPullRequestsService);
    when(mockPullRequestsService.get(slug, number)).thenAnswer((_) async {
      return testPr;
    });
  });

  test('listCommits decodes all relevant fields of each commit', () async {
    final PullRequest pr = await githubService.getPullRequest(slug, prNumber: number);
    expect(pr.id, id);
    expect(pr.number, number);
    expect(pr.mergeable, mergeable);
    expect(testPr.labels![0].name, 'autosubmit');
  });
}
