// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;

import 'package:cocoon_service/cocoon_service.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';

import '../src/datastore/fake_config.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('StaticFileHandler', () {
    RequestHandlerTester tester;
    FileSystem fs;

    final FakeConfig config = FakeConfig();

    const String indexFileName = 'index.html';
    const String indexFileContent = 'some html';
    const String dartMapFileName = 'main.dart.js.map';

    setUp(() {
      tester = RequestHandlerTester();
      fs = MemoryFileSystem();
      fs.file('build/web/$indexFileName').createSync(recursive: true);
      fs.file('build/web/$indexFileName').writeAsStringSync(indexFileContent);
      fs.file('build/web/$dartMapFileName').writeAsStringSync('[{}]');
    });

    Future<String> _decodeHandlerBody(Body body) {
      return utf8.decoder.bind(body.serialize()).first;
    }

    test('returns 404 response when file does not exist', () async {
      final StaticFileHandler staticFileHandler = StaticFileHandler('i do not exist as a file', config: config, fs: fs);

      expect(tester.get(staticFileHandler), throwsA(const TypeMatcher<NotFoundException>()));
    });

    test('returns body when file does exist', () async {
      final StaticFileHandler staticFileHandler = StaticFileHandler('/$indexFileName', config: config, fs: fs);

      final Body body = await tester.get(staticFileHandler);
      expect(body, isNotNull);
      final String response = await _decodeHandlerBody(body);
      expect(response, indexFileContent);
    });

    test('DartMap file does not raise exception', () async {
      final StaticFileHandler staticFileHandler = StaticFileHandler('/$dartMapFileName', config: config, fs: fs);

      final Body body = await tester.get(staticFileHandler);
      expect(body, isNotNull);
      final String response = await _decodeHandlerBody(body);
      expect(response, '[{}]');
    });

    test('No extension files default to plain text', () async {
      fs.file('build/web/NOTICE').writeAsStringSync('abc');
      final StaticFileHandler staticFileHandler = StaticFileHandler('/NOTICE', config: config, fs: fs);

      final Body body = await tester.get(staticFileHandler);
      expect(body, isNotNull);
      final String response = await _decodeHandlerBody(body);
      expect(response, 'abc');
    });
  });
}
