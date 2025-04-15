// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/ci_yaml/target.dart';
import 'package:test/test.dart';

const isTarget = TargetMatcher._(TypeMatcher());

final class TargetMatcher extends Matcher {
  const TargetMatcher._(this._delegate);
  final TypeMatcher<Target> _delegate;

  TargetMatcher hasName(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having((e) => e.name, 'name', valueOrMatcher),
    );
  }

  TargetMatcher hasSchedulerConfig(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having(
        (e) => e.schedulerConfig,
        'schedulerConfig',
        valueOrMatcher,
      ),
    );
  }

  TargetMatcher hasSlug(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having((e) => e.slug, 'slug', valueOrMatcher),
    );
  }

  TargetMatcher hasDimensions(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having(
        (e) => e.getDimensions(),
        'getDimensions()',
        valueOrMatcher,
      ),
    );
  }

  TargetMatcher hasSchedulerPolicy(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having(
        (e) => e.schedulerPolicy,
        'schedulerPolicy',
        valueOrMatcher,
      ),
    );
  }

  TargetMatcher hasTags(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having((e) => e.tags, 'tags', valueOrMatcher),
    );
  }

  TargetMatcher hasProperties(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having(
        (e) => e.getProperties(),
        'getProperties()',
        valueOrMatcher,
      ),
    );
  }

  TargetMatcher hasPlatform(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having((e) => e.getPlatform(), 'getPlatform()', valueOrMatcher),
    );
  }

  TargetMatcher hasBucket(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having((e) => e.getBucket(), 'getBucket()', valueOrMatcher),
    );
  }

  TargetMatcher hasIgnoreFlakiness(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having(
        (e) => e.getIgnoreFlakiness(),
        'getIgnoreFlakiness()',
        valueOrMatcher,
      ),
    );
  }

  TargetMatcher hasIsReleaseBuildTarget(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having(
        (e) => e.isReleaseBuild,
        'isReleaseBuildTarget',
        valueOrMatcher,
      ),
    );
  }

  TargetMatcher hasIsBringupTarget(Object? valueOrMatcher) {
    return TargetMatcher._(
      _delegate.having((e) => e.isBringup, 'isBringupTarget', valueOrMatcher),
    );
  }

  @override
  bool matches(Object? item, _) {
    if (item is! Target) {
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
