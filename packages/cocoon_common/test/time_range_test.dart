// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/core_extensions.dart';
import 'package:test/test.dart';

void main() {
  group('TimeRange.indefinite', () {
    test('omits start and end', () {
      expect(
        TimeRange.indefinite,
        isA<IndefiniteTimeRange>()
            .having((r) => r.start, 'start', isNull)
            .having((r) => r.end, 'end', isNull),
      );
    });

    test('matches any date', () {
      final now = DateTime.now();
      for (var i = -365; i < 365; i++) {
        final date = now.add(Duration(days: i));
        expect(
          TimeRange.indefinite.contains(date),
          isTrue,
          reason: 'Expected $date to be contained in indefinite range',
        );
      }
    });
  });

  group('TimeRange.between', () {
    test('matches specific date', () {
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2020, 1, 2);
      final range = TimeRange.between(start, end);

      expect(range.start, start);
      expect(range.end, end);

      expect(range.contains(start), isTrue);
      expect(range.contains(end), isTrue);
    });

    test('does not match specific date (exclusive)', () {
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2020, 1, 2);
      final range = TimeRange.between(start, end, exclusive: true);

      expect(range.start, start);
      expect(range.end, end);

      expect(range.contains(start), isFalse);
      expect(range.contains(end), isFalse);
    });

    test('does not match date outside range', () {
      final start = DateTime(2020, 1, 1);
      final end = DateTime(2020, 1, 2);
      final range = TimeRange.between(start, end);

      expect(range.contains(start.subtract(const Duration(days: 1))), isFalse);
      expect(range.contains(end.add(const Duration(days: 1))), isFalse);
    });
  });

  group('TimeRange.before', () {
    test('matches specific date', () {
      final end = DateTime(2020, 1, 1);
      final range = TimeRange.before(end);

      expect(range.end, end);
      expect(range.start, isNull);

      expect(range.contains(end), isTrue);
    });

    test('does not match specific date (exclusive)', () {
      final end = DateTime(2020, 1, 1);
      final range = TimeRange.before(end, exclusive: true);

      expect(range.end, end);
      expect(range.start, isNull);

      expect(range.contains(end), isFalse);
    });

    test('does not match date after range', () {
      final end = DateTime(2020, 1, 1);
      final range = TimeRange.before(end);

      expect(range.contains(end.add(const Duration(days: 1))), isFalse);
    });
  });

  group('TimeRange.after', () {
    test('matches specific date', () {
      final start = DateTime(2020, 1, 1);
      final range = TimeRange.after(start);

      expect(range.start, start);
      expect(range.end, isNull);

      expect(range.contains(start), isTrue);
    });

    test('does not match specific date (exclusive)', () {
      final start = DateTime(2020, 1, 1);
      final range = TimeRange.after(start, exclusive: true);

      expect(range.start, start);
      expect(range.end, isNull);

      expect(range.contains(start), isFalse);
    });

    test('does not match date before range', () {
      final start = DateTime(2020, 1, 1);
      final range = TimeRange.after(start);

      expect(range.contains(start.subtract(const Duration(days: 1))), isFalse);
    });

    test('matches date after range', () {
      final start = DateTime(2020, 1, 1);
      final range = TimeRange.after(start);

      expect(range.contains(start.add(const Duration(days: 1))), isTrue);
    });
  });
}
