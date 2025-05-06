// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/commit_ref.dart';
import 'package:cocoon_service/src/model/task_ref.dart';
import 'package:test/test.dart';

import '../delegate_matcher.dart';

const isCommitRef = CommitRefMatcher._(TypeMatcher());
const isTaskRef = TaskRefMatcher._(TypeMatcher());

final class CommitRefMatcher extends DelegateMatcher<CommitRef> {
  const CommitRefMatcher._(super._delegate);

  CommitRefMatcher hasSha(Object? matcherOr) {
    return CommitRefMatcher._(having((e) => e.sha, 'sha', matcherOr));
  }

  CommitRefMatcher hasBranch(Object? matcherOr) {
    return CommitRefMatcher._(having((e) => e.branch, 'branch', matcherOr));
  }

  CommitRefMatcher hasSlug(Object? matcherOr) {
    return CommitRefMatcher._(having((e) => e.slug, 'slug', matcherOr));
  }
}

final class TaskRefMatcher extends DelegateMatcher<TaskRef> {
  const TaskRefMatcher._(super._delegate);

  TaskRefMatcher hasName(Object? matcherOr) {
    return TaskRefMatcher._(having((e) => e.name, 'name', matcherOr));
  }

  TaskRefMatcher hasCurrentAttempt(Object? matcherOr) {
    return TaskRefMatcher._(
      having((e) => e.currentAttempt, 'currentAttempt', matcherOr),
    );
  }

  TaskRefMatcher hasStatus(Object? matcherOr) {
    return TaskRefMatcher._(having((e) => e.status, 'status', matcherOr));
  }

  TaskRefMatcher hasCommitSha(Object? matcherOr) {
    return TaskRefMatcher._(having((e) => e.commitSha, 'commitSha', matcherOr));
  }
}
