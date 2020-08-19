// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/service/github_service.dart';
import 'package:github/github.dart';
import 'package:mockito/mockito.dart';

/// A fake GithubService implementation.
class FakeGithubService implements GithubService {
  List<RepositoryCommit> Function(String, int) listCommitsBranch;
  List<PullRequest> Function(String) listPullRequestsBranch;

  @override
  final GitHub github = MockGitHub();

  @override
  Future<List<RepositoryCommit>> listCommits(RepositorySlug slug, String branch, int lastCommitTimestampMills) async {
    return listCommitsBranch(branch, lastCommitTimestampMills);
  }

  @override
  Future<List<PullRequest>> listPullRequests(RepositorySlug slug, String branch) async {
    return listPullRequestsBranch(branch);
  }

  @override
  Future<List<String>> listFiles(RepositorySlug slug, int prNumber) async {
    return <String>['abc/def'];
  }
}

class MockGitHub extends Mock implements GitHub {}
