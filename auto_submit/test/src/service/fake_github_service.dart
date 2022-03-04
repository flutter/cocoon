// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:auto_submit/service/github_service.dart';
import 'package:github/github.dart';

import '../../requests/github_webhook_test_data.dart';
import '../../utilities/mocks.dart';

/// A fake GithubService implementation.
class FakeGithubService implements GithubService {
  FakeGithubService({GitHub? client}) : github = client ?? MockGitHub();

  @override
  final GitHub github;

  @override
  Future<List<PullRequestReview>> getReviews(RepositorySlug slug,
      {required int prNumber}) async {
    List<dynamic> reviews = json.decode(reviewsMock) as List;
    List<PullRequestReview> prReviews = reviews
        .map((dynamic review) => PullRequestReview.fromJson(review))
        .toList();
    return prReviews;
  }
}
