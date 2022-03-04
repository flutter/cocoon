// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';

/// [GithubService] handles communication with the GitHub API.
class GithubService {
  GithubService(this.github);

  final GitHub github;

  /// Retrieves the reviews for a pull request.
  Future<List<PullRequestReview>> getReviews(
    RepositorySlug slug, {
    required int prNumber,
  }) async {
    return await github.pullRequests.listReviews(slug, prNumber).toList();
  }
}
