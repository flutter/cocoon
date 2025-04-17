// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../../model/appengine/commit.dart' as ds;
import '../../model/appengine/task.dart' as ds;
import '../../model/firestore/commit.dart' as fs;
import '../../model/firestore/task.dart' as fs;

/// Represents components of a GitHub commit without specifying the backend.
///
/// This is used transitory to migrate from Datastore -> Firestore.
@immutable
abstract final class OpaqueCommit {
  factory OpaqueCommit.fromFirestore(fs.Commit commit) = _FirestoreCommit;
  factory OpaqueCommit.fromDatastore(ds.Commit commit) = _DatastoreCommit;
  const OpaqueCommit();

  /// The commit SHA.
  String get sha;

  /// The commit branch.
  String get branch;

  /// The commit repository (owner and repo) on GitHub.
  RepositorySlug get slug;

  @override
  bool operator ==(Object other) {
    if (other is! OpaqueCommit) {
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

final class _FirestoreCommit extends OpaqueCommit {
  _FirestoreCommit(this._commit);
  final fs.Commit _commit;

  @override
  String get sha => _commit.sha;

  @override
  String get branch => _commit.branch;

  @override
  RepositorySlug get slug => _commit.slug;
}

final class _DatastoreCommit extends OpaqueCommit {
  _DatastoreCommit(this._commit);
  final ds.Commit _commit;

  @override
  String get sha => _commit.sha!;

  @override
  String get branch => _commit.branch!;

  @override
  RepositorySlug get slug => _commit.slug;
}

/// Represents components of a backend task without specifying the backend.
///
/// This is used transitory to migrate from Datastore -> Firestore.
@immutable
abstract final class OpaqueTask {
  factory OpaqueTask.fromFirestore(fs.Task task) = _FirestoreTask;
  factory OpaqueTask.fromDatastore(ds.Task task) = _DatastoreTask;
  const OpaqueTask();

  /// Name of the task.
  String get name;

  /// Which attempt number;
  int get currentAttempt;

  /// Status of the task.
  String get status;

  /// Commit the task belongs to.
  String get commitSha;

  @override
  bool operator ==(Object other) {
    if (other is! OpaqueTask) {
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
    return 'Task <$name ($commitSha): $status ($currentAttempt)>';
  }
}

final class _FirestoreTask extends OpaqueTask {
  const _FirestoreTask(this._task);
  final fs.Task _task;

  @override
  String get name => _task.taskName;

  @override
  int get currentAttempt => _task.currentAttempt;

  @override
  String get status => _task.status;

  @override
  String get commitSha => _task.commitSha;
}

final class _DatastoreTask extends OpaqueTask {
  const _DatastoreTask(this._task);
  final ds.Task _task;

  @override
  String get name => _task.builderName!;

  @override
  int get currentAttempt => _task.attempts!;

  @override
  String get status => _task.status;

  @override
  String get commitSha => _task.commitKey!.id!.split('/').last;
}
