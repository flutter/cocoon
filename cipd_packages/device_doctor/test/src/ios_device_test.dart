// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:device_doctor/src/ios_device.dart';
import 'package:device_doctor/src/utils.dart';
import 'package:file/src/backends/memory/memory_file_system.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'fake_ios_device.dart';
import 'utils.dart';

void main() {
  group('IosDeviceDiscovery', () {
    late FakeIosDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    Process process;

    setUp(() {
      deviceDiscovery =
          FakeIosDeviceDiscovery(MemoryFileSystem().file('output'));
      processManager = MockProcessManager();
    });

    test('deviceDiscovery', () async {
      deviceDiscovery.outputs = <dynamic>[''];
      expect(await deviceDiscovery.discoverDevices(), isEmpty);
      final sb = StringBuffer();
      sb.writeln('abcdefg');
      deviceDiscovery.outputs = <dynamic>[sb.toString()];
      final devices = await deviceDiscovery.discoverDevices();
      expect(devices.length, equals(1));
      expect(devices[0].deviceId, equals('abcdefg'));
    });

    test('checkDevices without device', () async {
      deviceDiscovery.outputs = <dynamic>[''];
      final results = await deviceDiscovery.checkDevices();
      await expectLater(results.keys.length, 0);
    });

    test('checkDevices with device', () async {
      process = FakeProcess(0, out: <List<int>>[]);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      deviceDiscovery.outputs = <dynamic>['abcdefg'];
      final results =
          await deviceDiscovery.checkDevices(processManager: processManager);
      expect(results['ios-device-abcdefg'], isNotNull);
      expect(results.keys.length, equals(1));
      expect(results.keys.toList()[0], 'ios-device-abcdefg');
      final healthCheckResults = results['ios-device-abcdefg']!;
      expect(healthCheckResults.length, 7);
      expect(healthCheckResults[0].name, kDeviceAccessCheckKey);
      expect(healthCheckResults[0].succeeded, true);
      expect(healthCheckResults[1].name, kKeychainUnlockCheckKey);
      expect(healthCheckResults[1].succeeded, true);
      expect(healthCheckResults[2].name, kCertCheckKey);
      expect(healthCheckResults[2].succeeded, false);
      expect(healthCheckResults[3].name, kDevicePairCheckKey);
      expect(healthCheckResults[3].succeeded, false);
      expect(healthCheckResults[4].name, kUserAutoLoginCheckKey);
      expect(healthCheckResults[4].succeeded, false);
      expect(healthCheckResults[5].name, kDeviceProvisioningProfileCheckKey);
      expect(healthCheckResults[5].succeeded, false);
      expect(healthCheckResults[6].name, kBatteryLevelCheckKey);
      expect(healthCheckResults[6].succeeded, false);
    });
  });

  group('IosDeviceDiscovery - health checks', () {
    late IosDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    Process process;
    List<List<int>> output;

    setUp(() {
      processManager = MockProcessManager();
      deviceDiscovery = IosDeviceDiscovery(MemoryFileSystem().file('output'));
    });

    test('Keychain unlock check - success', () async {
      process = FakeProcess(0);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final healthCheckResult = await deviceDiscovery.keychainUnlockCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, true);
    });

    test('Keychain unlock check - exception', () async {
      process = FakeProcess(1);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final healthCheckResult = await deviceDiscovery.keychainUnlockCheck(
          processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kKeychainUnlockCheckKey);
      expect(healthCheckResult.details,
          'Executable $kUnlockLoginKeychain failed with exit code 1.');
    });

    test('Cert check - success', () async {
      final sb = StringBuffer();
      sb.writeln('1) abcdefg "Apple Development: Flutter Devicelab (hijklmn)"');
      sb.writeln('1 valid identities found');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final healthCheckResult =
          await deviceDiscovery.certCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, true);
    });

    test('Cert check - failure without target certificate', () async {
      final sb = StringBuffer();
      sb.writeln('abcdefg');
      sb.writeln('hijklmn');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final healthCheckResult =
          await deviceDiscovery.certCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kCertCheckKey);
      expect(healthCheckResult.details, sb.toString().trim());
    });

    test('Cert check - failure with multiple certificates', () async {
      final sb = StringBuffer();
      sb.writeln('1) abcdefg "Apple Development: Flutter Devicelab (hijklmn)"');

      sb.writeln('1) opqrst "uvwxyz"');
      sb.writeln('2 valid identities found');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final healthCheckResult =
          await deviceDiscovery.certCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kCertCheckKey);
      expect(healthCheckResult.details, sb.toString().trim());
    });

    test('Cert check - failure with revoked certificates', () async {
      final sb = StringBuffer();
      sb.writeln(
          '1) abcdefg "Apple Development: Flutter Devicelab (hijklmn)" (CSSMERR_TP_CERT_REVOKED)');
      sb.writeln('1 valid identities found');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final healthCheckResult =
          await deviceDiscovery.certCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kCertCheckKey);
      expect(healthCheckResult.details, sb.toString().trim());
    });

    test('Cert check - exception', () async {
      process = FakeProcess(1);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final healthCheckResult =
          await deviceDiscovery.certCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kCertCheckKey);
      expect(healthCheckResult.details,
          'Executable security failed with exit code 1.');
    });

    test('Device pair check - success', () async {
      final sb = StringBuffer();
      sb.writeln('SUCCESS: Validated pairing with device abcdefg-hijklmn');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final healthCheckResult =
          await deviceDiscovery.devicePairCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, true);
    });

    test('Device pair check - failure', () async {
      final sb = StringBuffer();
      sb.writeln('abcdefg');
      output = <List<int>>[utf8.encode(sb.toString())];
      process = FakeProcess(0, out: output);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final healthCheckResult =
          await deviceDiscovery.devicePairCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kDevicePairCheckKey);
      expect(healthCheckResult.details, sb.toString().trim());
    });

    test('Device pair check - exception', () async {
      process = FakeProcess(1);
      when(processManager.start(any,
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final healthCheckResult =
          await deviceDiscovery.devicePairCheck(processManager: processManager);
      expect(healthCheckResult.succeeded, false);
      expect(healthCheckResult.name, kDevicePairCheckKey);
      expect(healthCheckResult.details,
          'Executable idevicepair failed with exit code 1.');
    });

    group('Device provisioning profile check', () {
      Process lsProcess;
      Process securityProcess;
      List<List<int>> lsOutput;
      List<List<int>> securityOutput;
      test('success', () async {
        const fileName = 'abcdefg';
        lsOutput = <List<int>>[utf8.encode(fileName)];
        lsProcess = FakeProcess(0, out: lsOutput);

        const deviceID = 'deviceId';
        const profileContent = '''<array>
        <string>test1</string>
        <string>$deviceID</string>
        <string>test2</string>
        </array>
        ''';
        securityOutput = <List<int>>[utf8.encode(profileContent)];
        securityProcess = FakeProcess(0, out: securityOutput);

        final homeDir = Platform.environment['HOME'];
        when(
          processManager.start(
            <Object>[
              'ls',
              '$homeDir/Library/MobileDevice/Provisioning Profiles'
            ],
            workingDirectory: anyNamed('workingDirectory'),
          ),
        ).thenAnswer((_) => Future.value(lsProcess));
        when(
          processManager.start(
            <Object>[
              'security',
              'cms',
              '-D',
              '-i',
              '$homeDir/Library/MobileDevice/Provisioning Profiles/$fileName'
            ],
            workingDirectory: anyNamed('workingDirectory'),
          ),
        ).thenAnswer((_) => Future.value(securityProcess));

        final healthCheckResult =
            await deviceDiscovery.deviceProvisioningProfileCheck(deviceID,
                processManager: processManager);
        expect(healthCheckResult.succeeded, true);
        expect(healthCheckResult.name, kDeviceProvisioningProfileCheckKey);
      });

      test('deviceId does not exist', () async {
        const fileName = 'abcdefg';
        lsOutput = <List<int>>[utf8.encode(fileName)];
        lsProcess = FakeProcess(0, out: lsOutput);

        const deviceID = 'deviceId';
        const profileContent = '''<array>
        <string>test1</string>
        <string>test2</string>
        </array>
        ''';
        securityOutput = <List<int>>[utf8.encode(profileContent)];
        securityProcess = FakeProcess(0, out: securityOutput);

        final homeDir = Platform.environment['HOME'];
        when(
          processManager.start(
            <Object>[
              'ls',
              '$homeDir/Library/MobileDevice/Provisioning Profiles'
            ],
            workingDirectory: anyNamed('workingDirectory'),
          ),
        ).thenAnswer((_) => Future.value(lsProcess));
        when(
          processManager.start(
            <Object>[
              'security',
              'cms',
              '-D',
              '-i',
              '$homeDir/Library/MobileDevice/Provisioning Profiles/$fileName'
            ],
            workingDirectory: anyNamed('workingDirectory'),
          ),
        ).thenAnswer((_) => Future.value(securityProcess));

        final healthCheckResult =
            await deviceDiscovery.deviceProvisioningProfileCheck(deviceID,
                processManager: processManager);
        expect(healthCheckResult.succeeded, false);
        expect(healthCheckResult.name, kDeviceProvisioningProfileCheckKey);
        expect(healthCheckResult.details,
            'device does not exist in the provisioning profile');
      });
    });

    group('Device battery check', () {
      Process process;
      List<List<int>> output;
      test('battery level is okay', () async {
        const batteryLevel = '100';
        output = <List<int>>[utf8.encode(batteryLevel)];
        process = FakeProcess(0, out: output);

        when(
          processManager.start(
            <Object>[
              'ideviceinfo',
              '-q',
              'com.apple.mobile.battery',
              '-k',
              'BatteryCurrentCapacity'
            ],
            workingDirectory: anyNamed('workingDirectory'),
          ),
        ).thenAnswer((_) => Future.value(process));

        final healthCheckResult = await deviceDiscovery.batteryLevelCheck(
            processManager: processManager);
        expect(healthCheckResult.succeeded, true);
        expect(healthCheckResult.name, kBatteryLevelCheckKey);
      });

      test('battery level is below minLevel', () async {
        const batteryLevel = '10';
        output = <List<int>>[utf8.encode(batteryLevel)];
        process = FakeProcess(0, out: output);

        when(
          processManager.start(
            <Object>[
              'ideviceinfo',
              '-q',
              'com.apple.mobile.battery',
              '-k',
              'BatteryCurrentCapacity'
            ],
            workingDirectory: anyNamed('workingDirectory'),
          ),
        ).thenAnswer((_) => Future.value(process));

        final healthCheckResult = await deviceDiscovery.batteryLevelCheck(
            processManager: processManager);
        expect(healthCheckResult.succeeded, false);
        expect(healthCheckResult.name, kBatteryLevelCheckKey);
        expect(healthCheckResult.details,
            'Battery level ($batteryLevel) is below 15');
      });
    });
  });

  group('IosDevice recovery checks', () {
    IosDevice device;
    late MockProcessManager processManager;
    Process process;
    Process whichProcess;
    String output;
    String ideviceinstallerPath;
    String idevicediagnosticsPath;

    setUp(() {
      processManager = MockProcessManager();
    });
    test('device restart - success', () async {
      idevicediagnosticsPath = '/abc/def/idevicediagnostics';
      whichProcess =
          FakeProcess(0, out: <List<int>>[utf8.encode(idevicediagnosticsPath)]);
      when(
        processManager.start(<String>['which', 'idevicediagnostics'],
            workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((_) => Future.value(whichProcess));
      process = FakeProcess(0);
      device = const IosDevice(deviceId: 'abc');
      when(
        processManager.start(<Object>[idevicediagnosticsPath, 'restart'],
            workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((_) => Future.value(process));
      final result = await device.restartDevice(processManager: processManager);
      expect(result, isTrue);
    });

    test('device restart - failure', () async {
      idevicediagnosticsPath = '/abc/def/idevicediagnostics';
      whichProcess =
          FakeProcess(0, out: <List<int>>[utf8.encode(idevicediagnosticsPath)]);
      when(
        processManager.start(<String>['which', 'idevicediagnostics'],
            workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((_) => Future.value(whichProcess));
      process = FakeProcess(1);
      device = const IosDevice(deviceId: 'abc');
      when(
        processManager.start(<Object>[idevicediagnosticsPath, 'restart'],
            workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((_) => Future.value(process));
      final result = await device.restartDevice(processManager: processManager);
      expect(result, isFalse);
    });

    test('device restart - skip 32 bit phone', () async {
      device =
          const IosDevice(deviceId: '822ef7958bba573829d85eef4df6cbdd86593730');
      final result = await device.restartDevice(processManager: processManager);
      expect(result, isTrue);
    });

    test('list applications - failure', () async {
      device =
          const IosDevice(deviceId: '822ef7958bba573829d85eef4df6cbdd86593730');
      process = FakeProcess(1);
      ideviceinstallerPath = '/abc/def/ideviceinstaller';
      whichProcess =
          FakeProcess(0, out: <List<int>>[utf8.encode(ideviceinstallerPath)]);
      when(processManager.start(<String>['which', 'ideviceinstaller'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(whichProcess));
      when(processManager.start(<Object>[ideviceinstallerPath, '-l'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      final result =
          await device.uninstallApplications(processManager: processManager);
      expect(result, isFalse);
    });

    test('uninstall applications - no device is available', () async {
      ideviceinstallerPath = '/abc/def/ideviceinstaller';
      device =
          const IosDevice(deviceId: '822ef7958bba573829d85eef4df6cbdd86593730');
      output = '''No device found.
        ''';
      process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);
      whichProcess =
          FakeProcess(0, out: <List<int>>[utf8.encode(ideviceinstallerPath)]);
      when(processManager.start(<String>['which', 'ideviceinstaller'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(whichProcess));
      when(processManager.start(<Object>[ideviceinstallerPath, '-l'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      final result =
          await device.uninstallApplications(processManager: processManager);
      expect(result, isTrue);
    });

    test('uninstall applications - no application exist', () async {
      ideviceinstallerPath = '/abc/def/ideviceinstaller';
      device =
          const IosDevice(deviceId: '822ef7958bba573829d85eef4df6cbdd86593730');
      output = '''CFBundleIdentifier, CFBundleVersion, CFBundleDisplayName
        ''';
      process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);
      whichProcess =
          FakeProcess(0, out: <List<int>>[utf8.encode(ideviceinstallerPath)]);
      when(processManager.start(<String>['which', 'ideviceinstaller'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(whichProcess));
      when(processManager.start(<Object>[ideviceinstallerPath, '-l'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));

      final result =
          await device.uninstallApplications(processManager: processManager);
      expect(result, isTrue);
    });

    test('uninstall applications - applications exist with exception',
        () async {
      ideviceinstallerPath = '/abc/def/ideviceinstaller';
      device =
          const IosDevice(deviceId: '822ef7958bba573829d85eef4df6cbdd86593730');
      whichProcess =
          FakeProcess(0, out: <List<int>>[utf8.encode(ideviceinstallerPath)]);
      output = '''CFBundleIdentifier, CFBundleVersion, CFBundleDisplayName
        abc, def, ghi
        jkl, mno, pqr
        ''';
      process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);
      Process processUninstall = FakeProcess(1);
      when(processManager.start(<String>['which', 'ideviceinstaller'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(whichProcess));
      when(processManager.start(<Object>[ideviceinstallerPath, '-l'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      when(
        processManager.start(<Object>[ideviceinstallerPath, '-U', 'abc'],
            workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((_) => Future.value(processUninstall));
      when(
        processManager.start(<Object>[ideviceinstallerPath, '-U', 'jkl'],
            workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((_) => Future.value(processUninstall));

      output = '''CFBundleIdentifier, CFBundleVersion, CFBundleDisplayName
        abc, def, ghi
        jkl, mno, pqr
        ''';
      process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);
      processUninstall = FakeProcess(1);

      final result =
          await device.uninstallApplications(processManager: processManager);
      expect(result, isFalse);
    });

    test('uninstall applications - applications exist', () async {
      ideviceinstallerPath = '/abc/def/ideviceinstaller';
      device =
          const IosDevice(deviceId: '822ef7958bba573829d85eef4df6cbdd86593730');
      whichProcess =
          FakeProcess(0, out: <List<int>>[utf8.encode(ideviceinstallerPath)]);
      output = '''CFBundleIdentifier, CFBundleVersion, CFBundleDisplayName
        abc, def, ghi
        jkl, mno, pqr
        ''';
      process = FakeProcess(0, out: <List<int>>[utf8.encode(output)]);
      final Process processUninstall = FakeProcess(0);
      when(processManager.start(<String>['which', 'ideviceinstaller'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(whichProcess));
      when(processManager.start(<Object>[ideviceinstallerPath, '-l'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(process));
      when(
        processManager.start(<Object>[ideviceinstallerPath, '-U', 'abc'],
            workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((_) => Future.value(processUninstall));
      when(
        processManager.start(<Object>[ideviceinstallerPath, '-U', 'jkl'],
            workingDirectory: anyNamed('workingDirectory')),
      ).thenAnswer((_) => Future.value(processUninstall));

      final result =
          await device.uninstallApplications(processManager: processManager);
      expect(result, isTrue);
    });
  });

  group('deviceListOutput', () {
    late IosDeviceDiscovery deviceDiscovery;
    late MockProcessManager processManager;
    Process processIdeviceID;
    Process processWhichIdeviceID;

    setUp(() {
      processManager = MockProcessManager();
      deviceDiscovery = IosDeviceDiscovery(MemoryFileSystem().file('output'));
    });

    test('success', () async {
      processIdeviceID = FakeProcess(0, out: <List<int>>[utf8.encode('abc')]);
      processWhichIdeviceID =
          FakeProcess(0, out: <List<int>>[utf8.encode('/test/idevice_id')]);
      when(processManager.start(<String>['which', 'idevice_id'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(processWhichIdeviceID));
      when(processManager.start(<String>['/test/idevice_id', '-l'],
              workingDirectory: anyNamed('workingDirectory')))
          .thenAnswer((_) => Future.value(processIdeviceID));
      final deviceId = await deviceDiscovery.deviceListOutput(
          processManager: processManager);
      expect(deviceId, 'abc');
    });
  });
}
