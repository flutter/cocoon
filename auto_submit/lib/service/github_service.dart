// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';

/// The [GithubService] handles communication with the GitHub API.
class GithubService {
  GithubService(this.github);

  final GitHub github;

  /// Gets a pull request with the pr number
  Future<PullRequest> getPullRequest(
    RepositorySlug slug, {
    required int prNumber,
  }) {
    ArgumentError.checkNotNull(slug);
    ArgumentError.checkNotNull(prNumber);
    return github.pullRequests.get(slug, prNumber);
  }
}
