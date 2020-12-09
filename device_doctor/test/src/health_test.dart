// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:platform/platform.dart' as platform;
import 'package:process/process.dart';
import 'package:test/test.dart';

import 'package:device_doctor/src/health.dart';
import 'package:device_doctor/src/utils.dart';

import 'fake_ios_device.dart';

void main() {
  group('testCloseIosDialog', () {
    MockProcessManager pm;
    FakeIosDeviceDiscovery discovery;

    setUp(() async {
      pm = MockProcessManager();
      discovery = FakeIosDeviceDiscovery();
      discovery.outputs = <dynamic>['fakeDeviceId'];
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
