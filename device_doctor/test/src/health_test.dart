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

void main() {
  group('testCloseIosDialog', () {
    MockProcessManager pm;

    setUp(() async {
      pm = MockProcessManager();
    });

    test('succeeded', () async {
      Process proc = FakeProcess(0);
      when(pm.start(any, workingDirectory: anyNamed('workingDirectory'))).thenAnswer((_) => Future.value(proc));

      HealthCheckResult res = await closeIosDialog(pm: pm);

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

      HealthCheckResult res = await closeIosDialog(pm: pm, pl: pl);

      expect(res.succeeded, isTrue);
    });

    test('failed', () async {
      Process proc = FakeProcess(123);
      when(pm.start(any, workingDirectory: anyNamed('workingDirectory'))).thenAnswer((_) => Future.value(proc));

      expect(
        closeIosDialog(pm: pm),
        throwsA(TypeMatcher<BuildFailedError>()),
      );
    });

    test('tool is not found', () async {
      Process proc = FakeProcess(123);
      when(pm.start(any, workingDirectory: anyNamed('workingDirectory'))).thenAnswer((_) => Future.value(proc));

      expect(
        closeIosDialog(pm: pm, infraDialog: 'abc'),
        throwsA(TypeMatcher<BuildFailedError>()),
      );
    });
  });

  group('healthCheck', () {
    Map<String, List<HealthCheckResult>> deviceChecks;

    setUp(() async {
      deviceChecks = <String, List<HealthCheckResult>>{};
    });

    test('with no device', () async {
      final Map<String, Map<String, dynamic>> healthcheckMap = await healthcheck(deviceChecks);
      expect(healthcheckMap, <String, Map<String, dynamic>>{
        kAttachedDeviceHealthcheckKey: <String, dynamic>{'status': false, 'details': kAttachedDeviceHealthcheckValue}
      });
    });

    test('with failed check', () async {
      final List<HealthCheckResult> healthChecks = <HealthCheckResult>[
        HealthCheckResult.success('check1'),
        HealthCheckResult.failure('check2', 'abc')
      ];
      deviceChecks['device1'] = healthChecks;
      final Map<String, Map<String, dynamic>> healthcheckMap = await healthcheck(deviceChecks);
      expect(healthcheckMap, <String, Map<String, dynamic>>{
        kAttachedDeviceHealthcheckKey: <String, dynamic>{'status': true, 'details': null},
        'check1': <String, dynamic>{'status': true, 'details': null},
        'check2': <String, dynamic>{'status': false, 'details': 'abc'}
      });
    });

    test('without failed check', () async {
      final List<HealthCheckResult> healthChecks = <HealthCheckResult>[
        HealthCheckResult.success('check1'),
        HealthCheckResult.success('check2')
      ];
      deviceChecks['device1'] = healthChecks;
      final Map<String, Map<String, dynamic>> healthcheckMap = await healthcheck(deviceChecks);
      expect(healthcheckMap, <String, Map<String, dynamic>>{
        kAttachedDeviceHealthcheckKey: <String, dynamic>{'status': true, 'details': null},
        'check1': <String, dynamic>{'status': true, 'details': null},
        'check2': <String, dynamic>{'status': true, 'details': null}
      });
    });
  });
}

class MockPlatform extends Mock implements Platform {}

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
