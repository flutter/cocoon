// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'firestore_matcher.dart';

final class TaskMatcher extends ModelMatcher<Task> {
  const TaskMatcher._(super._delegate) : super._();

  @override
  AppDocumentMetadata<Task> get metadata => Task.metadata;

  TaskMatcher hasBringup(Object? matcherOr) {
    return TaskMatcher._(
      _delegate.having((Task task) => task.bringup, 'bringup', matcherOr),
    );
  }

  TaskMatcher hasBuildNumber(Object? matcherOr) {
    return TaskMatcher._(
      _delegate.having(
        (Task task) => task.buildNumber,
        'buildNumber',
        matcherOr,
      ),
    );
  }

  TaskMatcher hasCommitSha(Object? matcherOr) {
    return TaskMatcher._(
      _delegate.having((Task task) => task.commitSha, 'commitSha', matcherOr),
    );
  }

  TaskMatcher hasCreateTimestamp(Object? matcherOr) {
    return TaskMatcher._(
      _delegate.having(
        (Task task) => task.createTimestamp,
        'createTimestamp',
        matcherOr,
      ),
    );
  }

  TaskMatcher hasStartTimestamp(Object? matcherOr) {
    return TaskMatcher._(
      _delegate.having(
        (Task task) => task.startTimestamp,
        'startTimestamp',
        matcherOr,
      ),
    );
  }

  TaskMatcher hasEndTimestamp(Object? matcherOr) {
    return TaskMatcher._(
      _delegate.having(
        (Task task) => task.endTimestamp,
        'endTimestamp',
        matcherOr,
      ),
    );
  }

  TaskMatcher hasTaskName(Object? matcherOr) {
    return TaskMatcher._(
      _delegate.having((Task task) => task.taskName, 'taskName', matcherOr),
    );
  }

  TaskMatcher hasStatus(Object? matcherOr) {
    return TaskMatcher._(
      _delegate.having((Task task) => task.status, 'status', matcherOr),
    );
  }

  TaskMatcher hasAttempts(Object? matcherOr) {
    return TaskMatcher._(
      _delegate.having((Task task) => task.attempts, 'attempts', matcherOr),
    );
  }

  TaskMatcher hasTestFlaky(Object? matcherOr) {
    return TaskMatcher._(
      _delegate.having((Task task) => task.testFlaky, 'testFlaky', matcherOr),
    );
  }
}
