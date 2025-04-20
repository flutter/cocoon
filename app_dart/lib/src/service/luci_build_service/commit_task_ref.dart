// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../model/firestore/commit.dart' as fs;
import '../../model/firestore/task.dart' as fs;

/// Represents components of a GitHub commit without specifying the backend.
@immutable
final class CommitRef {
  factory CommitRef.fromFirestore(fs.Commit commit) {
    return CommitRef(sha: commit.sha, branch: commit.branch, slug: commit.slug);
  }

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

/// Represents components of a backend task without specifying the backend.
@immutable
final class TaskRef {
  factory TaskRef.fromFirestore(fs.Task task) {
    return TaskRef(
      name: task.taskName,
      currentAttempt: task.currentAttempt,
      status: task.status,
      commitSha: task.commitSha,
    );
  }

  const TaskRef({
    required this.name,
    required this.currentAttempt,
    required this.status,
    required this.commitSha,
  });

  /// Name of the task.
  final String name;

  /// Which attempt number;
  final int currentAttempt;

  /// Status of the task.
  final String status;

  /// Commit the task belongs to.
  final String commitSha;

  @override
  bool operator ==(Object other) {
    if (other is! TaskRef) {
      return false;
    }
    return name == other.name &&
        currentAttempt == other.currentAttempt &&
        status == other.status &&
        commitSha == other.commitSha;
  }

  @override
  int get hashCode {
    return Object.hash(name, currentAttempt, status, commitSha);
  }

  @override
  String toString() {
    return 'Task <$name (SHA=$commitSha): $status ($currentAttempt)>';
  }
}
