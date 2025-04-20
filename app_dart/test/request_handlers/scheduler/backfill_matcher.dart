// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handlers/scheduler/backfill_grid.dart';
import 'package:cocoon_service/src/service/luci_build_service/commit_task_ref.dart';
import 'package:test/expect.dart';

import '../../src/model/ci_yaml_matcher.dart';

/// Returns a matcher that asserts the state of [BackfillGrid.targets].
Matcher hasGridTargetsMatching(
  Iterable<(TargetMatcher, List<OpaqueTaskMatcher>)> targets,
) {
  return _BackfillGridMatcher([...targets]);
}

// The default Dart matchers do not handle tuples well, so this matcher does
// roughly what you'd want to do when comparing the shape of BackfillGrid to
// an expected output.
final class _BackfillGridMatcher extends Matcher {
  const _BackfillGridMatcher(this._expected);
  final List<(TargetMatcher, List<OpaqueTaskMatcher>)> _expected;

  @override
  Description describe(Description description) {
    return description
        .add('matches the grid shape ')
        .addDescriptionOf(_expected);
  }

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! BackfillGrid) {
      return false;
    }
    final actual = item.targets.toList();
    if (actual.length != _expected.length) {
      return false;
    }
    var i = 0;
    for (final (actualTarget, actualTasks) in item.targets) {
      final (expectedTarget, expectedTasks) = _expected[i];
      if (!expectedTarget.matches(actualTarget, {})) {
        return false;
      }
      if (actualTasks.length != expectedTasks.length) {
        return false;
      }
      for (var n = 0; n < actualTasks.length; n++) {
        if (!expectedTasks[n].matches(actualTasks[n], {})) {
          return false;
        }
      }
      i++;
    }
    return true;
  }
}

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
  bool matches(Object? item, Map matchState) {
    if (item is! BackfillTask) {
      return false;
    }

    return _delegate.matches(item, matchState);
  }

  @override
  Description describe(Description description) {
    return _delegate.describe(description);
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    _,
  ) {
    return _delegate.describeMismatch(
      item,
      mismatchDescription,
      matchState,
      false,
    );
  }
}

const isOpaqueCommit = OpaqueCommitMatcher._(TypeMatcher());

final class OpaqueCommitMatcher extends Matcher {
  const OpaqueCommitMatcher._(this._delegate);
  final TypeMatcher<CommitRef> _delegate;

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
    if (item is! CommitRef) {
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
  final TypeMatcher<TaskRef> _delegate;

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
    if (item is! TaskRef) {
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
