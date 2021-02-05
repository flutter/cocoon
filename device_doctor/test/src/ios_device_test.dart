// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:device_doctor/src/device.dart';
import 'package:device_doctor/src/health.dart';
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

    test('checkDevices with healthy device', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      process = FakeProcess(0);
      deviceDiscovery.outputs = <dynamic>['abcdefg'];
      Map<String, List<HealthCheckResult>> results = await deviceDiscovery.checkDevices(processManager: processManager);
      expect(results.keys.length, equals(1));
      expect(results.keys.toList()[0], 'ios-device-abcdefg');
      expect(results['ios-device-abcdefg'].length, equals(2));
      expect(results['ios-device-abcdefg'][0].succeeded, true);
      expect(results['ios-device-abcdefg'][1].succeeded, true);
    });

    test('checkDevices with unhealthy device - unlock keychain failed', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      process = FakeProcess(1);
      deviceDiscovery.outputs = <dynamic>['abcdefg'];
      Map<String, List<HealthCheckResult>> results = await deviceDiscovery.checkDevices(processManager: processManager);
      expect(results.keys.length, equals(1));
      expect(results.keys.toList()[0], 'ios-device-abcdefg');
      expect(results['ios-device-abcdefg'].length, equals(2));
      expect(results['ios-device-abcdefg'][0].succeeded, true);
      expect(results['ios-device-abcdefg'][1].name, kKeychainUnlockCheckKey);
      expect(results['ios-device-abcdefg'][1].succeeded, false);
    });
  });
}
