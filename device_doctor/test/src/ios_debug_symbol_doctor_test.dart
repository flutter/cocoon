// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:device_doctor/src/ios_debug_symbol_doctor.dart';
import 'package:fake_async/fake_async.dart';
import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:mockito/mockito.dart';

import 'package:test/test.dart';

import 'utils.dart';

Future<void> main() async {
  test('XCDevice surfaces "Fetching debug symbols" error messages', () {
    final Iterable<XCDevice> devices = XCDevice.parseJson(_jsonWithErrors);
    final Iterable<XCDevice> erroredDevices = devices.where((XCDevice device) {
      return device.hasError;
    });
    expect(erroredDevices, hasLength(1));
    final XCDevice erroredDevice = erroredDevices.single;
    expect(erroredDevice.error!['code'], -10);
    expect(erroredDevice.error!['failureReason'], isEmpty);
    expect(erroredDevice.error!['description'], 'iPhone is busy: Fetching debug symbols for iPhone');
    expect(erroredDevice.error!['recoverySuggestion'], 'Xcode will continue when iPhone is finished.');
    expect(erroredDevice.error!['domain'], 'com.apple.platform.iphoneos');
  });

  test('XCDevice ignores "phone is locked" errors', () {
    final Iterable<XCDevice> devices = XCDevice.parseJson(_jsonWithNonFatalErrors);
    final Iterable<XCDevice> erroredDevices = devices.where((XCDevice device) {
      return device.hasError;
    });
    expect(erroredDevices, isEmpty);
  });

  CommandRunner<bool> _createTestRunner() {
    return CommandRunner(
      'ios-debug-symbol-doctor',
      'for testing',
    );
  }

  group('commands', () {
    late MockProcessManager processManager;
    late TestLogger logger;
    const String cocoonPath = '/path/to/cocoon';
    const String xcworkspacePath = '$cocoonPath/dashboard/ios/Runner.xcodeproj/project.xcworkspace';
    late MemoryFileSystem fs;

    setUp(() {
      processManager = MockProcessManager();
      logger = TestLogger();
      fs = MemoryFileSystem();
      fs.directory(xcworkspacePath).createSync(recursive: true);
    });

    test('diagnose logs output of xcdevice list', () async {
      when(
        processManager.run(<String>['xcrun', 'xcdevice', 'list']),
      ).thenAnswer((_) async {
        return ProcessResult(0, 0, _jsonWithNonFatalErrors, '');
      });
      final CommandRunner<bool> runner = _createTestRunner();
      final command = DiagnoseCommand(
        processManager: processManager,
        loggerOverride: logger,
      );
      runner.addCommand(command);
      await runner.run(<String>['diagnose']);
      expect(logger.logs[Level.INFO], contains(_jsonWithNonFatalErrors));
    });

    test('recover opens Xcode, waits, then kills it', () async {
      when(
        processManager.run(<String>['open', '-n', '-F', '-W', xcworkspacePath]),
      ).thenAnswer((_) async {
        return ProcessResult(1, 0, '', '');
      });
      bool killedXcode = false;
      when(
        processManager.run(<String>['killall', '-9', 'Xcode']),
      ).thenAnswer((_) async {
        killedXcode = true;
        return ProcessResult(2, 0, '', '');
      });
      final bool result = fakeAsync<bool>((FakeAsync time) {
        final CommandRunner<bool> runner = _createTestRunner();
        final command = RecoverCommand(
          processManager: processManager,
          loggerOverride: logger,
          fs: fs,
        );
        runner.addCommand(command);
        bool? result;
        runner.run(<String>['recover', '--cocoon-root=$cocoonPath']).then((bool? value) => result = value);
        time.elapse(const Duration(seconds: 299));
        // We have not yet reached the timeout, so Xcode should still be open
        expect(result, isNull);
        expect(killedXcode, isFalse);
        time.elapse(const Duration(seconds: 2));
        expect(result, isNotNull);
        expect(killedXcode, isTrue);
        return result!;
      });
      expect(result, isTrue);
      expect(
        logger.logs[Level.INFO],
        containsAllInOrder(<String>[
          'Launching Xcode...',
          'Waiting for 300 seconds',
          'Waited for 300 seconds, now killing Xcode',
        ]),
      );
    });
  });
}

const String _jsonWithNonFatalErrors = '''
[
  {
    "modelCode" : "iPhone11,8",
    "simulator" : false,
    "modelName" : "iPhone XR",
    "error" : {
      "code" : -13,
      "failureReason" : "",
      "underlyingErrors" : [
        {
          "code" : 4,
          "failureReason" : "",
          "description" : "Flutter’s iPhone is locked.",
          "recoverySuggestion" : "To use Flutter’s iPhone with Xcode, unlock it.",
          "domain" : "DVTDeviceIneligibilityErrorDomain"
        }
      ],
      "description" : "Flutter’s iPhone is not connected",
      "recoverySuggestion" : "Xcode will continue when Flutter’s iPhone is connected.",
      "domain" : "com.apple.platform.iphoneos"
    },
    "operatingSystemVersion" : "15.4.1 (19E258)",
    "identifier" : "00008120-00017DA80CC1002E",
    "platform" : "com.apple.platform.iphoneos",
    "architecture" : "arm64e",
    "interface" : "usb",
    "available" : false,
    "name" : "Flutter’s iPhone",
    "modelUTI" : "com.apple.iphone-xr-9"
  }
]''';

const String _jsonWithErrors = '''
[
  {
    "modelCode" : "iPhone8,1",
    "simulator" : false,
    "modelName" : "iPhone 6s",
    "error" : {
      "code" : -10,
      "failureReason" : "",
      "description" : "iPhone is busy: Fetching debug symbols for iPhone",
      "recoverySuggestion" : "Xcode will continue when iPhone is finished.",
      "domain" : "com.apple.platform.iphoneos"
    },
    "operatingSystemVersion" : "15.1 (19B74)",
    "identifier" : "e3f3a0cf8005b8b34f14d16fa224b19017648353",
    "platform" : "com.apple.platform.iphoneos",
    "architecture" : "arm64",
    "interface" : "usb",
    "available" : false,
    "name" : "iPhone",
    "modelUTI" : "com.apple.iphone-6s-e1ccb7"
  }
]
''';
