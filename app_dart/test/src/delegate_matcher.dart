// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:test/test.dart';

abstract base class DelegateMatcher<T> extends Matcher {
  const DelegateMatcher(this._delegate);
  final TypeMatcher<T> _delegate;

  @protected
  TypeMatcher<T> having(
    Object? Function(T) feature,
    String description,
    Object? matcher,
  ) {
    return _delegate.having(feature, description, matcher);
  }

  @override
  bool matches(Object? item, _) {
    if (item is! T) {
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
