// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:file/memory.dart';
import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart' as platform;
import 'package:process/process.dart';
import 'package:test/test.dart';

import 'package:device_doctor/src/device.dart';
import 'package:device_doctor/src/health.dart';
import 'package:device_doctor/src/ios_device.dart';
import 'package:device_doctor/src/utils.dart';

void main() {
  group('testRemoveXcodeDerivedData', () {
    MemoryFileSystem fs;

    setUp(() {
      fs = MemoryFileSystem();
    });

    test('ignores non-macOS', () async {
      platform.FakePlatform pf = platform.FakePlatform()..operatingSystem = "linux";

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
      List<String> folders = <String>['/foo/.gradle', '/foo/.dartServer'];
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

  group('testCloseIosDialog', () {
    MockProcessManager pm;
    DeviceDiscovery discovery;

    setUp(() async {
      pm = MockProcessManager();
      discovery = FakeIosDeviceDiscovery();
    });

    test('succeeded', () async {
      Process proc = FakeProcess(0);
      when(pm.start(any, workingDirectory: anyNamed('workingDirectory'))).thenAnswer((_) => Future.value(proc));

      HealthCheckResult res = await closeIosDialog(pm: pm, discovery: discovery);

      expect(res.succeeded, isTrue);
    });

    test('succeeded with code signing overwrite', () async {
      Process proc = FakeProcess(0);
      when(pm.start(any, workingDirectory: anyNamed('workingDirectory'))).thenAnswer((_) => Future.value(proc));
      platform.Platform pl = platform.FakePlatform(environment: <String, String>{
        'FLUTTER_XCODE_CODE_SIGN_STYLE': 'Manual',
        'FLUTTER_XCODE_DEVELOPMENT_TEAM': 'S8QB4VV633',
        'FLUTTER_XCODE_PROVISIONING_PROFILE_SPECIFIER': 'a name with space',
      });

      HealthCheckResult res = await closeIosDialog(pm: pm, discovery: discovery, pl: pl);

      expect(res.succeeded, isTrue);
    });

    test('failed', () async {
      Process proc = FakeProcess(123);
      when(pm.start(any, workingDirectory: anyNamed('workingDirectory'))).thenAnswer((_) => Future.value(proc));

      expect(
        closeIosDialog(pm: pm, discovery: discovery),
        throwsA(TypeMatcher<BuildFailedError>()),
      );
    });
  });
}

class FakeIosDeviceDiscovery extends Fake implements DeviceDiscovery {
  @override
  Future<List<Device>> discoverDevices({int retriesDelayMs = 10000}) {
    IosDevice d = IosDevice(deviceId: 'fakeDeviceId');
    return Future.value(<Device>[d]);
  }
}

class MockProcessManager extends Mock implements ProcessManager {}

class FakeProcess extends Fake implements Process {
  FakeProcess(int exitCode) : _exitCode = exitCode;

  int _exitCode;

  @override
  Future<int> get exitCode => Future.value(_exitCode);

  @override
  Stream<List<int>> get stderr => Stream.fromIterable([
        [1, 2, 3]
      ]);

  @override
  Stream<List<int>> get stdout => Stream.fromIterable([
        [1, 2, 3]
      ]);
}
