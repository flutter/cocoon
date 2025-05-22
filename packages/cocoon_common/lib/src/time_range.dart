// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// A definition of a time range, which can be specific or indefinite.
@immutable
sealed class TimeRange {
  const TimeRange();

  /// Matches any time.
  static const TimeRange indefinite = IndefiniteTimeRange();

  /// Creates a range matching time between [start] and [end].
  ///
  /// If [exclusive] is set, the specific moments described in [start] and [end]
  /// are excluded.
  ///
  /// [end] must be after [start].
  factory TimeRange.between(
    DateTime start, //
    DateTime end, {
    bool exclusive,
  }) = SpecificTimeRange.between;

  /// Creates a range matching time before [end].
  ///
  /// If [exclusive] is set, the specific moment described in [end] is excluded.
  factory TimeRange.before(
    DateTime end, { //
    bool exclusive,
  }) = SpecificTimeRange.before;

  /// Creates a range matching time after [start].
  ///
  /// If [exclusive] is set, the specific moment described in [start] is
  /// excluded.
  factory TimeRange.after(
    DateTime start, { //
    bool exclusive,
  }) = SpecificTimeRange.after;

  @override
  @nonVirtual
  bool operator ==(Object other) {
    return other is TimeRange && start == other.start && end == other.end;
  }

  @override
  @nonVirtual
  int get hashCode => Object.hash(start, end);

  /// A starting point in time.
  ///
  /// If `null`, the time range is infinite in the past.
  DateTime? get start;

  /// An ending point in time.
  ///
  /// If `null`, the time range is infinite in the future.
  DateTime? get end;

  /// Returns whether [time] is within `this` range.
  bool contains(DateTime time);

  @override
  String toString() {
    if (start == null && end == null) {
      return 'TimeRange.indefinite';
    }
    if (start == null) {
      return 'TimeRange.before($end)';
    }
    if (end == null) {
      return 'TimeRange.after($start)';
    }
    return 'TimeRange.between($start, $end)';
  }
}

/// No specific start or end time.
final class IndefiniteTimeRange extends TimeRange {
  @literal
  const IndefiniteTimeRange();

  @override
  Null get start => null;

  @override
  Null get end => null;

  @override
  bool contains(DateTime time) => true;
}

/// A specific time range, which includes at _least_ [start] or [end], or both.
final class SpecificTimeRange extends TimeRange {
  /// Creates a time range with a specific [end] time.
  ///
  /// If [exclusive] is set, the specific moment described in [end] is excluded.
  SpecificTimeRange.before(
    DateTime this.end, { //
    this.exclusive = false,
  }) : start = null;

  /// Creates a time range with a specific [start] time.
  ///
  /// If [exclusive] is set, the specific moment described in [start] is
  /// excluded.
  SpecificTimeRange.after(
    DateTime this.start, { //
    this.exclusive = false,
  }) : end = null;

  /// Creates a time range with a specific [start] and [end] time.
  ///
  /// If [exclusive] is set, the specific moment described in [start] and [end]
  /// are excluded.
  ///
  /// [start] must be before [end].
  SpecificTimeRange.between(
    DateTime this.start, //
    DateTime this.end, {
    this.exclusive = false,
  }) {
    if (start!.isAfter(end!)) {
      throw ArgumentError.value(
        start,
        'start',
        'Start time must be before end time.',
      );
    }
  }

  /// Whether [start], or [end], if specified, should exclude that instant.
  final bool exclusive;

  /// Whether [start], or [end], if specified, should include that instant.
  bool get inclusive => !exclusive;

  @override
  final DateTime? start;

  @override
  final DateTime? end;

  @override
  bool contains(DateTime time) {
    if (start case final start? when start.isAfter(time)) {
      return false;
    }
    if (end case final end? when end.isBefore(time)) {
      return false;
    }
    if (exclusive) {
      return time != start && time != end;
    }
    return true;
  }
}
