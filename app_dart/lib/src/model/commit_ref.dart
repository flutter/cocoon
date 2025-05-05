// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:meta/meta.dart';

/// Represents components of a GitHub commit without specifying the backend.
@immutable
final class CommitRef {
  const CommitRef({
    required this.sha,
    required this.branch,
    required this.slug,
  });

  /// The commit SHA.
  final String sha;

  /// The commit branch.
  final String branch;

  /// The commit repository (owner and repo) on GitHub.
  final RepositorySlug slug;

  @override
  bool operator ==(Object other) {
    if (other is! CommitRef) {
      return false;
    }
    return sha == other.sha && branch == other.branch && slug == other.slug;
  }

  @override
  int get hashCode {
    return Object.hash(sha, branch, slug);
  }

  @override
  String toString() {
    return 'Commit <$sha (${slug.fullName}/$branch)>';
  }
}
