// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:github/github.dart';
import 'package:test/test.dart';

const isTarget = CheckRunMatcher._(TypeMatcher());

final class CheckRunMatcher extends Matcher {
  const CheckRunMatcher._(this._delegate);
  final TypeMatcher<CheckRun> _delegate;

  CheckRunMatcher hasId(Object? valueOrMatcher) {
    return CheckRunMatcher._(
      _delegate.having((e) => e.id, 'id', valueOrMatcher),
    );
  }

  CheckRunMatcher hasName(Object? valueOrMatcher) {
    return CheckRunMatcher._(
      _delegate.having((e) => e.name, 'name', valueOrMatcher),
    );
  }

  @override
  bool matches(Object? item, _) {
    if (item is! CheckRun) {
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
