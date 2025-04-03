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
import 'package:platform/platform.dart';

import 'package:test/test.dart';

import 'utils.dart';

Future<void> main() async {
  for (final deviceName in const <String>[
    'iPhone',
    'iPhone 11',
    "Flutter's iOS Phone",
  ]) {
    test(
      'ios_debug_symbol_doctor surfaces "Fetching debug symbols" error messages for "$deviceName"',
      () {
        final devices = XCDevice.parseJson(_jsonWithErrors(deviceName));
        final erroredDevices = devices.where((XCDevice device) {
          return device.hasError;
        });
        expect(erroredDevices, hasLength(1));
        final erroredDevice = erroredDevices.single;
        expect(erroredDevice.error!['code'], -10);
        expect(erroredDevice.error!['failureReason'], isEmpty);
        expect(
          erroredDevice.error!['description'],
          '$deviceName is busy: Fetching debug symbols for $deviceName',
        );
        expect(
          erroredDevice.error!['recoverySuggestion'],
          'Xcode will continue when $deviceName is finished.',
        );
        expect(erroredDevice.error!['domain'], 'com.apple.platform.iphoneos');
      },
    );

    test(
      'ios_debug_symbol_doctor surfaces "Preparing $deviceName for development" error message',
      () {
        final devices = XCDevice.parseJson(
          _jsonWithPreparingErrors(deviceName),
        );
        final erroredDevices = devices.where((XCDevice device) {
          return device.hasError;
        });
        expect(erroredDevices, hasLength(1), reason: devices.toString());
        final erroredDevice = erroredDevices.single;
        expect(erroredDevice.error!['code'], -10);
        expect(erroredDevice.error!['failureReason'], isEmpty);
        expect(
          erroredDevice.error!['description'],
          contains(
            '$deviceName is busy: Preparing $deviceName for development',
          ),
        );
        expect(
          erroredDevice.error!['recoverySuggestion'],
          'Xcode will continue when $deviceName is finished.',
        );
        expect(erroredDevice.error!['domain'], 'com.apple.platform.iphoneos');
      },
    );
  }

  test('XCDevice ignores "phone is locked" errors', () {
    final devices = XCDevice.parseJson(_jsonWithNonFatalErrors);
    final erroredDevices = devices.where((XCDevice device) {
      return device.hasError;
    });
    expect(erroredDevices, isEmpty);
  });

  CommandRunner<bool> createTestRunner() {
    return CommandRunner('ios-debug-symbol-doctor', 'for testing');
  }

  group('commands', () {
    late MockProcessManager processManager;
    late TestLogger logger;
    const cocoonPath = '/path/to/cocoon';
    const xcworkspacePath =
        '$cocoonPath/dashboard/ios/Runner.xcodeproj/project.xcworkspace';
    late MemoryFileSystem fs;
    late Platform platform;
    const deviceSupportDirectory =
        '/User/username/Library/Developer/Xcode/iOS DeviceSupport';

    setUp(() {
      processManager = MockProcessManager();
      logger = TestLogger();
      fs = MemoryFileSystem();
      fs.directory(xcworkspacePath).createSync(recursive: true);
      platform = MockPlatform();
      platform.environment['HOME'] = '/User/username';
    });

    test('diagnose logs output of xcdevice list', () async {
      when(
        processManager.run(<String>['xcrun', 'xcdevice', 'list']),
      ).thenAnswer((_) async {
        return ProcessResult(0, 0, _jsonWithNonFatalErrors, '');
      });
      final runner = createTestRunner();
      final command = DiagnoseCommand(
        processManager: processManager,
        loggerOverride: logger,
      );
      runner.addCommand(command);
      await runner.run(<String>['diagnose']);
      expect(logger.logs[Level.INFO], contains(_jsonWithNonFatalErrors));
    });

    test(
      'recover returns early if xcodebuild -runFirstLaunch exits non-zero',
      () async {
        final Directory symbolsDirectory = fs.directory(
          '/User/username/Library/Developer/Xcode/iOS Temp',
        );
        symbolsDirectory.createSync(recursive: true);
        when(
          processManager.run(<String>[
            'xcrun',
            'xcodebuild',
            '-runFirstLaunch',
          ]),
        ).thenAnswer((_) async {
          return ProcessResult(
            0,
            1,
            '',
            'xcrun: error: invalid active developer path (/Library/Developer/CommandLineTools), missing xcrun at: /Library/Developer/CommandLineTools/usr/bin/xcrun',
          );
        });

        fakeAsync<void>((FakeAsync time) {
          final runner = createTestRunner();
          final command = RecoverCommand(
            processManager: processManager,
            loggerOverride: logger,
            fs: fs,
            platform: platform,
          );
          runner.addCommand(command);
          bool? result;
          unawaited(
            runner
                .run(<String>['recover', '--cocoon-root=$cocoonPath'])
                .then((bool? value) => result = value),
          );
          time.elapse(const Duration(microseconds: 1));
          expect(result, isNotNull);
        });
      },
    );

    test(
      'recover deletes symbols, opens Xcode, waits, then kills it',
      () async {
        final Directory symbolsDirectory = fs.directory(deviceSupportDirectory);
        symbolsDirectory.createSync(recursive: true);
        when(
          processManager.run(<String>[
            'xcrun',
            'xcodebuild',
            '-runFirstLaunch',
          ]),
        ).thenAnswer((_) async {
          return ProcessResult(0, 0, '', '');
        });
        when(
          processManager.run(<String>[
            'open',
            '-n',
            '-F',
            '-W',
            xcworkspacePath,
          ]),
        ).thenAnswer((_) async {
          return ProcessResult(1, 0, '', '');
        });
        var killedXcode = false;
        when(processManager.run(<String>['killall', '-9', 'Xcode'])).thenAnswer(
          (_) async {
            killedXcode = true;
            return ProcessResult(2, 0, '', '');
          },
        );
        final result = fakeAsync<bool>((FakeAsync time) {
          final runner = createTestRunner();
          final command = RecoverCommand(
            processManager: processManager,
            loggerOverride: logger,
            fs: fs,
            platform: platform,
          );
          runner.addCommand(command);
          bool? result;
          unawaited(
            runner
                .run(<String>['recover', '--cocoon-root=$cocoonPath'])
                .then((bool? value) => result = value),
          );
          time.elapse(const Duration(seconds: 299));
          // We have not yet reached the timeout, so Xcode should still be open
          expect(result, isNull);
          expect(killedXcode, isFalse);
          time.elapse(const Duration(seconds: 2));
          expect(result, isNotNull);
          expect(killedXcode, isTrue);
          expect(logger.logs[Level.WARNING], isNull);
          expect(symbolsDirectory.existsSync(), false);

          return result!;
        });
        expect(result, isTrue);
        expect(
          logger.logs[Level.INFO],
          containsAllInOrder(<String>[
            'Running Xcode first launch...',
            'Launching Xcode...',
            'Waiting for 300 seconds',
            'Waited for 300 seconds, now killing Xcode',
          ]),
        );
      },
    );

    test(
      'recover cannot find symbols but still opens Xcode, waits, then kills it',
      () async {
        when(
          processManager.run(<String>[
            'xcrun',
            'xcodebuild',
            '-runFirstLaunch',
          ]),
        ).thenAnswer((_) async {
          return ProcessResult(0, 0, '', '');
        });
        when(
          processManager.run(<String>[
            'open',
            '-n',
            '-F',
            '-W',
            xcworkspacePath,
          ]),
        ).thenAnswer((_) async {
          return ProcessResult(1, 0, '', '');
        });
        var killedXcode = false;
        when(processManager.run(<String>['killall', '-9', 'Xcode'])).thenAnswer(
          (_) async {
            killedXcode = true;
            return ProcessResult(2, 0, '', '');
          },
        );
        final result = fakeAsync<bool>((FakeAsync time) {
          final runner = createTestRunner();
          final command = RecoverCommand(
            processManager: processManager,
            loggerOverride: logger,
            fs: fs,
            platform: platform,
          );
          runner.addCommand(command);
          bool? result;
          unawaited(
            runner
                .run(<String>['recover', '--cocoon-root=$cocoonPath'])
                .then((bool? value) => result = value),
          );
          time.elapse(const Duration(seconds: 299));
          // We have not yet reached the timeout, so Xcode should still be open
          expect(result, isNull);
          expect(killedXcode, isFalse);
          time.elapse(const Duration(seconds: 2));
          expect(result, isNotNull);
          expect(killedXcode, isTrue);
          expect(
            logger.logs[Level.WARNING],
            contains(
              'iOS Device Support directory was not found at $deviceSupportDirectory',
            ),
          );
          return result!;
        });
        expect(result, isTrue);
        expect(
          logger.logs[Level.INFO],
          containsAllInOrder(<String>[
            'Running Xcode first launch...',
            'Launching Xcode...',
            'Waiting for 300 seconds',
            'Waited for 300 seconds, now killing Xcode',
          ]),
        );
      },
    );
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

String _jsonWithErrors(String name) => '''
[
  {
    "modelCode" : "iPhone8,1",
    "simulator" : false,
    "modelName" : "iPhone 6s",
    "error" : {
      "code" : -10,
      "failureReason" : "",
      "description" : "$name is busy: Fetching debug symbols for $name",
      "recoverySuggestion" : "Xcode will continue when $name is finished.",
      "domain" : "com.apple.platform.iphoneos"
    },
    "operatingSystemVersion" : "15.1 (19B74)",
    "identifier" : "e3f3a0cf8005b8b34f14d16fa224b19017648353",
    "platform" : "com.apple.platform.iphoneos",
    "architecture" : "arm64",
    "interface" : "usb",
    "available" : false,
    "name" : "$name",
    "modelUTI" : "com.apple.iphone-6s-e1ccb7"
  }
]
''';

String _jsonWithPreparingErrors(String name) => '''
[
  {
    "modelCode" : "iPhone8,1",
    "simulator" : false,
    "modelName" : "iPhone 6s",
    "error" : {
      "code" : -10,
      "failureReason" : "",
      "description" : "$name is busy: Preparing $name for development. Xcode will continue when $name is finished. (code -10)",
      "recoverySuggestion" : "Xcode will continue when $name is finished.",
      "domain" : "com.apple.platform.iphoneos"
    },
    "operatingSystemVersion" : "15.1 (19B74)",
    "identifier" : "e3f3a0cf8005b8b34f14d16fa224b19017648353",
    "platform" : "com.apple.platform.iphoneos",
    "architecture" : "arm64",
    "interface" : "usb",
    "available" : false,
    "name" : "$name",
    "modelUTI" : "com.apple.iphone-6s-e1ccb7"
  }
]
''';
