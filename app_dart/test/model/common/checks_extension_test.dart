// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_common/task_status.dart';
import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/common/checks_extension.dart';
import 'package:cocoon_service/src/model/firestore/ci_staging.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('ChecksExtension', () {
    test('toTaskConclusion mapping for neutral', () {
      expect(TaskStatus.neutral.toTaskConclusion(), TaskConclusion.neutral);
    });

    test('toConclusion mapping for neutral', () {
      expect(TaskStatus.neutral.toConclusion(), 'neutral');
    });

    test('toCheckRunConclusion mapping for neutral', () {
      expect(
        TaskStatus.neutral.toCheckRunConclusion(),
        CheckRunConclusion.neutral,
      );
    });

    test('fromConclusion mapping for neutral', () {
      expect(ChecksExtension.fromConclusion('neutral'), TaskStatus.neutral);
    });

    test('fromCheckRunConclusion mapping for neutral', () {
      expect(
        ChecksExtension.fromCheckRunConclusion(CheckRunConclusion.neutral),
        TaskStatus.neutral,
      );
    });
  });

  group('TaskConclusion', () {
    test('isSuccess returns true for neutral', () {
      expect(TaskConclusion.neutral.isSuccess, isTrue);
    });

    test('isFailure returns false for neutral', () {
      expect(TaskConclusion.neutral.isFailure, isFalse);
    });

    test('isComplete returns true for neutral', () {
      expect(TaskConclusion.neutral.isComplete, isTrue);
    });
  });
}
