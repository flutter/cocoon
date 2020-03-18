// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:platform/platform.dart' as platform;

import 'package:cocoon_agent/src/utils.dart';
import 'package:cocoon_agent/src/health.dart';

void main() {
  group('testRemoveXcodeDerivedData', () {
    MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
    });

    test('ignores non-macOS', () async {
      platform.FakePlatform pf = platform.FakePlatform()
        ..operatingSystem = "linux";

      HealthCheckResult result = await removeXcodeDerivedData(pf: pf, fs: fs);

      expect(result.succeeded, true);
    });

    test('fails when missing home env var', () async {
      platform.FakePlatform pf = platform.FakePlatform()
        ..operatingSystem = "macos"
        ..environment = <String, String>{"HOME": null};

      HealthCheckResult result = await removeXcodeDerivedData(pf: pf, fs: fs);

      expect(result.succeeded, false);
    });

    test('throws no excpetion when missing DerivedData', () async {
      platform.FakePlatform pf = platform.FakePlatform()
        ..operatingSystem = "macos"
        ..environment = <String, String>{"HOME": "/foo"};

      HealthCheckResult result = await removeXcodeDerivedData(pf: pf, fs: fs);

      expect(result.succeeded, true);
    });

    test('removes DerivedData directory', () async {
      platform.FakePlatform pf = platform.FakePlatform()
        ..operatingSystem = "macos"
        ..environment = <String, String>{"HOME": "/foo"};
      const String path = "/foo/Library/Developer/Xcode/DerivedData/bar";
      fs.file(path)..createSync(recursive: true);

      HealthCheckResult result = await removeXcodeDerivedData(pf: pf, fs: fs);

      expect(await fs.file(path).exists(), isFalse);
      expect(result.succeeded, true);
    });
  });

  group('testRemoveCachedData', () {
    MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
    });

    test('removes cache directories all exist', () async {
      platform.FakePlatform pf = platform.FakePlatform()
        ..operatingSystem = "macos"
        ..environment = <String, String>{"HOME": "/foo"};
      List<String> folders = <String>[
        '/foo/.graddle',
        '/foo/.dartServer',
        '/foo/.pub-cache'
      ];
      for (String dir in folders) {
        fs.directory(dir)..createSync(recursive: true);
      }
      HealthCheckResult result = await removeCachedData(pf: pf, fs: fs);
      for (String dir in folders) {
        expect(await fs.directory(dir).exists(), isFalse);
      }
      expect(result.succeeded, true);
    });

    test('removes cache directories not all exist', () async {
      platform.FakePlatform pf = platform.FakePlatform()
        ..operatingSystem = "macos"
        ..environment = <String, String>{"HOME": "/foo"};
      String dir = '/foo/.dartServer';
      fs.directory(dir)..createSync(recursive: true);
      HealthCheckResult result = await removeCachedData(pf: pf, fs: fs);
      expect(await fs.directory(dir).exists(), isFalse);
      expect(result.succeeded, true);
    });
  });
}
