// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:matcher/matcher.dart';

/// Returns a matcher that matches a severity of at _least_ [severity].
///
/// `atLeastSeverity(Severity.warning)` would match [Severity.warning] and
/// [Severity.error], but not [Severity.info].
///
/// The inverse of this matcher is [atMostSeverity].
///
/// See also:
/// - [atLeastInfo]
/// - [atLeastNotice]
/// - [atLeastWarning]
/// - [atLeastError]
Matcher atLeastSeverity(Severity severity) {
  return _CompareSeverity(severity, compareAtLeast: true);
}

/// An alias for `atLeastSeverity(Severity.info)`.
final atLeastInfo = atLeastSeverity(Severity.info);

/// An alias for `atLeastSeverity(Severity.notice)`.
final atLeastNotice = atLeastSeverity(Severity.notice);

/// An alias for `atLeastSeverity(Severity.warning)`.
final atLeastWarning = atLeastSeverity(Severity.warning);

/// An alias for `atLeastSeverity(Severity.error)`.
final atLeastError = atLeastSeverity(Severity.error);

/// Returns a matcher that matches a severity of at _most_ [severity].
///
/// `atLeastSeverity(Severity.warning)` would match [Severity.warning] and
/// [Severity.info], but not [Severity.error].
///
/// The inverse of this matcher is [atLeastSeverity].
///
/// See also:
/// - [atMostInfo]
/// - [atMostNotice]
/// - [atMostWarning]
/// - [atMostError]
Matcher atMostSeverity(Severity severity) {
  return _CompareSeverity(severity, compareAtLeast: false);
}

/// An alias for `atMostSeverity(Severity.info)`.
final atMostInfo = atMostSeverity(Severity.info);

/// An alias for `atMostSeverity(Severity.notice)`.
final atMostNotice = atMostSeverity(Severity.notice);

/// An alias for `atMostSeverity(Severity.warning)`.
final atMostWarning = atMostSeverity(Severity.warning);

/// An alias for `atMostSeverity(Severity.error)`.
final atMostError = atMostSeverity(Severity.error);

final class _CompareSeverity extends Matcher {
  _CompareSeverity(this._baseline, {required bool compareAtLeast})
    : _compareAtLeast = compareAtLeast;

  final Severity _baseline;
  final bool _compareAtLeast;

  @override
  Description describe(Description description) {
    return description
        .add(_compareAtLeast ? '>=' : '<=')
        .add(' ')
        .add(_baseline.name);
  }

  @override
  bool matches(Object? item, _) {
    if (item is! Severity) {
      return false;
    }
    return switch (_baseline.compareTo(item)) {
      > 0 => _compareAtLeast,
      < 0 => !_compareAtLeast,
      _ => true,
    };
  }
}
