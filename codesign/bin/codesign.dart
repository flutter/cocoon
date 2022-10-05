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
const String kDryrunFlag = 'dryrun';
const String kCodesignCertNameOption = 'codesign-cert-name';
const String kCodesignUserNameOption = 'codesign-username';
const String kAppSpecificPasswordOption = 'app-specific-password';
const String kCodesignAppStoreIdOption = 'codesign-appstore-id';
const String kCodesignTeamIdOption = 'codesign-team-id';
const String kCodesignFilepathOption = 'filepath';
const String kGCloudDownloadPattern = 'google-cloud-download-pattern';
const String kGCloudUploadPattern = 'google-cloud-upload-pattern';

/// Perform Mac code signing based on file paths.
///
/// If [kDryrunFlag] is set to false, code signed artifacts will be uploaded
/// back to google cloud storage.
/// Otherwise, nothing will be uploaded back for dry run. default value is
/// true.
///
/// For [kCodesignFilepathOption], supply the filepaths of binaries to be codesigned.
/// e.g. supply `--filepath=darwin-x86/artifacts.zip --ios-release/artifacts.zip` if you would like to codesign darwin-x86/artifacts.zip and ios-release/artifacts.zip
///
/// For [kGCloudDownloadPattern], it is a required parameter to specify the google cloud bucket prefix of the artifacts stored in google cloud.
/// Artifacts stored with this bucket prefix path are downloaded from google cloud and codesigned.
/// For [kGCloudUploadPattern], it is a required parameter to specify the google cloud bucket prefix for the code signed artifacts to be uploaded to.
/// Code signed artifacts are uploaded to google cloud under this bucket prefix.
///
/// Usage:
/// ```shell
/// dart run bin/main.dart --commit=$commitSha [--dryrun]
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
      kGCloudDownloadPattern,
      help: 'A required pattern to specify the google cloud bucket prefix of the artifacts stored in google cloud. '
          'In a pattern, the word ARTIFACTRAWNAME will get replaced to the raw name of artifact without suffix or prefix, the word FILEPATH will get replaced to the artifact path\n'
          'For example, to code sign ios usb dependency artifacts ios-deploy.zip and libplist.zip, supply the pattern\n'
          '`--google-cloud-download-pattern = ios-usb-dependencies/unsigned/ARTIFACTRAWNAME/<commitHash>/FILEPATH`\n,'
          'and supply file path to be `--filepath = ios-deploy.zip --filepath = libplist.zip`\n'
          'when the program runs and signs ios-deploy.zip, the pattern will get auto replaced into ios-usb-dependencies/unsigned/ios-deploy/<commitHash>/ios-deploy.zip'
          'As another example, to code sign engine artifact darwin-x64/artifacts.zip, supply the pattern\n'
          '`--google-cloud-download-pattern = flutter/<commitHash>/FILEPATH`\n,'
          'and supply file path to be `--filepath = darwin-x64/artifacts.zip`\n'
          'when the program runs and signs darwin-x64/artifacts.zip, the pattern will get auto replaced into flutter/<commitHash>/darwin-x64/artifacts.zip',
    )
    ..addOption(
      kGCloudUploadPattern,
      help:
          'A required pattern to specify the google cloud bucket prefix for the code signed artifacts to be uploaded to. \n'
          'In a pattern, the word ARTIFACTRAWNAME will get replaced to the raw name of artifact without suffix or prefix, the word FILEPATH will get replaced to the artifact path\n'
          'For example, to upload an ios usb dependency artifact, supply the pattern\n'
          '`--google-cloud-upload-pattern = ios-usb-dependencies/ARTIFACTRAWNAME/<commitHash>/FILEPATH`\n'
          'and supply file path to be something like `--filepath = libimobiledevice.zip --filepath = openssl.zip` depending on user needs\n'
          'when the program runs and uploads libimobiledevice.zip, the pattern will get auto replaced into ios-usb-dependencies/libimobiledevice/<commitHash>/libimobiledevice.zip',
    )
    ..addMultiOption(
      kCodesignFilepathOption,
      help: 'the list of file paths of binaries to be codesigned. \n'
          'e.g. supply `--filepath=darwin-x86/artifacts.zip --ios-release/artifacts.zip` if you would like to codesign darwin-x86/artifacts.zip and ios-release/artifacts.zip',
      defaultsTo: <String>[],
    )
    ..addFlag(
      kDryrunFlag,
      help: 'whether we are going to upload the artifacts back to GCS for dryrun',
    );

  final ArgResults argResults = parser.parse(args);

  const Platform platform = LocalPlatform();

  final String codesignCertName = getValueFromEnvOrArgs(kCodesignCertNameOption, argResults, platform.environment)!;
  final String codesignUserName = getValueFromEnvOrArgs(kCodesignUserNameOption, argResults, platform.environment)!;
  final String appSpecificPassword =
      getValueFromEnvOrArgs(kAppSpecificPasswordOption, argResults, platform.environment)!;
  final String codesignAppstoreId = getValueFromEnvOrArgs(kCodesignAppStoreIdOption, argResults, platform.environment)!;
  final String codesignTeamId = getValueFromEnvOrArgs(kCodesignTeamIdOption, argResults, platform.environment)!;
  final String gCloudDownloadPattern = getValueFromEnvOrArgs(kGCloudDownloadPattern, argResults, platform.environment)!;
  final String gCloudUploadPattern = getValueFromEnvOrArgs(kGCloudUploadPattern, argResults, platform.environment)!;
  final List<String> filePaths = argResults[kCodesignFilepathOption] as List<String>;

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
    gCloudDownloadPattern: gCloudDownloadPattern,
    gCloudUploadPattern: gCloudUploadPattern,
  );

  return FileCodesignVisitor(
    codesignCertName: codesignCertName,
    codesignUserName: codesignUserName,
    appSpecificPassword: appSpecificPassword,
    codesignAppstoreId: codesignAppstoreId,
    codesignTeamId: codesignTeamId,
    fileSystem: fileSystem,
    rootDirectory: rootDirectory,
    processManager: processManager,
    dryrun: dryrun,
    filePaths: filePaths,
    googleCloudStorage: googleCloudStorage,
  ).validateAll();
}
