// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;

import 'package:cocoon_server_test/test_logging.dart';
import 'package:cocoon_service/cocoon_service.dart';
import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

import '../src/fake_config.dart';
import '../src/request_handling/request_handler_tester.dart';

void main() {
  useTestLoggerPerTest();

  group('StaticFileHandler', () {
    late RequestHandlerTester tester;
    late FileSystem fs;

    final config = FakeConfig();

    const indexFileName = 'index.html';
    const indexFileContent = 'some html';
    const dartMapFileName = 'main.dart.js.map';
    const assetManifestSmcbin = 'AssetManifest.smcbin';

    setUp(() {
      tester = RequestHandlerTester();
      fs = MemoryFileSystem();
      fs.file('build/web/$indexFileName').createSync(recursive: true);
      fs.file('build/web/$indexFileName').writeAsStringSync(indexFileContent);
      fs
          .file('build/web/$assetManifestSmcbin')
          .writeAsStringSync(assetManifestSmcbin);
      fs.file('build/web/$dartMapFileName').writeAsStringSync('[{}]');
    });

    Future<String> decodeHandlerBody(Body body) {
      return utf8.decoder.bind(body.serialize() as Stream<List<int>>).first;
    }

    test('returns 404 response when file does not exist', () async {
      final staticFileHandler = StaticFileHandler(
        'i do not exist as a file',
        config: config,
        fs: fs,
      );

      expect(
        tester.get(staticFileHandler),
        throwsA(const TypeMatcher<NotFoundException>()),
      );
    });

    test('returns body when file does exist', () async {
      final staticFileHandler = StaticFileHandler(
        '/$indexFileName',
        config: config,
        fs: fs,
      );

      final body = await tester.get(staticFileHandler);
      expect(body, isNotNull);
      final response = await decodeHandlerBody(body);
      expect(response, indexFileContent);
    });

    test('DartMap file does not raise exception', () async {
      final staticFileHandler = StaticFileHandler(
        '/$dartMapFileName',
        config: config,
        fs: fs,
      );

      final body = await tester.get(staticFileHandler);
      expect(body, isNotNull);
      final response = await decodeHandlerBody(body);
      expect(response, '[{}]');
    });

    test('smcbin file extension is handled correctly', () async {
      final staticFileHandler = StaticFileHandler(
        '/$assetManifestSmcbin',
        config: config,
        fs: fs,
      );

      final body = await tester.get(staticFileHandler);
      expect(body, isNotNull);
      final response = await decodeHandlerBody(body);
      expect(response, assetManifestSmcbin);
    });

    test('No extension files default to plain text', () async {
      fs.file('build/web/NOTICE').writeAsStringSync('abc');
      final staticFileHandler = StaticFileHandler(
        '/NOTICE',
        config: config,
        fs: fs,
      );

      final body = await tester.get(staticFileHandler);
      expect(body, isNotNull);
      final response = await decodeHandlerBody(body);
      expect(response, 'abc');
    });
  });
}
