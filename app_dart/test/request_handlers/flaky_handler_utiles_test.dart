// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/request_handlers/flaky_handler_utils.dart';
import 'package:test/test.dart';

void main() {
  group('Gets test ownership', () {
    String testOwnersContent;

    group('framework host only', () {
      test('returns correct owner when no mulitple tests share the same file', () async {
        testOwnersContent = '''
## Host only framework tests
# Linux abc
abc_test.sh @ghi @flutter/jkl
## Firebase tests
''';
        final String owner = getTestOwnership('Linux abc', BuilderType.frameworkHostOnly, testOwnersContent).owner;
        expect(owner, 'ghi');
      });

      test('returns correct owner when mulitple tests share the same file', () async {
        testOwnersContent = '''
## Host only framework tests
# Linux abc
# Linu def
abc_test.sh @ghi @flutter/jkl
## Firebase tests
''';
        final String owner1 = getTestOwnership('Linux abc', BuilderType.frameworkHostOnly, testOwnersContent).owner;
        expect(owner1, 'ghi');
        final String owner2 = getTestOwnership('Linux def', BuilderType.frameworkHostOnly, testOwnersContent).owner;
        expect(owner2, 'ghi');
      });
    });

    group('firebaselab only', () {
      test('returns correct owner', () async {
        testOwnersContent = '''
## Firebase tests
# Linux abc
/test/abc @def @flutter/ghi
## Shards tests
''';
        final String owner = getTestOwnership('Linux firebase_abc', BuilderType.firebaselab, testOwnersContent).owner;
        expect(owner, 'def');
      });
    });

    group('devicelab tests', () {
      test('returns correct owner', () async {
        testOwnersContent = '''
## Linux Android DeviceLab tests
/dev/devicelab/bin/tasks/abc.dart @def @flutter/ghi

## Host only framework tests
''';
        final String owner = getTestOwnership('Linux abc', BuilderType.devicelab, testOwnersContent).owner;
        expect(owner, 'def');
      });
    });

    group('shards tests', () {
      test('returns correct owner', () async {
        testOwnersContent = '''
## Shards tests
#
# abc @def @flutter/ghi
''';
        final String owner = getTestOwnership('Linux abc', BuilderType.shard, testOwnersContent).owner;
        expect(owner, 'def');
      });
    });
  });
}
