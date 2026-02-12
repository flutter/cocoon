// Copyright 2025 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('SuppressedTest', () {
    test('creates from document correctly', () {
      final doc = Document(
        name:
            'projects/flutter-dashboard/databases/cocoon/documents/suppressed_tests/test_doc_id',
        fields: {
          'name': 'my_test'.toValue(),
          'repository': 'flutter/flutter'.toValue(),
          'issueLink': 'https://github.com/flutter/flutter/issues/123'
              .toValue(),
          'isSuppressed': true.toValue(),
          'createTimestamp': DateTime.fromMillisecondsSinceEpoch(
            1234567890,
          ).toValue(),
          'updates': [
            {
              'user': 'user@example.com',
              'updateTimestamp': DateTime.fromMillisecondsSinceEpoch(
                1234567890,
              ),
              'note': 'suppressed',
              'action': 'SUPPRESS',
            },
          ].toValue(),
        },
      );

      final suppressedTest = SuppressedTest.fromDocument(doc);
      expect(suppressedTest.testName, 'my_test');
      expect(suppressedTest.repository, 'flutter/flutter');
      expect(
        suppressedTest.issueLink,
        'https://github.com/flutter/flutter/issues/123',
      );
      expect(suppressedTest.isSuppressed, true);
      expect(suppressedTest.createTimestamp.millisecondsSinceEpoch, 1234567890);
      expect(suppressedTest.updates, hasLength(1));
      final update = suppressedTest.updates.first;
      expect(update['user'], 'user@example.com');
      expect(update['note'], 'suppressed');
      expect(update['action'], 'SUPPRESS');
      expect(
        update['updateTimestamp'],
        DateTime.fromMillisecondsSinceEpoch(1234567890, isUtc: true),
      );
    });
  });
}
