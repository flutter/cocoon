// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
  final String description =
      'Diagnose whether attached iOS devices have errors.';

  Future<bool> run() async {
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
    final Iterable<XCDevice> devices =
        XCDevice.parseJson(result.stdout as String);
    final Iterable<XCDevice> devicesWithErrors =
        devices.where((XCDevice device) => device.hasError);

    if (devicesWithErrors.isNotEmpty) {
      logger.severe('Found devices with errors!');

      for (final XCDevice device in devicesWithErrors) {
        logger.severe('${device.name}: ${device.error}');
      }
      return false;
    }

    return true;
  }
}

class RecoverCommand extends Command<bool> {
  RecoverCommand({
    this.processManager = const LocalProcessManager(),
    Logger? loggerOverride,
    this.fs = const LocalFileSystem(),
  }) : logger = loggerOverride ?? Logger.root {
    argParser.addOption(
      'cocoon-root',
      help: 'Path to the root of the Cocoon repo. This is used to find the Build dashboard macos project, which is '
            'then used to open Xcode.',
      mandatory: true,
    );
  }

  final Logger logger;
  final ProcessManager processManager;
  final FileSystem fs;

  final String name = 'recover';
  final String description =
      'Open Xcode UI to allow it to sync debug symbols from the iPhone';

  @override
  Future<bool> run() async {
    final Directory cocoonRoot = fs.directory(argResults['cocoon-root']);
    final io.ProcessResult result = await processManager.run(<String>['open', xcodeDir.absolute.path]);
    if (result.exitCode != 0) {
      logger.severe('Failed opening Xcode!');
      return false;
    }
    const Duration timeout = Duration(minutes: 2);
    logger.info('Waiting for $timeout');
    await Future.delayed(timeout);
    // TODO kill Xcode
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

  static const String _debugSymbolDescriptionPattern =
      'iPhone is busy: Fetching debug symbols for iPhone';

  /// Parse subset of JSON from `parseJson` associated with a particular XCDevice.
  factory XCDevice.fromMap(Map<String, Object?> map) {
    Map<String, Object?>? error = map['error'] as Map<String, Object?>?;
    // We should only specifically pattern match on known fatal errors, and
    // ignore the rest.
    bool validError = false;
    if (error != null) {
      final String description = error['description'] as String;
      if (description.contains(_debugSymbolDescriptionPattern)) {
        validError = true;
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
