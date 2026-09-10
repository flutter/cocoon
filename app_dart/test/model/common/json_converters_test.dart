// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/src/model/common/json_converters.dart';
import 'package:github/github.dart';
import 'package:test/test.dart';

void main() {
  useTestLoggerPerTest();

  group('SafeCheckSuiteConverter', () {
    const converter = SafeCheckSuiteConverter();

    test(
      'parses check_suite with startup_failure to CheckRunConclusion.failure',
      () {
        final json = <String, dynamic>{
          'id': 5678,
          'head_branch': 'main',
          'head_sha': 'abc123',
          'conclusion': 'startup_failure',
          'pull_requests': <dynamic>[],
        };

        final suite = converter.fromJson(json);
        expect(suite, isNotNull);
        expect(suite!.id, 5678);
        expect(suite.headBranch, 'main');
        expect(suite.headSha, 'abc123');
        expect(suite.conclusion, CheckRunConclusion.failure);
      },
    );

    test('returns null for null json', () {
      expect(converter.fromJson(null), isNull);
    });

    test('serializes CheckSuite to map', () {
      const suite = CheckSuite(
        id: 5678,
        headBranch: 'main',
        headSha: 'abc123',
        conclusion: CheckRunConclusion.failure,
        pullRequests: [],
      );

      final map = converter.toJson(suite);
      expect(map, isNotNull);
      expect(map!['id'], 5678);
      expect(map['head_branch'], 'main');
      expect(map['head_sha'], 'abc123');
      expect(map['conclusion'], 'failure');
      expect(map['pull_requests'], isEmpty);
      expect(converter.toJson(null), isNull);
    });
  });

  group('Base64Converter', () {
    const converter = Base64Converter();

    test('encodes and decodes base64 string', () {
      expect(converter.toJson('hello world'), 'aGVsbG8gd29ybGQ=');
      expect(converter.fromJson('aGVsbG8gd29ybGQ='), 'hello world');
    });
  });

  group('SecondsSinceEpochConverter', () {
    const converter = SecondsSinceEpochConverter();

    test('converts int and string epoch seconds to DateTime', () {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(1600000000000);
      expect(converter.fromJson(1600000000), dateTime);
      expect(converter.fromJson('1600000000'), dateTime);
      expect(converter.fromJson(null), isNull);
    });

    test('converts DateTime to epoch seconds string', () {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(1600000000000);
      expect(converter.toJson(dateTime), '1600000000');
      expect(converter.toJson(null), isNull);
    });
  });

  group('BoolConverter', () {
    const converter = BoolConverter();

    test('converts bool and string to bool', () {
      expect(converter.fromJson(true), isTrue);
      expect(converter.fromJson(false), isFalse);
      expect(converter.fromJson('true'), isTrue);
      expect(converter.fromJson('TRUE'), isTrue);
      expect(converter.fromJson('false'), isFalse);
      expect(converter.fromJson(null), isNull);
    });

    test('converts bool to string', () {
      expect(converter.toJson(true), 'true');
      expect(converter.toJson(false), 'false');
      expect(converter.toJson(null), isNull);
    });
  });

  group('GerritDateTimeConverter', () {
    const converter = GerritDateTimeConverter();

    test('parses ISO8601 format', () {
      final date = DateTime.parse('2023-06-07T22:54:06.000Z');
      expect(converter.fromJson('2023-06-07T22:54:06.000Z'), date);
    });

    test('parses Gerrit custom format', () {
      final date = converter.fromJson('Wed Jun 07 22:54:06 2023 +0000');
      expect(date, DateTime(2023, 6, 7, 22, 54, 6));
    });

    test('serializes DateTime to ISO8601', () {
      final date = DateTime.utc(2023, 6, 7, 22, 54, 6);
      expect(converter.toJson(date), '2023-06-07T22:54:06.000Z');
      expect(converter.toJson(null), isNull);
    });
  });
}
