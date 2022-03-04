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
  late PullRequestReview testReview;
  late List<PullRequestReview> testReviews;
  final MockGitHub mockGitHub = MockGitHub();
  final MockPullRequestsService mockPullRequestsService = MockPullRequestsService();
  final String user = '''{"login": "octocat", "id": 1}''';

  const int number = 1347;
  const int id = 1;
  const String state = "APPROVED";

  setUp(() {
    githubService = GithubService(mockGitHub);
    slug = RepositorySlug('flutter', 'cocoon');
    testReview = PullRequestReview.fromJson(
      jsonDecode('{"id": $id, "user": $user, "state": "$state"}') as Map<String, dynamic>,
    );
    testReviews = <PullRequestReview>[testReview];

    when(mockGitHub.pullRequests).thenReturn(mockPullRequestsService);
    when(mockPullRequestsService.listReviews(slug, number))
        .thenAnswer((_) => Stream<PullRequestReview>.fromIterable(testReviews));
  });

  test('listReviews retrieves all reviews of the pull request', () async {
    final List<PullRequestReview> reviews = await githubService.getReviews(slug, prNumber: number);
    PullRequestReview review = reviews[0];
    expect(review.id, id);
    expect(review.state, state);
  });
}
