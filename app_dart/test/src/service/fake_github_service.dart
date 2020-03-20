// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/server.dart';

/// A fake GithubService implementation.
class FakeGithubService implements GithubService {
  List<RepositoryCommit> Function(String) listCommitsBranch;
  List<PullRequest> Function(String) listPullRequestsBranch;

  @override
  final GitHub github = null;

  @override
  Future<List<RepositoryCommit>> listCommits(
      RepositorySlug slug, String branch) async {
    return listCommitsBranch(branch);
  }

  @override
  Future<List<PullRequest>> listPullRequests(
      RepositorySlug slug, String branch) async {
    return listPullRequestsBranch(branch);
  }
}
