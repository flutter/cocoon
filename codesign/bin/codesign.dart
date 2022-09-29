// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:codesign/codesign.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:platform/platform.dart';
import 'package:process/process.dart';

/// Definitions of variables are included in help texts below.
const String kHelpFlag = 'help';
const String kCommitOption = 'commit';
const String kDryrunFlag = 'dryrun';
const String kCodesignCertNameOption = 'codesign-cert-name';
const String kCodesignUserNameOption = 'codesign-username';
const String kAppSpecificPasswordOption = 'app-specific-password';
const String kCodesignAppStoreIdOption = 'codesign-appstore-id';
const String kCodesignTeamIdOption = 'codesign-team-id';
const String kCodesignFilepathOption = 'filepath';
const String kOptionalSwitch = 'optional-switch';

/// Perform Mac code signing based on file paths.
///
/// If [kDryrunFlag] is set to false, code signed artifacts will be uploaded
/// back to google cloud storage.
/// Otherwise, nothing will be uploaded back for dry run. default value is
/// true.
///
/// For [kCommitOption], provides the engine commit to be code signed.
///
/// For [kCodesignFilepathOption], provides the artifacts zip paths to be code signed.
///
/// For [kOptionalSwitch], it is an optional parameter that you can supply to code sign binaries other than flutter engine binaries.
/// The five options are: ios-deploy.zip, libimobiledevice.zip, libplist.zip, libusbmuxd.zip, openssl.zip.
///
/// Usage:
/// ```shell
/// dart run bin/main.dart --commit=$commitSha
/// ( add `--dryrun` if this is intended for dryrun)
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
    ..addOption(
      kCodesignCertNameOption,
      help: 'The name of the codesign certificate to be used when codesigning.'
          'the name of the certificate for flutter, for example, is: FLUTTER.IO LLC',
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
      kOptionalSwitch,
      help:
          'the list of binaries that are supported besides flutter engine binaries. e.g. ios-deploy.zip, libimobiledevice.zip, libplist.zip, libusbmuxd.zip, openssl.zip',
      allowed: ["ios-deploy.zip", "libimobiledevice.zip", "libplist.zip", "libusbmuxd.zip", "openssl.zip"],
      defaultsTo: <String>[],
    )
    ..addFlag(
      kDryrunFlag,
      help: 'whether we are going to upload the artifacts back to GCS for dryrun',
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
  final List<String> optionalSwitch = argResults[kOptionalSwitch] as List<String>;

  final bool dryrun = argResults[kDryrunFlag] as bool;

  if (!platform.isMacOS) {
    throw CodesignException(
      'Error! Expected operating system "macos", actual operating system is: '
      '"${platform.operatingSystem}"',
    );
  }

  const FileSystem fileSystem = LocalFileSystem();
  final Directory rootDirectory = fileSystem.systemTempDirectory.createTempSync('conductor_codesign');
  const ProcessManager processManager = LocalProcessManager();
  final GoogleCloudStorage googleCloudStorage = GoogleCloudStorage(
    processManager: processManager,
    rootDirectory: rootDirectory,
    commitHash: commit,
    optionalSwitch: optionalSwitch,
  );

  return FileCodesignVisitor(
    codesignCertName: codesignCertName,
    codesignUserName: codesignUserName,
    commitHash: commit,
    appSpecificPassword: appSpecificPassword,
    codesignAppstoreId: codesignAppstoreId,
    codesignTeamId: codesignTeamId,
    fileSystem: fileSystem,
    rootDirectory: rootDirectory,
    processManager: processManager,
    dryrun: dryrun,
    googleCloudStorage: googleCloudStorage,
  ).validateAll();
}
