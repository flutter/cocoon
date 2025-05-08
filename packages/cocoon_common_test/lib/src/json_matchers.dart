// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:cocoon_common/core_extensions.dart';
import 'package:matcher/matcher.dart';

/// Returns a matcher that checks a type that can be decoded to a JSON value.
///
/// The following types are supported as the _actual_ object:
/// - `String`
/// - `List<int>`
Matcher decodedAsJson(Object? matcher) {
  return _SyncJsonMatcher(wrapMatcher(matcher));
}

final class _SyncJsonMatcher extends Matcher {
  const _SyncJsonMatcher(this._matcher);
  final Matcher _matcher;

  @override
  bool matches(Object? item, Map matchState) {
    final Object? json = switch (item) {
      String() => jsonDecode(item),
      List<int>() => const JsonUtf8Decoder().convert(item),
      _ => false,
    };
    matchState['_SyncJsonMatcher.decoded'] = json;
    return _matcher.matches(json, {});
  }

  @override
  Description describe(Description description) {
    return description
        .add('decoded as a JSON value matches ')
        .addDescriptionOf(_matcher);
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    final decoded = matchState['_SyncJsonMatcher.decoded'];
    return mismatchDescription
        .add('decoded object ')
        .addDescriptionOf(decoded)
        .add('did not match ')
        .addDescriptionOf(_matcher);
  }
}
