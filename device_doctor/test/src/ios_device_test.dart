// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:device_doctor/src/device.dart';
import 'package:device_doctor/src/health.dart';
import 'package:device_doctor/src/ios_device.dart';
import 'package:device_doctor/src/utils.dart';

import 'fake_ios_device.dart';
import 'utils.dart';

void main() {
  group('IosDeviceDiscovery', () {
    FakeIosDeviceDiscovery deviceDiscovery;
    MockProcessManager processManager;
    Process process;

    setUp(() {
      deviceDiscovery = FakeIosDeviceDiscovery('/tmp/output');
      processManager = MockProcessManager();
    });

    test('deviceDiscovery', () async {
      deviceDiscovery.outputs = <dynamic>[''];
      expect(await deviceDiscovery.discoverDevices(), isEmpty);
      StringBuffer sb = new StringBuffer();
      sb.writeln('abcdefg');
      deviceDiscovery.outputs = <dynamic>[sb.toString()];
      List<Device> devices = await deviceDiscovery.discoverDevices();
      expect(devices.length, equals(1));
      expect(devices[0].deviceId, equals('abcdefg'));
    });

    test('checkDevices without device', () async {
      deviceDiscovery.outputs = <dynamic>[''];
      Map<String, List<HealthCheckResult>> results = await deviceDiscovery.checkDevices();
      await expectLater(results.keys.length, 0);
    });

    test('checkDevices with device', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      process = FakeProcess(0);
      deviceDiscovery.outputs = <dynamic>['abcdefg'];
      Map<String, List<HealthCheckResult>> results = await deviceDiscovery.checkDevices(processManager: processManager);
      expect(results.keys.length, equals(1));
      expect(results.keys.toList()[0], 'ios-device-abcdefg');
      expect(results['ios-device-abcdefg'].length, equals(4));
      expect(results['ios-device-abcdefg'][0].succeeded, true);
      expect(results['ios-device-abcdefg'][1].succeeded, true);
      expect(results['ios-device-abcdefg'][2].succeeded, false);
      expect(results['ios-device-abcdefg'][3].succeeded, false);
    });
  });

  group('IosDeviceDiscovery - health checks', () {
    IosDeviceDiscovery deviceDiscovery;
    MockProcessManager processManager;
    Process process;
    List<List<int>> output;

    setUp(() {
      processManager = MockProcessManager();
      deviceDiscovery = DeviceDiscovery('ios', '/tmp');
    });

    test('Keychain unlock check - success', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      process = FakeProcess(0);
      HealthCheckResult healthCheckResult = await deviceDiscovery.keychainUnlockCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, true);
    });

    test('Keychain unlock check - exception', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      process = FakeProcess(1);
      HealthCheckResult healthCheckResult = await deviceDiscovery.keychainUnlockCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kKeychainUnlockCheckKey);
      expect(healthCheckResult.details, 'Executable ${kUnlockLoginKeychain} failed with exit code 1.');
    });

    test('Cert check - success', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      StringBuffer sb = new StringBuffer();
      sb.writeln('1) abcdefg "Apple Development: Flutter Devicelab (hijklmn)"');
      sb.writeln('1 valid identities found');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      HealthCheckResult healthCheckResult = await deviceDiscovery.certCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, true);
    });

    test('Cert check - failure without target certificate', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      StringBuffer sb = new StringBuffer();
      sb.writeln('abcdefg');
      sb.writeln('hijklmn');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      HealthCheckResult healthCheckResult = await deviceDiscovery.certCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kCertCheckKey);
      expect(healthCheckResult.details, sb.toString().trim());
    });

    test('Cert check - failure with multiple certificates', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      StringBuffer sb = new StringBuffer();
      sb.writeln('1) abcdefg "Apple Development: Flutter Devicelab (hijklmn)"');

      sb.writeln('1) opqrst "uvwxyz"');
      sb.writeln('2 valid identities found');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      HealthCheckResult healthCheckResult = await deviceDiscovery.certCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kCertCheckKey);
      expect(healthCheckResult.details, sb.toString().trim());
    });

    test('Cert check - exception', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      process = FakeProcess(1);
      HealthCheckResult healthCheckResult = await deviceDiscovery.certCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kCertCheckKey);
      expect(healthCheckResult.details, 'Executable security failed with exit code 1.');
    });

    test('Device pair check - success', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      StringBuffer sb = new StringBuffer();
      sb.writeln('SUCCESS: Validated pairing with device abcdefg-hijklmn');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      HealthCheckResult healthCheckResult = await deviceDiscovery.devicePairCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, true);
    });

    test('Device pair check - failure', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      StringBuffer sb = new StringBuffer();
      sb.writeln('abcdefg');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      HealthCheckResult healthCheckResult = await deviceDiscovery.devicePairCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kDevicePairCheckKey);
      expect(healthCheckResult.details, sb.toString().trim());
    });

    test('Device pair check - exception', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      process = FakeProcess(1);
      HealthCheckResult healthCheckResult = await deviceDiscovery.devicePairCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kDevicePairCheckKey);
      expect(healthCheckResult.details, 'Executable idevicepair failed with exit code 1.');
    });
  });
}
