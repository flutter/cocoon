// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:args/command_runner.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:process/process.dart';
import 'package:logging/logging.dart';

class DiagnoseCommand extends Command<bool> {
  DiagnoseCommand({
    this.processManager = const LocalProcessManager(),
    Logger? loggerOverride,
  }) : logger = loggerOverride ?? Logger.root;

  final Logger logger;

  final ProcessManager processManager;

  final String name = 'diagnose';
  final String description = 'Diagnose whether attached iOS devices have errors.';

  Future<bool> run() async {
    await checkDevToolsSecurity();

    final List<String> command = <String>['xcrun', 'xcdevice', 'list'];
    final io.ProcessResult result = await processManager.run(
      command,
    );
    if (result.exitCode != 0) {
      logger.severe(
        '$command failed with exit code ${result.exitCode}\n${result.stderr}',
      );
      return false;
    }
    final String stdout = result.stdout as String;
    logger.info(stdout);
    final Iterable<XCDevice> devices = XCDevice.parseJson(stdout);
    final Iterable<XCDevice> devicesWithErrors = devices.where((XCDevice device) => device.hasError);

    if (devicesWithErrors.isNotEmpty) {
      logger.severe('Found devices with errors!');

      for (final XCDevice device in devicesWithErrors) {
        logger.severe('${device.name}: ${device.error}');
      }
      return false;
    }

    return true;
  }

  /// Log the status of DevToolsSecurity.
  Future<void> checkDevToolsSecurity() async {
    final List<String> command = <String>['xcrun', 'DevToolsSecurity', '--status'];
    final io.ProcessResult result = await processManager.run(
      command,
    );
    if (result.exitCode != 0) {
      logger.severe(
        '$command failed with exit code ${result.exitCode}\n${result.stderr}',
      );
    }
    final String stdout = result.stdout as String;
    logger.info(stdout);
  }
}

class RecoverCommand extends Command<bool> {
  RecoverCommand({
    this.processManager = const LocalProcessManager(),
    Logger? loggerOverride,
    this.fs = const LocalFileSystem(),
  }) : logger = loggerOverride ?? Logger.root {
    argParser
      ..addOption(
        'cocoon-root',
        help: 'Path to the root of the Cocoon repo. This is used to find the Build dashboard macos project, which is '
            'then used to open Xcode.',
        mandatory: true,
      )
      ..addOption(
        'timeout',
        help: 'Integer number of seconds to allow Xcode to run before killing it.',
        defaultsTo: '300',
      );
  }

  final Logger logger;
  final ProcessManager processManager;
  final FileSystem fs;

  final String name = 'recover';
  final String description = 'Open Xcode UI to allow it to sync debug symbols from the iPhone';

  /// Xcode Project workspace file for the build dashboard Flutter app.
  ///
  /// Should be located at //cocoon/dashboard/ios/Runner.xcodeproj/project.xcworkspace.
  Directory get dashboardXcWorkspace {
    final String cocoonRootPath = argResults!['cocoon-root'];
    final Directory cocoonRoot = fs.directory(cocoonRootPath);
    final Directory dashboardXcWorkspace = cocoonRoot
        .childDirectory('dashboard')
        .childDirectory('ios')
        .childDirectory('Runner.xcodeproj')
        .childDirectory('project.xcworkspace')
        .absolute;
    if (!dashboardXcWorkspace.existsSync()) {
      throw StateError(
        'You provided the --cocoon-root option with "$cocoonRootPath", and the device doctor tried to '
        "locate the build dashboard's project.xcworkspace directory at \"${dashboardXcWorkspace.path}\" "
        'but that path does not exist on disk.',
      );
    }
    return dashboardXcWorkspace;
  }

