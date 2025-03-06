// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_doctor/src/android_device.dart';
import 'package:device_doctor/src/device.dart';
import 'package:device_doctor/src/utils.dart';
import 'package:file/src/backends/memory/memory_file_system.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('AndroidDeviceDiscovery', () {
    late AndroidDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    List<List<int>> output;
    Process process;

    setUp(() {
      deviceDiscovery =
          AndroidDeviceDiscovery(MemoryFileSystem().file('output'));
      processManager = MockProcessManager();
    });

    test('deviceDiscovery no retries', () async {
      final sb = StringBuffer();
      sb.writeln('List of devices attached');
      sb.writeln('ZY223JQNMR      device');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      final List<Device> devices = await deviceDiscovery.discoverDevices(
        retryDuration: const Duration(seconds: 0),
        processManager: processManager,
      );
      expect(devices.length, equals(1));
      expect(devices[0].deviceId, equals('ZY223JQNMR'));
    });

    test('deviceDiscovery fails', () async {
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => throw TimeoutException('test'));
      expect(
        deviceDiscovery.discoverDevices(
            retryDuration: const Duration(seconds: 0),
            processManager: processManager),
        throwsA(const TypeMatcher<BuildFailedException>()),
      );
    });
  });

  group('AndroidDeviceProperties', () {
    late AndroidDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    Process propertyProcess;
    Process process;
    String output;

    setUp(() {
      deviceDiscovery =
          AndroidDeviceDiscovery(MemoryFileSystem().file('output'));
      processManager = MockProcessManager();
    });

    test('returns empty when no device is attached', () async {
      output = 'List of devices attached';
      process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);

      when(processManager.start(<Object>['adb', 'devices', '-l'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      expect(
          await deviceDiscovery.deviceProperties(
              processManager: processManager),
          equals(<String, String>{}));
    });

    test('get device properties', () async {
      output = '''[ro.product.brand]: [abc]
      [ro.build.id]: [def]
      [ro.build.type]: [ghi]
      [ro.product.model]: [jkl]
      [ro.product.board]: [mno]
      ''';
      propertyProcess = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);

      when(
        processManager.start(
          <Object>['adb', '-s', 'ZY223JQNMR', 'shell', 'getprop'],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(propertyProcess));

      final deviceProperties = await deviceDiscovery.getDeviceProperties(
          AndroidDevice(deviceId: 'ZY223JQNMR'),
          processManager: processManager);

      const expectedProperties = <String, String>{
        'product_brand': 'abc',
        'build_id': 'def',
        'build_type': 'ghi',
        'product_model': 'jkl',
        'product_board': 'mno',
      };
      expect(deviceProperties, equals(expectedProperties));
    });
  });

  group('AndroidAdbPowerServiceCheck', () {
    late AndroidDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    Process process;

    setUp(() {
      deviceDiscovery =
          AndroidDeviceDiscovery(MemoryFileSystem().file('output'));
      processManager = MockProcessManager();
    });

    test('returns success when adb power service is available', () async {
      process = FakeProcess(0);
      when(
        processManager.start(<Object>['adb', 'shell', 'dumpsys', 'power'],
            workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.adbPowerServiceCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, true);
      expect(healthCheckResult.name, kAdbPowerServiceCheckKey);
    });

    test('returns failure when adb returns none 0 code', () async {
      process = FakeProcess(1);
      when(
        processManager.start(<Object>['adb', 'shell', 'dumpsys', 'power'],
            workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.adbPowerServiceCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kAdbPowerServiceCheckKey);
      expect(
          healthCheckResult.details, 'Executable adb failed with exit code 1.');
    });
  });

  group('AndroidDevloperModeCheck', () {
    late AndroidDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    Process process;
    List<List<int>> output;

    setUp(() {
      deviceDiscovery =
          AndroidDeviceDiscovery(MemoryFileSystem().file('output'));
      processManager = MockProcessManager();
    });

    test('returns success when developer mode is on', () async {
      output = <List<int>>[utf8.encode('1')];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'settings',
            'get',
            'global',
            'development_settings_enabled'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.developerModeCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, true);
      expect(healthCheckResult.name, kDeveloperModeCheckKey);
    });

    test('returns failure when developer mode is off', () async {
      output = <List<int>>[utf8.encode('0')];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'settings',
            'get',
            'global',
            'development_settings_enabled'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.developerModeCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kDeveloperModeCheckKey);
      expect(healthCheckResult.details, 'developer mode is off');
    });

    test('returns success when screensaver is off', () async {
      output = <List<int>>[utf8.encode('0')];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'settings',
            'get',
            'secure',
            'screensaver_enabled'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.screenSaverCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, true);
      expect(healthCheckResult.name, kScreenSaverCheckKey);
    });

    test('returns failure when screensaver is on', () async {
      output = <List<int>>[utf8.encode('1')];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'settings',
            'get',
            'secure',
            'screensaver_enabled'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.screenSaverCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kScreenSaverCheckKey);
      expect(healthCheckResult.details, 'Screensaver is on');
    });

    test('returns failure when adb return none 0 code', () async {
      process = FakeProcess(1);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'settings',
            'get',
            'global',
            'development_settings_enabled'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.developerModeCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kDeveloperModeCheckKey);
      expect(
          healthCheckResult.details, 'Executable adb failed with exit code 1.');
    });
  });

  group('AndroidScreenOnCheck', () {
    late AndroidDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    Process process;
    List<List<int>> output;

    setUp(() {
      deviceDiscovery =
          AndroidDeviceDiscovery(MemoryFileSystem().file('output'));
      processManager = MockProcessManager();
    });

    test('returns success when screen is on', () async {
      const screenMessage = '''
      mHoldingDisplaySuspendBlocker=true
      ''';
      output = <List<int>>[utf8.encode(screenMessage)];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'dumpsys',
            'power',
            '|',
            'grep',
            'mHoldingDisplaySuspendBlocker'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult =
          await deviceDiscovery.screenOnCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, true);
      expect(healthCheckResult.name, kScreenOnCheckKey);
    });

    test('returns failure when screen is off', () async {
      const screenMessage = '''
      mHoldingDisplaySuspendBlocker=false
      ''';
      output = <List<int>>[utf8.encode(screenMessage)];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'dumpsys',
            'power',
            '|',
            'grep',
            'mHoldingDisplaySuspendBlocker'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult =
          await deviceDiscovery.screenOnCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kScreenOnCheckKey);
      expect(healthCheckResult.details, 'screen is off');
    });

    test('returns failure when adb return non 0 code', () async {
      process = FakeProcess(1);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'dumpsys',
            'power',
            '|',
            'grep',
            'mHoldingDisplaySuspendBlocker'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult =
          await deviceDiscovery.screenOnCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kScreenOnCheckKey);
      expect(
          healthCheckResult.details, 'Executable adb failed with exit code 1.');
    });
  });

  group('AndroidScreenRotationCheck', () {
    late AndroidDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    Process process;
    List<List<int>> output;

    setUp(() {
      deviceDiscovery =
          AndroidDeviceDiscovery(MemoryFileSystem().file('output'));
      processManager = MockProcessManager();
    });

    test('returns success when rotation is disabled', () async {
      output = <List<int>>[utf8.encode('0')];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'settings',
            'get',
            'system',
            'accelerometer_rotation'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.screenRotationCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, true);
      expect(healthCheckResult.name, kScreenRotationCheckKey);
    });

    test('returns failure when screen rotation is enabled', () async {
      output = <List<int>>[utf8.encode('1')];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'settings',
            'get',
            'system',
            'accelerometer_rotation'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.screenRotationCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kScreenRotationCheckKey);
      expect(healthCheckResult.details, 'Screen rotation is enabled');
    });
  });

  group('AndroidDeviceKillProcesses', () {
    late AndroidDevice device;
    late MockProcessManager processManager;
    Process listProcess;
    Process killProcess;
    List<List<int>>? output;

    setUp(() {
      device = AndroidDevice(deviceId: 'abc');
      processManager = MockProcessManager();
    });

    test('successfully killed running processes', () async {
      output = <List<int>>[
        utf8.encode(
          'Proc #27: fg     T/ /TOP  LCM  t: 0 0:com.google.android.apps.nexuslauncher/u0a199 (top-activity)',
        ),
      ];
      listProcess = FakeProcess(0, out: output);
      killProcess = FakeProcess(0);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'dumpsys',
            'activity',
            '|',
            'grep',
            'top-activity'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(listProcess));
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'am',
            'force-stop',
            'com.google.android.apps.nexuslauncher'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(killProcess));

      final result = await device.killProcesses(processManager: processManager);
      expect(result, true);
    });

    test('no running processes', () async {
      output = <List<int>>[];
      listProcess = FakeProcess(0, out: output);
      killProcess = FakeProcess(0);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'dumpsys',
            'activity',
            '|',
            'grep',
            'top-activity'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(listProcess));
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'am',
            'force-stop',
            'com.google.android.apps.nexuslauncher'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(killProcess));

      final result = await device.killProcesses(processManager: processManager);
      expect(result, true);
    });

    test('fails to kill running processes', () async {
      output = <List<int>>[
        utf8.encode(
          'Proc #27: fg     T/ /TOP  LCM  t: 0 0:com.google.android.apps.nexuslauncher/u0a199 (top-activity)',
        ),
      ];
      listProcess = FakeProcess(0, out: output);
      killProcess = FakeProcess(1);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'dumpsys',
            'activity',
            '|',
            'grep',
            'top-activity'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(listProcess));
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'am',
            'force-stop',
            'com.google.android.apps.nexuslauncher'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(killProcess));

      final result = await device.killProcesses(processManager: processManager);
      expect(result, false);
    });
  });

  group('KillAdbServerCheck', () {
    late AndroidDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    Process process;

    setUp(() {
      deviceDiscovery =
          AndroidDeviceDiscovery(MemoryFileSystem().file('output'));
      processManager = MockProcessManager();
    });

    test('returns success when adb power service is killed', () async {
      process = FakeProcess(0);
      when(processManager.start(<Object>['adb', 'kill-server'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.killAdbServerCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, true);
      expect(healthCheckResult.name, kKillAdbServerCheckKey);
    });

    test('returns failure when adb returns non 0 code', () async {
      process = FakeProcess(1);
      when(processManager.start(<Object>['adb', 'kill-server'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.killAdbServerCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kKillAdbServerCheckKey);
      expect(
          healthCheckResult.details, 'Executable adb failed with exit code 1.');
    });
  });

  group('BatteryLevelCheck', () {
    late AndroidDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    Process process;
    List<List<int>> output;

    setUp(() {
      deviceDiscovery =
          AndroidDeviceDiscovery(MemoryFileSystem().file('output'));
      processManager = MockProcessManager();
    });

    test('returns success when battery level is high', () async {
      const screenMessage = '''
  level: 100
  mod level: -1
      ''';
      output = <List<int>>[utf8.encode(screenMessage)];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>['adb', 'shell', 'dumpsys', 'battery', '|', 'grep', 'level'],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.batteryLevelCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, true);
      expect(healthCheckResult.name, kBatteryLevelCheckKey);
    });

    test('returns failure when battery level is below threshold', () async {
      const screenMessage = '''
  level: 10
  mod level: -1
      ''';
      output = <List<int>>[utf8.encode(screenMessage)];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>['adb', 'shell', 'dumpsys', 'battery', '|', 'grep', 'level'],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.batteryLevelCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kBatteryLevelCheckKey);
      expect(healthCheckResult.details, 'Battery level (10) is below 15');
    });
  });

  group('BatteryTemperatureCheck', () {
    late AndroidDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    Process process;
    List<List<int>> output;

    setUp(() {
      deviceDiscovery =
          AndroidDeviceDiscovery(MemoryFileSystem().file('output'));
      processManager = MockProcessManager();
    });

    test('returns success when battery temperature is low', () async {
      const screenMessage = '''
  temperature: 24
      ''';
      output = <List<int>>[utf8.encode(screenMessage)];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'dumpsys',
            'battery',
            '|',
            'grep',
            'temperature'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.batteryTemperatureCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, true);
      expect(healthCheckResult.name, kBatteryTemperatureCheckKey);
    });

    test('returns failure when battery temperature is above threshold',
        () async {
      const screenMessage = '''
  temperature: 350
      ''';
      output = <List<int>>[utf8.encode(screenMessage)];
      process = FakeProcess(0, out: output);
      when(
        processManager.start(
          <Object>[
            'adb',
            'shell',
            'dumpsys',
            'battery',
            '|',
            'grep',
            'temperature'
          ],
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer((_) => Future.value(process));

      final healthCheckResult = await deviceDiscovery.batteryTemperatureCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kBatteryTemperatureCheckKey);
      expect(
          healthCheckResult.details, 'Battery temperature (35°C) is over 34°C');
    });
  });
}
