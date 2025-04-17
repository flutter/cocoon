// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handlers/scheduler/backfill_grid.dart';
import 'package:cocoon_service/src/service/luci_build_service/opaque_commit.dart';
import 'package:test/expect.dart';

const isBackfillTask = BackfillTaskMatcher._(TypeMatcher());

final class BackfillTaskMatcher extends Matcher {
  const BackfillTaskMatcher._(this._delegate);
  final TypeMatcher<BackfillTask> _delegate;

  BackfillTaskMatcher hasTask(Object matcherOr) {
    return BackfillTaskMatcher._(
      _delegate.having((t) => t.task, 'task', matcherOr),
    );
  }

  BackfillTaskMatcher hasTarget(Object matcherOr) {
    return BackfillTaskMatcher._(
      _delegate.having((t) => t.target, 'target', matcherOr),
    );
  }

  BackfillTaskMatcher hasCommit(Object matcherOr) {
    return BackfillTaskMatcher._(
      _delegate.having((t) => t.commit, 'commit', matcherOr),
    );
  }

  BackfillTaskMatcher hasPriority(Object matcherOr) {
    return BackfillTaskMatcher._(
      _delegate.having((t) => t.priority, 'priority', matcherOr),
    );
  }

  @override
  bool matches(Object? item, _) {
    if (item is! BackfillTask) {
      return false;
    }

    return _delegate.matches(item, {});
  }

  @override
  Description describe(Description description) {
    return _delegate.describe(description);
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    _,
    _,
  ) {
    return _delegate.describeMismatch(item, mismatchDescription, {}, false);
  }
}

const isOpaqueCommit = OpaqueCommitMatcher._(TypeMatcher());

final class OpaqueCommitMatcher extends Matcher {
  const OpaqueCommitMatcher._(this._delegate);
  final TypeMatcher<OpaqueCommit> _delegate;

  OpaqueCommitMatcher hasSha(Object matcherOr) {
    return OpaqueCommitMatcher._(
      _delegate.having((c) => c.sha, 'sha', matcherOr),
    );
  }

  OpaqueCommitMatcher hasBranch(Object matcherOr) {
    return OpaqueCommitMatcher._(
      _delegate.having((c) => c.branch, 'branch', matcherOr),
    );
  }

  OpaqueCommitMatcher hasSlug(Object matcherOr) {
    return OpaqueCommitMatcher._(
      _delegate.having((c) => c.slug, 'slug', matcherOr),
    );
  }

  @override
  bool matches(Object? item, _) {
    if (item is! OpaqueCommit) {
      return false;
    }

    return _delegate.matches(item, {});
  }

  @override
  Description describe(Description description) {
    return _delegate.describe(description);
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    _,
    _,
  ) {
    return _delegate.describeMismatch(item, mismatchDescription, {}, false);
  }
}

const isOpaqueTask = OpaqueTaskMatcher._(TypeMatcher());

final class OpaqueTaskMatcher extends Matcher {
  const OpaqueTaskMatcher._(this._delegate);
  final TypeMatcher<OpaqueTask> _delegate;

  OpaqueTaskMatcher hasName(Object matcherOr) {
    return OpaqueTaskMatcher._(
      _delegate.having((t) => t.name, 'name', matcherOr),
    );
  }

  OpaqueTaskMatcher hasCommitSha(Object matcherOr) {
    return OpaqueTaskMatcher._(
      _delegate.having((t) => t.commitSha, 'commitSha', matcherOr),
    );
  }

  OpaqueTaskMatcher hasCurrentAttempt(Object matcherOr) {
    return OpaqueTaskMatcher._(
      _delegate.having((t) => t.currentAttempt, 'currentAttempt', matcherOr),
    );
  }

  OpaqueTaskMatcher hasStatus(Object matcherOr) {
    return OpaqueTaskMatcher._(
      _delegate.having((t) => t.status, 'status', matcherOr),
    );
  }

  @override
  bool matches(Object? item, _) {
    if (item is! OpaqueTask) {
      return false;
    }

    return _delegate.matches(item, {});
  }

  @override
  Description describe(Description description) {
    return _delegate.describe(description);
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    _,
    _,
  ) {
    return _delegate.describeMismatch(item, mismatchDescription, {}, false);
  }
}
