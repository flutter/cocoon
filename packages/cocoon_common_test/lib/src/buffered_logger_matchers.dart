// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/cocoon_common.dart';
import 'package:matcher/matcher.dart';

import 'severity_matchers.dart';

/// Returns a matcher that asserts against the state of a [BufferedLogger].
///
/// Will typically be used in conjunction with matchers that operate on an
/// iterable or list, such as [equals] or [contains]. For example, to match
/// a logger that has exactly a specific message:
///
/// ```dart
/// // Has a single log message with a specific message:
/// bufferedLoggerOf(equals([
///   logThat(equals('A big bad thing happened!'))
/// ]))
/// ```
///
/// Or, to match against a logger that contains a matching message:
///
/// ```dart
/// // Has at least one log message containing the phrase 'DATABASE'
/// bufferedLoggerOf(contains(
///   logThat(contains('DATABASE'))
/// ))
/// ```
Matcher bufferedLoggerOf(Matcher that) => _BufferedLoggerOf(that);

final class _BufferedLoggerOf extends Matcher {
  const _BufferedLoggerOf(this._matcher);
  final Matcher _matcher;

  @override
  Description describe(Description description) {
    return description.add('buffered logger that ').addDescriptionOf(_matcher);
  }

  @override
  bool matches(Object? item, _) {
    if (item is! BufferedLogger) {
      return false;
    }
    return _matcher.matches(item.messages, {});
  }
}

/// A matcher asserting that no warnings (or higher) are in a [BufferedLogger].
final hasNoWarningsOrHigher = bufferedLoggerOf(contains(isNot(atLeastWarning)));

/// A matcher asserting that no errors (or higher) are in a [BufferedLogger].
final hasNoErrorsOrHigher = bufferedLoggerOf(contains(isNot(atLeastError)));

/// Returns a matcher that matches a recorded [LogRecord].
///
/// A [message] is required, which itself is a matcher:
/// ```dart
/// logThat(message: contains('BIG UPDATE'))
/// ```
///
/// Optionally, additional fields of the log can be matched against:
/// ```dart
/// logThat(
///   message: contains('BIG UPDATE'),
///   severity: equals(Severity.warning),
/// )
/// ```
Matcher logThat({
  required Matcher message,
  Matcher? severity,
  Matcher? error,
  Matcher? trace,
  Matcher? recordedAt,
}) {
  return _LogMatcher(message, severity, error, trace, recordedAt);
}

final class _LogMatcher extends Matcher {
  const _LogMatcher(
    this._message,
    this._severity,
    this._error,
    this._trace,
    this._recordedAt,
  );

  final Matcher _message;
  final Matcher? _severity;
  final Matcher? _error;
  final Matcher? _trace;
  final Matcher? _recordedAt;

  @override
  Description describe(Description description) {
    description = description.add('message is ').addDescriptionOf(_message);
    if (_severity case final severity?) {
      description = description
          .add(', severity is ')
          .addDescriptionOf(severity);
    }
    if (_error case final error?) {
      description = description.add(', error is ').addDescriptionOf(error);
    }
    if (_trace case final trace?) {
      description = description.add(', trace is ').addDescriptionOf(trace);
    }
    if (_recordedAt case final time?) {
      description = description.add(', recordedAt is ').addDescriptionOf(time);
    }
    return description;
  }

  @override
  bool matches(Object? item, _) {
    if (item is! LogRecord) {
      return false;
    }
    if (!_message.matches(item.message, {})) {
      return false;
    }
    if (_severity?.matches(item.severity, {}) == false) {
      return false;
    }
    if (_error?.matches(item.error, {}) == false) {
      return false;
    }
    if (_trace?.matches(item.trace, {}) == false) {
      return false;
    }
    if (_recordedAt?.matches(item.recordedAt, {}) == false) {
      return false;
    }
    return true;
  }
}
