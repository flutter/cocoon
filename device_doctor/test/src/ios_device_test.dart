// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:file/src/backends/memory/memory_file_system.dart';
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
      deviceDiscovery = FakeIosDeviceDiscovery(MemoryFileSystem().file('output'));
      processManager = MockProcessManager();
    });

    test('deviceDiscovery', () async {
      deviceDiscovery.outputs = <dynamic>[''];
      expect(await deviceDiscovery.discoverDevices(), isEmpty);
      StringBuffer sb = StringBuffer();
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
      process = FakeProcess(0, out: null);
      deviceDiscovery.outputs = <dynamic>['abcdefg'];
      Map<String, List<HealthCheckResult>> results = await deviceDiscovery.checkDevices(processManager: processManager);
      expect(results.keys.length, equals(1));
      expect(results.keys.toList()[0], 'ios-device-abcdefg');
      expect(results['ios-device-abcdefg'].length, 7);
      expect(results['ios-device-abcdefg'][0].name, kDeviceAccessCheckKey);
      expect(results['ios-device-abcdefg'][0].succeeded, true);
      expect(results['ios-device-abcdefg'][1].name, kKeychainUnlockCheckKey);
      expect(results['ios-device-abcdefg'][1].succeeded, true);
      expect(results['ios-device-abcdefg'][2].name, kCertCheckKey);
      expect(results['ios-device-abcdefg'][2].succeeded, false);
      expect(results['ios-device-abcdefg'][3].name, kDevicePairCheckKey);
      expect(results['ios-device-abcdefg'][3].succeeded, false);
      expect(results['ios-device-abcdefg'][4].name, kUserAutoLoginCheckKey);
      expect(results['ios-device-abcdefg'][4].succeeded, false);
      expect(results['ios-device-abcdefg'][5].name, kDeviceProvisioningProfileCheckKey);
      expect(results['ios-device-abcdefg'][5].succeeded, false);
      expect(results['ios-device-abcdefg'][6].name, kBatteryLevelCheckKey);
      expect(results['ios-device-abcdefg'][6].succeeded, false);
    });
  });

  group('IosDeviceDiscovery - health checks', () {
    IosDeviceDiscovery deviceDiscovery;
    MockProcessManager processManager;
    Process process;
    List<List<int>> output;

    setUp(() {
      processManager = MockProcessManager();
      deviceDiscovery = DeviceDiscovery('ios', MemoryFileSystem().file('output'));
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
      StringBuffer sb = StringBuffer();
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
      StringBuffer sb = StringBuffer();
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
      StringBuffer sb = StringBuffer();
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

    test('Cert check - failure with revoked certificates', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      StringBuffer sb = StringBuffer();
      sb.writeln('1) abcdefg "Apple Development: Flutter Devicelab (hijklmn)" (CSSMERR_TP_CERT_REVOKED)');
      sb.writeln('1 valid identities found');
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
      StringBuffer sb = StringBuffer();
      sb.writeln('SUCCESS: Validated pairing with device abcdefg-hijklmn');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      HealthCheckResult healthCheckResult = await deviceDiscovery.devicePairCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, true);
    });

    test('Device pair check - failure', () async {
      when(processManager.start(any, workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      StringBuffer sb = StringBuffer();
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

    group('Device provisioning profile check', () {
      Process lsProcess;
      Process securityProcess;
      List<List<int>> lsOutput;
      List<List<int>> securityOutput;
      test('success', () async {
        String fileName = 'abcdefg';
        lsOutput = <List<int>>[utf8.encode(fileName)];
        lsProcess = FakeProcess(0, out: lsOutput);

        String deviceID = 'deviceId';
        String profileContent = '''<array>
        <string>test1</string>
        <string>$deviceID</string>
        <string>test2</string>
        </array>
        ''';
        securityOutput = <List<int>>[utf8.encode(profileContent)];
        securityProcess = FakeProcess(0, out: securityOutput);

        final String homeDir = Platform.environment['HOME'];
        when(processManager.start(<dynamic>['ls', '$homeDir/Library/MobileDevice/Provisioning\ Profiles'],
                workingDirectory: anyNamed('workingDirectory')))
            .thenAnswer((_) => Future.value(lsProcess));
        when(processManager.start(<dynamic>[
          'security',
          'cms',
          '-D',
          '-i',
          '$homeDir/Library/MobileDevice/Provisioning\ Profiles/$fileName'
        ], workingDirectory: anyNamed('workingDirectory')))
            .thenAnswer((_) => Future.value(securityProcess));

        HealthCheckResult healthCheckResult =
            await deviceDiscovery.deviceProvisioningProfileCheck(deviceID, processManager: processManager);
        expect(healthCheckResult.succeeded, true);
        expect(healthCheckResult.name, kDeviceProvisioningProfileCheckKey);
      });

      test('deviceId does not exist', () async {
        String fileName = 'abcdefg';
        lsOutput = <List<int>>[utf8.encode(fileName)];
        lsProcess = FakeProcess(0, out: lsOutput);

        String deviceID = 'deviceId';
        String profileContent = '''<array>
        <string>test1</string>
        <string>test2</string>
        </array>
        ''';
        securityOutput = <List<int>>[utf8.encode(profileContent)];
        securityProcess = FakeProcess(0, out: securityOutput);

        final String homeDir = Platform.environment['HOME'];
        when(processManager.start(<dynamic>['ls', '$homeDir/Library/MobileDevice/Provisioning\ Profiles'],
                workingDirectory: anyNamed('workingDirectory')))
            .thenAnswer((_) => Future.value(lsProcess));
        when(processManager.start(<dynamic>[
          'security',
          'cms',
          '-D',
          '-i',
          '$homeDir/Library/MobileDevice/Provisioning\ Profiles/$fileName'
        ], workingDirectory: anyNamed('workingDirectory')))
            .thenAnswer((_) => Future.value(securityProcess));

        HealthCheckResult healthCheckResult =
            await deviceDiscovery.deviceProvisioningProfileCheck(deviceID, processManager: processManager);
        expect(healthCheckResult.succeeded, false);
        expect(healthCheckResult.name, kDeviceProvisioningProfileCheckKey);
        expect(healthCheckResult.details, 'device does not exist in the provisioning profile');
      });
    });

    group('Device battery check', () {
      Process process;
      List<List<int>> output;
      test('battery level is okay', () async {
        String batteryLevel = '100';
        output = <List<int>>[utf8.encode(batteryLevel)];
        process = FakeProcess(0, out: output);

        when(processManager.start(
                <dynamic>['ideviceinfo', '-q', 'com.apple.mobile.battery', '-k', 'BatteryCurrentCapacity'],
                workingDirectory: anyNamed('workingDirectory')))
            .thenAnswer((_) => Future.value(process));

        HealthCheckResult healthCheckResult = await deviceDiscovery.batteryLevelCheck(processManager: processManager);
        expect(healthCheckResult.succeeded, true);
        expect(healthCheckResult.name, kBatteryLevelCheckKey);
      });

      test('battery level is below minLevel', () async {
        String batteryLevel = '10';
        output = <List<int>>[utf8.encode(batteryLevel)];
        process = FakeProcess(0, out: output);

        when(processManager.start(
                <dynamic>['ideviceinfo', '-q', 'com.apple.mobile.battery', '-k', 'BatteryCurrentCapacity'],
                workingDirectory: anyNamed('workingDirectory')))
            .thenAnswer((_) => Future.value(process));

        HealthCheckResult healthCheckResult = await deviceDiscovery.batteryLevelCheck(processManager: processManager);
        expect(healthCheckResult.succeeded, false);
        expect(healthCheckResult.name, kBatteryLevelCheckKey);
        expect(healthCheckResult.details, 'Battery level ($batteryLevel) is below 15');
      });
    });
  });

  group('IosDevice recovery checks', () {
    IosDevice device;
    MockProcessManager processManager;
    Process process;
    Process whichProcess;
    String output;
    String ideviceinstallerPath;

    setUp(() {
      processManager = MockProcessManager();
      device = IosDevice(deviceId: 'abc');
      ideviceinstallerPath = '/abc/def/ideviceinstaller';
      whichProcess = FakeProcess(0, out: <List<int>>[utf8.encode(ideviceinstallerPath)]);
    });
    test('device restart - success', () async {
      when(processManager
              .start(<dynamic>['idevicediagnostics', 'restart'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      process = FakeProcess(0);
      final bool result = await device.restart_device(processManager: processManager);
      expect(result, isTrue);
    });

    test('device restart - failure', () async {
      when(processManager
              .start(<dynamic>['idevicediagnostics', 'restart'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      process = FakeProcess(1);
      final bool result = await device.restart_device(processManager: processManager);
      expect(result, isFalse);
    });

    test('device restart - skip 32 bit phone', () async {
      device = IosDevice(deviceId: '822ef7958bba573829d85eef4df6cbdd86593730');
      final bool result = await device.restart_device(processManager: processManager);
      expect(result, isTrue);
    });

    test('list applications - failure', () async {
      when(processManager.start(<String>['which', 'ideviceinstaller'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(whichProcess));
      when(processManager.start(<dynamic>[ideviceinstallerPath, '-l'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      process = FakeProcess(1);

      final bool result = await device.uninstall_applications(processManager: processManager);
      expect(result, isFalse);
    });

    test('uninstall applications - no device is available', () async {
      when(processManager.start(<String>['which', 'ideviceinstaller'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(whichProcess));
      when(processManager.start(<dynamic>[ideviceinstallerPath, '-l'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      output = '''No device found.
        ''';
      process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);

      final bool result = await device.uninstall_applications(processManager: processManager);
      expect(result, isTrue);
    });

    test('uninstall applications - no application exist', () async {
      when(processManager.start(<String>['which', 'ideviceinstaller'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(whichProcess));
      when(processManager.start(<dynamic>[ideviceinstallerPath, '-l'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      output = '''CFBundleIdentifier, CFBundleVersion, CFBundleDisplayName
        ''';
      process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);

      final bool result = await device.uninstall_applications(processManager: processManager);
      expect(result, isTrue);
    });

    test('uninstall applications - applications exist with exception', () async {
      Process process_uninstall;
      when(processManager.start(<String>['which', 'ideviceinstaller'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(whichProcess));
      when(processManager.start(<dynamic>[ideviceinstallerPath, '-l'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      when(processManager
              .start(<dynamic>[ideviceinstallerPath, '-U', 'abc'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process_uninstall));
      when(processManager
              .start(<dynamic>[ideviceinstallerPath, '-U', 'jkl'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process_uninstall));

      output = '''CFBundleIdentifier, CFBundleVersion, CFBundleDisplayName
        abc, def, ghi
        jkl, mno, pqr
        ''';
      process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);
      process_uninstall = FakeProcess(1);

      final bool result = await device.uninstall_applications(processManager: processManager);
      expect(result, isFalse);
    });

    test('uninstall applications - applications exist', () async {
      Process process_uninstall;
      when(processManager.start(<String>['which', 'ideviceinstaller'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(whichProcess));
      when(processManager.start(<dynamic>[ideviceinstallerPath, '-l'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      when(processManager
              .start(<dynamic>[ideviceinstallerPath, '-U', 'abc'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process_uninstall));
      when(processManager
              .start(<dynamic>[ideviceinstallerPath, '-U', 'jkl'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process_uninstall));

      output = '''CFBundleIdentifier, CFBundleVersion, CFBundleDisplayName
        abc, def, ghi
        jkl, mno, pqr
        ''';
      process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);
      process_uninstall = FakeProcess(0);

      final bool result = await device.uninstall_applications(processManager: processManager);
      expect(result, isTrue);
    });
  });

  group('deviceListOutput', () {
    IosDeviceDiscovery deviceDiscovery;
    MockProcessManager processManager;
    Process processIdeviceID;
    Process processWhichIdeviceID;

    setUp(() {
      processManager = MockProcessManager();
      deviceDiscovery = DeviceDiscovery('ios', MemoryFileSystem().file('output'));
    });

    test('success', () async {
      when(processManager.start(<String>['which', 'idevice_id'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(processWhichIdeviceID));
      when(processManager.start(<String>['/test/idevice_id', '-l'], workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(processIdeviceID));
      processIdeviceID = FakeProcess(0, out: <List<int>>[utf8.encode('abc')]);
      processWhichIdeviceID = FakeProcess(0, out: <List<int>>[utf8.encode('/test/idevice_id')]);
      String deviceId = await deviceDiscovery.deviceListOutput(processManager: processManager);
      expect(deviceId, 'abc');
    });
  });
}
