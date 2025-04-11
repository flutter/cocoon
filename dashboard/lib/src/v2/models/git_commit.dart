// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'git_branch.dart';
import 'github_repository.dart';

/// Represnts a commit on a branch of a Git repository.
@immutable
final class GitCommit {
  GitCommit({
    required this.sha,
    required this.branch,
    required this.repository,
    required this.createdOn,
    required this.author,
    required this.avatarUrl,
    required this.message,
  });

  /// Git SHA.
  final String sha;

  /// Branch that the commit was written to.
  final GitBranch branch;

  /// Repository that the commit belongs to.
  final GithubRepository repository;

  /// When the commit was created.
  final DateTime createdOn;

  /// The (github) author of the commit.
  final String author;

  /// The avatar (image URL) representing the commit.
  ///
  /// If omitted, a default avatar or placeholder can be used.
  final Uri? avatarUrl;

  /// The commit message.
  final String message;
}