  @override
  Future<bool> run() async {
    final int? timeoutSeconds = int.tryParse(argResults!['timeout']);
    if (timeoutSeconds == null) {
      throw ArgumentError('Could not parse an integer from the option --timeout="${argResults!['timeout']}"');
    }

    // Prompt Xcode to first setup without opening the app.
    // This will return very quickly if there is no work to do.
    logger.info('Running Xcode first launch...');
    final io.ProcessResult runFirstLaunchResult = await processManager.run(<String>[
      'xcrun',
      'xcodebuild',
      '-runFirstLaunch',
    ]);
    final String runFirstLaunchStdout = runFirstLaunchResult.stdout.trim();
    if (runFirstLaunchStdout.isNotEmpty) {
      logger.info('stdout from `xcodebuild -runFirstLaunch`:\n$runFirstLaunchStdout\n');
    }
    final String runFirstLaunchStderr = runFirstLaunchResult.stderr.trim();
    if (runFirstLaunchStderr.isNotEmpty) {
      logger.info('stderr from `xcodebuild -runFirstLaunch`:\n$runFirstLaunchStderr\n');
    }
    final int runFirstLaunchCode = runFirstLaunchResult.exitCode;
    if (runFirstLaunchCode != 0) {
      logger.info('Failed running `xcodebuild -runFirstLaunch` with code $runFirstLaunchCode!');
      return false;
    }

    final Duration timeout = Duration(seconds: timeoutSeconds);
    logger.info('Launching Xcode...');
    final Future<io.ProcessResult> xcodeFuture = processManager.run(<String>[
      'open',
      '-n', // Opens a new instance of the application even if one is already running
      '-F', // Opens the application "fresh," without restoring windows
      '-W', // Wait for the opened application (Xcode) to close
      dashboardXcWorkspace.path,
    ]);

    unawaited(
      xcodeFuture.then((io.ProcessResult result) {
        logger.info('Open closed...');
        final String stdout = result.stdout.trim();
        if (stdout.isNotEmpty) {
          logger.info('stdout from `open`:\n$stdout\n');
        }
        final String stderr = result.stderr.trim();
        if (stderr.isNotEmpty) {
          logger.info('stderr from `open`:\n$stderr\n');
        }
        if (result.exitCode != 0) {
          throw Exception('Failed opening Xcode!');
        }
      }),
    );

    logger.info('Waiting for $timeoutSeconds seconds');
    await Future.delayed(timeout);
    logger.info('Waited for $timeoutSeconds seconds, now killing Xcode');
    final io.ProcessResult result = await processManager.run(<String>['killall', '-9', 'Xcode']);

    if (result.exitCode != 0) {
      logger.severe('Failed killing Xcode!');
      return false;
    }
    return true;
  }
}

/// A Device configuration as output by `xcrun xcdevice list`.
///
/// As more fields are needed, they can be added to this class. It is
/// recommended to make all fields nullable in case a different version of Xcode
/// does not implement it.
class XCDevice {
  const XCDevice._({
    required this.error,
    required this.name,
  });

  static const String _debugSymbolDescriptionPattern = r' is busy: Fetching debug symbols for ';
  static final RegExp _preparingPhoneForDevelopmentPattern = RegExp(
    r'Preparing .* for development\. Xcode will continue when .* is finished\.',
  );

  /// Parse subset of JSON from `parseJson` associated with a particular XCDevice.
  factory XCDevice.fromMap(Map<String, Object?> map) {
    final Map<String, Object?>? error = map['error'] as Map<String, Object?>?;
    // We should only specifically pattern match on known fatal errors, and
    // ignore the rest.
    bool validError = false;
    if (error != null) {
      final String description = error['description'] as String;
      if (description.contains(_debugSymbolDescriptionPattern) ||
          _preparingPhoneForDevelopmentPattern.hasMatch(description)) {
        validError = true;
      } else {
        print('not matching pattern: $description');
      }
    }
    return XCDevice._(
      error: validError ? error : null,
      name: map['name'] as String,
    );
  }

  final Map<String, Object?>? error;
  final String name;

  bool get hasError => error != null;

  /// Parse the complete output of `xcrun xcdevice list`.
  static Iterable<XCDevice> parseJson(String jsonString) {
    final List<Object?> devices = json.decode(jsonString) as List<Object?>;
    return devices.map<XCDevice>((Object? obj) {
      return XCDevice.fromMap(obj as Map<String, Object?>);
    });
  }
}
