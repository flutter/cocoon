// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:codesign/codesign.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:logging/logging.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

/// Definitions of variables are included in help texts below.
const String kHelpFlag = 'help';
const String kCommitOption = 'commit';
const String kProductionFlag = 'production';
const String kCodesignCertNameOption = 'codesign-cert-name';
const String kCodesignUserNameOption = 'codesign-username';
const String kAppSpecificPasswordOption = 'app-specific-password';
const String kCodesignAppStoreIdOption = 'codesign-appstore-id';
const String kCodesignTeamIdOption = 'codesign-team-id';
const String kCodesignFilepathOption = 'filepath';

/// Perform Mac code signing based on file paths.
///
/// If ```--production``` is set to true, code signed artifacts will be uploaded
/// back to google cloud storage.
/// Otherwise, nothing will be uploaded back for production. default value is
/// false.
///
/// For ```--commit```, asks for the engine commit to be code signed.
///
/// For ```--filepath```, provides the artifacts zip paths to be code signed.
///
/// Usage:
/// ```
/// dart run bin/main.dart --commit=$commitSha
/// --filepath=darwin-x64/FlutterMacOS.framework.zip --filepath=ios/artifacts.zip
/// --filepath=dart-sdk-darwin-arm64.zip
/// ( add `--production` if this is intended for production)
/// ```
Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser
    ..addFlag(kHelpFlag, help: 'Prints usage info.', callback: (bool value) {
      if (value) {
        stdout.write('${parser.usage}\n');
        exit(1);
      }
    })
    // e.g. FLUTTER.IO LLC
    ..addOption(
      kCodesignCertNameOption,
      help: 'The name of the codesign certificate to be used when codesigning.',
    )
    ..addOption(
      kAppSpecificPasswordOption,
      help: 'Unique password specifically for codesigning the given application.',
    )
    ..addOption(
      kCodesignAppStoreIdOption,
      help: 'Apple developer account email used for authentication with notary service.',
    )
    ..addOption(
      kCodesignTeamIdOption,
      help: 'Team-id is used by notary service for xcode version 13+.',
    )
    ..addOption(
      kCommitOption,
      help: 'the Flutter engine commit revision for which Google Cloud Storage binary artifacts should be codesigned.',
    )
    ..addMultiOption(
      kCodesignFilepathOption,
      help: 'The zip file paths to be codesigned. Pass this option multiple'
          'times to codesign multiple zip files',
      valueHelp: 'darwin-x64/font-subset.zip',
    )
    ..addFlag(
      kProductionFlag,
      help: 'whether we are going to upload the artifacts back to GCS for production',
    );

  final ArgResults argResults = parser.parse(args);

  const Platform platform = LocalPlatform();

  final String commit = getValueFromEnvOrArgs(kCommitOption, argResults, platform.environment)!;
  final String codesignCertName = getValueFromEnvOrArgs(kCodesignCertNameOption, argResults, platform.environment)!;
  final String codesignUserName = getValueFromEnvOrArgs(kCodesignUserNameOption, argResults, platform.environment)!;
  final String appSpecificPassword =
      getValueFromEnvOrArgs(kAppSpecificPasswordOption, argResults, platform.environment)!;
  final String codesignAppstoreId = getValueFromEnvOrArgs(kCodesignAppStoreIdOption, argResults, platform.environment)!;
  final String codesignTeamId = getValueFromEnvOrArgs(kCodesignTeamIdOption, argResults, platform.environment)!;

  final List<String> codesignFilepaths = argResults[kCodesignFilepathOption]!;
  final bool production = argResults[kProductionFlag] as bool;

  if (!platform.isMacOS) {
    throw CodesignException(
      'Error! Expected operating system "macos", actual operating system is: '
      '"${platform.operatingSystem}"',
    );
  }

  FileSystem fileSystem = const LocalFileSystem();
  Directory tempDir = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
  Logger logger = Logger('codesign-logger');
  ProcessManager processManager = const LocalProcessManager();

  return FileCodesignVisitor(
    codesignCertName: codesignCertName,
    codesignUserName: codesignUserName,
    commitHash: commit,
    appSpecificPassword: appSpecificPassword,
    codesignAppstoreId: codesignAppstoreId,
    codesignTeamId: codesignTeamId,
    codesignFilepaths: codesignFilepaths,
    fileSystem: fileSystem,
    logger: logger,
    tempDir: tempDir,
    processManager: processManager,
    visitDirectory: visitDirectory,
    production: production,
  ).validateAll();
}
