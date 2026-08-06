// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/cocoon_service.dart';
import 'package:test/test.dart';

void main() {
  group('TestSuppression.canonicalizeIssueUrl', () {
    test('canonicalizes standard GitHub issue URLs', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('strips trailing slashes', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740/',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740///',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('strips fragment anchors (e.g. comment links)', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740#issuecomment-1234567',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('strips query parameters', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740?param=1&q=search',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('strips rest path segments (e.g. comments subpath)', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740/comments',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740/comments/123/',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('handles combined trailing slashes, queries, and fragments', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/188740/comments/?param=1#frag',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('trims surrounding whitespace', () {
      expect(
        TestSuppression.canonicalizeIssueUrl(
          '   https://github.com/flutter/flutter/issues/188740   ',
        ),
        'https://github.com/flutter/flutter/issues/188740',
      );
    });

    test('returns null for non-GitHub URLs or non-issue links', () {
      expect(
        TestSuppression.canonicalizeIssueUrl('https://example.com/foo/bar/'),
        isNull,
      );
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/pull/123/',
        ),
        isNull,
      );
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter',
        ),
        isNull,
      );
      expect(
        TestSuppression.canonicalizeIssueUrl(
          'https://github.com/flutter/flutter/issues/notanumber',
        ),
        isNull,
      );
      expect(TestSuppression.canonicalizeIssueUrl('   '), isNull);
    });
  });
}
