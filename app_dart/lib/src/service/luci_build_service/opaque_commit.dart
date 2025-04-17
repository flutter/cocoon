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

  /// The commit SHA.
  String get sha;

  /// The commit branch.
  String get branch;

  /// The commit repository (owner and repo) on GitHub.
  RepositorySlug get slug;
}

final class _FirestoreCommit implements OpaqueCommit {
  _FirestoreCommit(this._commit);
  final fs.Commit _commit;

  @override
  String get sha => _commit.sha;

  @override
  String get branch => _commit.branch;

  @override
  RepositorySlug get slug => _commit.slug;
}

final class _DatastoreCommit implements OpaqueCommit {
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

  /// Name of the task.
  String get name;

  /// Which attempt number;
  int get currentAttempt;

  /// Status of the task.
  String get status;

  /// Commit the task belongs to.
  String get commitSha;
}

final class _FirestoreTask implements OpaqueTask {
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

final class _DatastoreTask implements OpaqueTask {
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
