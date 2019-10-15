// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;
import 'dart:io';

import 'package:cocoon_service/cocoon_service.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:cocoon_service/src/request_handling/body.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';

import '../src/datastore/fake_cocoon_config.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  group('StaticFileHandler', () {
    RequestHandlerTester tester;
    FileSystem fs;

    final FakeConfig config = FakeConfig();

    const String indexFileName = 'index.html';
    const String indexFileContent = 'some html';

    setUp(() {
      tester = RequestHandlerTester();
      fs = MemoryFileSystem();
      fs.file('build/web/$indexFileName').createSync(recursive: true);
      fs.file('build/web/$indexFileName').writeAsString(indexFileContent);
    });

    Future<String> _decodeHandlerBody(Body body) {
      return utf8.decoder.bind(body.serialize()).first;
    }

    test('returns 404 response when file does not exist', () async {
      final StaticFileHandler<Body> staticFileHandler =
          StaticFileHandler<Body>('i do not exist as a file', config: config, fs: fs);

      expect(tester.get(staticFileHandler),
          throwsA(const TypeMatcher<NotFoundException>()));
    });

    test('returns body when file does exist', () async {
      final StaticFileHandler<Body> staticFileHandler =
          StaticFileHandler<Body>('/$indexFileName', config: config, fs: fs);

      final Body body = await tester.get(staticFileHandler);
      expect(body, isNotNull);
      final String response = await _decodeHandlerBody(body);
      expect(response, indexFileContent);
    });
  });
}

class MockHttpRequest extends Mock implements HttpRequest {}
