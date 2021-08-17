// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:device_doctor/src/android_device.dart';
import 'package:device_doctor/src/device.dart';
import 'package:device_doctor/src/health.dart';
import 'package:device_doctor/src/utils.dart';

import 'utils.dart';

void main() {
  group('AndroidDeviceDiscovery', () {
    AndroidDeviceDiscovery deviceDiscovery;
    MockProcessManager processManager;
    List<List<int>> output;
    Process process;

    setUp(() {
      deviceDiscovery = AndroidDeviceDiscovery('/tmp/output');
      processManager = MockProcessManager();
    });

    test('deviceDiscovery no retries', () async {
      StringBuffer sb = StringBuffer();
      sb.writeln('List of devices attached');
      sb.writeln('ZY223JQNMR      device');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      List<Device> devices = await deviceDiscovery.discoverDevices(
          retryDuration: const Duration(seconds: 0), processManager: processManager);
      expect(devices.length, equals(1));
      expect(devices[0].deviceId, equals('ZY223JQNMR'));
    });

    test('deviceDiscovery fails', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => throw TimeoutException('test'));
      expect(deviceDiscovery.discoverDevices(retryDuration: const Duration(seconds: 0), processManager: processManager),
          throwsA(TypeMatcher<BuildFailedError>()));
    });
  });

  group('AndroidDeviceProperties', () {
    AndroidDeviceDiscovery deviceDiscovery;
    MockProcessManager processManager;
    Process property_process;
    Process process;
    String output;

    setUp(() {
      deviceDiscovery = AndroidDeviceDiscovery('/tmp/output');
      processManager = MockProcessManager();
    });

    test('returns empty when no device is attached', () async {
      output = 'List of devices attached';
      process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);

      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      expect(await deviceDiscovery.deviceProperties(processManager: processManager), equals(<String, String>{}));
    });

    test('get device properties', () async {
      output = '''[ro.product.brand]: [abc]
      [ro.build.id]: [def]
      [ro.build.type]: [ghi]
      [ro.product.model]: [jkl]
      [ro.product.board]: [mno]
      ''';
      property_process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);

      when(processManager.start(<dynamic>['adb', '-s', 'ZY223JQNMR', 'shell', 'getprop'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(property_process));

      Map<String, String> deviceProperties = await deviceDiscovery
          .getDeviceProperties(AndroidDevice(deviceId: 'ZY223JQNMR'), processManager: processManager);

      const Map<String, String> expectedProperties = <String, String>{
        'product_brand': 'abc',
        'build_id': 'def',
        'build_type': 'ghi',
        'product_model': 'jkl',
        'product_board': 'mno'
      };
      expect(deviceProperties, equals(expectedProperties));
    });
  });

  group('AndroidAdbPowerServiceCheck', () {
    AndroidDeviceDiscovery deviceDiscovery;
    MockProcessManager processManager;
    Process process;

    setUp(() {
      deviceDiscovery = AndroidDeviceDiscovery('/tmp/output');
      processManager = MockProcessManager();
    });

    test('returns success when adb power service is available', () async {
      process = FakeProcess(0);
      when(processManager
              .start(<dynamic>['adb', 'shell', 'dumpsys', 'power'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      HealthCheckResult healthCheckResult = await deviceDiscovery.adbPowerServiceCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, true);
      expect(healthCheckResult.name, kAdbPowerServiceCheckKey);
    });

    test('returns failure when adb returns none 0 code', () async {
      process = FakeProcess(1);
      when(processManager
              .start(<dynamic>['adb', 'shell', 'dumpsys', 'power'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      HealthCheckResult healthCheckResult = await deviceDiscovery.adbPowerServiceCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kAdbPowerServiceCheckKey);
      expect(healthCheckResult.details, 'Executable adb failed with exit code 1.');
    });
  });

  group('AndroidDevloperModeCheck', () {
    AndroidDeviceDiscovery deviceDiscovery;
    MockProcessManager processManager;
    Process process;
    List<List<int>> output;

    setUp(() {
      deviceDiscovery = AndroidDeviceDiscovery('/tmp/output');
      processManager = MockProcessManager();
    });

    test('returns success when developer mode is on', () async {
      output = <List<int>>[utf8.encode('1')];
      process = FakeProcess(0, out: output);
      when(processManager.start(<dynamic>['adb', 'shell', 'settings', 'get', 'global', 'development_settings_enabled'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      HealthCheckResult healthCheckResult = await deviceDiscovery.developerModeCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, true);
      expect(healthCheckResult.name, kDeveloperModeCheckKey);
    });

    test('returns failure when developer mode is off', () async {
      output = <List<int>>[utf8.encode('0')];
      process = FakeProcess(0, out: output);
      when(processManager.start(<dynamic>['adb', 'shell', 'settings', 'get', 'global', 'development_settings_enabled'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      HealthCheckResult healthCheckResult = await deviceDiscovery.developerModeCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kDeveloperModeCheckKey);
      expect(healthCheckResult.details, 'developer mode is off');
    });

    test('returns failure when adb return none 0 code', () async {
      process = FakeProcess(1);
      when(processManager.start(<dynamic>['adb', 'shell', 'settings', 'get', 'global', 'development_settings_enabled'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      HealthCheckResult healthCheckResult = await deviceDiscovery.developerModeCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kDeveloperModeCheckKey);
      expect(healthCheckResult.details, 'Executable adb failed with exit code 1.');
    });
  });

  group('AndroidDeviceKillProcesses', () {
    AndroidDevice device;
    MockProcessManager processManager;
    Process listProcess;
    Process killProcess;
    List<List<int>> output;

    setUp(() {
      device = AndroidDevice(deviceId: 'abc');
      processManager = MockProcessManager();
    });

    test('successfully killed running processes', () async {
      output = <List<int>>[
        utf8.encode('Proc #27: fg     T/ /TOP  LCM  t: 0 0:com.google.android.apps.nexuslauncher/u0a199 (top-activity)')
      ];
      listProcess = FakeProcess(0, out: output);
      killProcess = FakeProcess(0);
      when(processManager.start(<dynamic>['adb', 'shell', 'dumpsys', 'activity', '|', 'grep', 'top-activity'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(listProcess));
      when(processManager.start(<dynamic>['adb', 'shell', 'am', 'force-stop', 'com.google.android.apps.nexuslauncher'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(killProcess));

      final bool result = await device.killProcesses(processManager: processManager);
      expect(result, true);
    });

    test('no running processes', () async {
      listProcess = FakeProcess(0, out: output);
      killProcess = FakeProcess(0);
      when(processManager.start(<dynamic>['adb', 'shell', 'dumpsys', 'activity', '|', 'grep', 'top-activity'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(listProcess));
      when(processManager.start(<dynamic>['adb', 'shell', 'am', 'force-stop', 'com.google.android.apps.nexuslauncher'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(killProcess));

      final bool result = await device.killProcesses(processManager: processManager);
      expect(result, true);
    });

    test('fails to kill running processes', () async {
      output = <List<int>>[
        utf8.encode('Proc #27: fg     T/ /TOP  LCM  t: 0 0:com.google.android.apps.nexuslauncher/u0a199 (top-activity)')
      ];
      listProcess = FakeProcess(0, out: output);
      killProcess = FakeProcess(1);
      when(processManager.start(<dynamic>['adb', 'shell', 'dumpsys', 'activity', '|', 'grep', 'top-activity'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(listProcess));
      when(processManager.start(<dynamic>['adb', 'shell', 'am', 'force-stop', 'com.google.android.apps.nexuslauncher'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(killProcess));

      final bool result = await device.killProcesses(processManager: processManager);
      expect(result, false);
    });
  });
}
