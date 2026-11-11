// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_models.dart';
import 'package:cocoon_service/src/service/want_lgtm/want_lgtm_parser.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('parseWantLgtmDirective', () {
    test('returns NoWantLgtmDirective on null or empty body', () {
      expect(
        parseWantLgtmDirective(null, authorLogin: 'author'),
        const NoWantLgtmDirective(),
      );
      expect(
        parseWantLgtmDirective('', authorLogin: 'author'),
        const NoWantLgtmDirective(),
      );
      expect(
        parseWantLgtmDirective('   \n  \t  ', authorLogin: 'author'),
        const NoWantLgtmDirective(),
      );
    });

    test('returns NoWantLgtmDirective when no directive is present', () {
      const body = '''
## Description
Fixes https://github.com/flutter/flutter/issues/12345.
This PR updates the engine build configuration.
''';
      expect(
        parseWantLgtmDirective(body, authorLogin: 'author'),
        const NoWantLgtmDirective(),
      );
    });

    test('requires WANT_LGTM= to start at column 0 of a line', () {
      const nonStartOfLine = '''
  WANT_LGTM=indented
> WANT_LGTM=quoted
<!-- WANT_LGTM=inline-comment -->
See WANT_LGTM=prose for details.
''';
      expect(
        parseWantLgtmDirective(nonStartOfLine, authorLogin: 'author'),
        const NoWantLgtmDirective(),
      );

      const inCodeBlockAtStartOfLine = '''
```text
WANT_LGTM=alice
```
''';
      expect(
        parseWantLgtmDirective(inCodeBlockAtStartOfLine, authorLogin: 'author'),
        const ValidWantLgtmDirective(
          requiresAll: false,
          explicitLogins: ['alice'],
        ),
      );
    });

    test(
      'parses explicit usernames (including single internal hyphens) and strips @',
      () {
        const body = 'WANT_LGTM=@alice, bob-2, @Carol-Dev';
        final directive = parseWantLgtmDirective(body, authorLogin: 'author');

        expect(
          directive,
          const ValidWantLgtmDirective(
            requiresAll: false,
            explicitLogins: ['alice', 'bob-2', 'carol-dev'],
          ),
        );
      },
    );

    test('handles CRLF line endings cleanly', () {
      const body = 'Fixes bug\r\nWANT_LGTM=alice\r\nMore details\r\n';
      final directive = parseWantLgtmDirective(body, authorLogin: 'author');

      expect(
        directive,
        const ValidWantLgtmDirective(
          requiresAll: false,
          explicitLogins: ['alice'],
        ),
      );
    });

    test(
      'treats "all" and "@all" as the special requiresAll keyword, never a user',
      () {
        const bodyAll = 'WANT_LGTM=all';
        expect(
          parseWantLgtmDirective(bodyAll, authorLogin: 'author'),
          const ValidWantLgtmDirective(requiresAll: true, explicitLogins: []),
        );

        const bodyAtAll = 'WANT_LGTM=@all';
        expect(
          parseWantLgtmDirective(bodyAtAll, authorLogin: 'author'),
          const ValidWantLgtmDirective(requiresAll: true, explicitLogins: []),
        );

        const bodyCombined = 'WANT_LGTM=all, @all, @ALL, bob';
        expect(
          parseWantLgtmDirective(bodyCombined, authorLogin: 'author'),
          const ValidWantLgtmDirective(
            requiresAll: true,
            explicitLogins: ['bob'],
          ),
        );
      },
    );

    test('merges multiple WANT_LGTM lines and deduplicates logins', () {
      const body = '''
WANT_LGTM=alice, Bob
want_lgtm = BOB, carol
WANT_LGTM=all
''';
      final directive = parseWantLgtmDirective(body, authorLogin: 'author');

      expect(
        directive,
        const ValidWantLgtmDirective(
          requiresAll: true,
          explicitLogins: ['alice', 'bob', 'carol'],
        ),
      );
    });

    test('automatically excludes the PR author', () {
      const body = 'WANT_LGTM=alice, author, bob';
      final directive = parseWantLgtmDirective(body, authorLogin: 'AUTHOR');

      expect(
        directive,
        const ValidWantLgtmDirective(
          requiresAll: false,
          explicitLogins: ['alice', 'bob'],
        ),
      );
    });

    test('ignores self-only and blank directives as NoWantLgtmDirective', () {
      const bodyAuthor = 'WANT_LGTM=author';
      expect(
        parseWantLgtmDirective(bodyAuthor, authorLogin: 'author'),
        const NoWantLgtmDirective(),
      );

      const bodyBlank = 'WANT_LGTM=   ';
      expect(
        parseWantLgtmDirective(bodyBlank, authorLogin: 'author'),
        const NoWantLgtmDirective(),
      );
    });

    test(
      'rejects team handles, underscores, bad hyphens, and malformed tokens',
      () {
        const body =
            'WANT_LGTM=alice, @flutter/engine, bad_underscore, -leading, trailing-, two--hyphens, bad*token';
        final directive = parseWantLgtmDirective(body, authorLogin: 'author');

        expect(
          directive,
          const InvalidWantLgtmDirective(
            invalidTokens: [
              '@flutter/engine',
              'bad_underscore',
              '-leading',
              'trailing-',
              'two--hyphens',
              'bad*token',
            ],
          ),
        );
      },
    );

    test('rejects tokens exceeding 39 characters', () {
      final valid39 = 'a' * 39;
      final invalid40 = 'a' * 40;

      final directiveValid = parseWantLgtmDirective(
        'WANT_LGTM=$valid39',
        authorLogin: 'author',
      );
      expect(directiveValid, isA<ValidWantLgtmDirective>());

      final directiveInvalid = parseWantLgtmDirective(
        'WANT_LGTM=$invalid40',
        authorLogin: 'author',
      );
      expect(
        directiveInvalid,
        InvalidWantLgtmDirective(invalidTokens: [invalid40]),
      );
    });
  });
}
