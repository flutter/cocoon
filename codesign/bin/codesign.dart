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
const String kCodesignCertNameOption = 'CODESIGN-CERT-NAME';
const String kCodesignUserNameOption = 'CODESIGN-USERNAME';
const String kGcsDownloadPathOption = 'GCS-DOWNLOAD-PATH';
const String kGcsUploadPathOption = 'GCS-UPLOAD-PATH';
const String kCredentialsPathOption = 'PASSWORD-FILE-PATH';

/// Perform Mac code signing based on file paths.
///
/// By default, if a user does not specify a dryrun flag, or selects dryrun
/// mode by providing the `--dryrun` flag, then [kDryrunFlag] is set to true.
/// In this case, code signed artifacts are not uploaded back to google cloud storage.
/// On the other hand, if a user provides the flag `--no-dryrun`, [kDryrunFlag]
/// will be set to false, and code signed artifacts will be uploaded back to
/// google cloud storage.
///
/// For [kGcsDownloadPathOption] and [kGcsUploadPathOption], they are required parameter to specify the google cloud bucket paths.
/// [kGcsDownloadPathOption] is the google cloud bucket prefix to download the remote artifacts,
/// [kGcsUploadPathOption] is the cloud bucket prefix to upload codesigned artifact to.
/// For example, supply '--GCS-DOWNLOAD-PATH=gs://flutter_infra_release/ios-usb-dependencies/unsigned/libimobiledevice/<commit>/libimobiledevice.zip',
/// and code sign app will download the artifact at 'flutter_infra_release/ios-usb-dependencies/unsigned/libimobiledevice/<commit>/libimobiledevice.zip' on google cloud storage
///
/// For [kCredentialsPathOption], this is the file path of the password file in file system. The password file stores sensitive passwords.
/// sensitive passwords include <CODESIGN-APPSTORE-ID>, <CODESIGN-TEAM-ID>, and <APP-SPECIFIC-PASSWORD>.
/// For example, if a user supplies --PASSWORD-FILE-PATH=/tmp/passwords.txt, then we would be expecting a password file located at /tmp/passwords.txt.
/// The password file should provide the password value for each of the password name, deliminated by a single colon. The content of a password file would look similar to:
/// CODESIGN-APPSTORE-ID:123
/// CODESIGN-TEAM-ID:456
/// APP-SPECIFIC-PASSWORD:789
///
/// Usage:
/// ```shell
/// dart run bin/codesign.dart --[no-]dryrun --GCS-DOWNLOAD-PATH=gs://flutter_infra_release/flutter/<commit>/android-arm-profile/artifacts.zip
/// --GCS-UPLOAD-PATH=gs://flutter_infra_release/flutter/<commit>/android-arm-profile/artifacts.zip
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
      kGcsDownloadPathOption,
      help: 'The google cloud bucket path to download the artifact from\n'
          'e.g. supply `--GCS-DOWNLOAD-PATH=gs://flutter_infra_release/ios-usb-dependencies/unsigned/ios-deploy/<commit>/ios-deploy.zip`'
          ' if you would like to codesign ios-deploy.zip, which has a google cloud bucket path of flutter_infra_release/ios-usb-dependencies/unsigned/ios-deploy/<commit>/ios-deploy.zip to be downloaded from \n',
    )
    ..addOption(
      kGcsUploadPathOption,
      help: 'The google cloud bucket path to upload the artifact to. \n'
          'e.g. supply `--GCS-UPLOAD-PATH=gs://flutter_infra_release/ios-usb-dependencies/ios-deploy/<commit>/ios-deploy.zip`'
          ' if you would like to codesign ios-deploy.zip, which has a google cloud bucket path of flutter_infra_release/ios-usb-dependencies/ios-deploy/<commit>/ios-deploy.zip to be uploaded to',
    )
    ..addOption(
      kCredentialsPathOption,
      help: 'The file path of the password file in file system. The password file stores sensitive passwords.\n'
          'sensitive passwords include <CODESIGN-APPSTORE-ID>, <CODESIGN-TEAM-ID>, and <APP-SPECIFIC-PASSWORD> \n',
    )
    ..addFlag(
      kDryrunFlag,
      defaultsTo: true,
      help: 'whether we are going to upload the artifacts back to GCS for dryrun',
    );

  final ArgResults argResults = parser.parse(args);

  const Platform platform = LocalPlatform();

  final String codesignCertName = getValueFromEnvOrArgs(kCodesignCertNameOption, argResults, platform.environment)!;
  final String codesignUserName = getValueFromEnvOrArgs(kCodesignUserNameOption, argResults, platform.environment)!;
  final String gCloudDownloadPath = getValueFromEnvOrArgs(kGcsDownloadPathOption, argResults, platform.environment)!;
  final String gCloudUploadPath = getValueFromEnvOrArgs(kGcsUploadPathOption, argResults, platform.environment)!;
  final String passwordsFilePath = getValueFromEnvOrArgs(kCredentialsPathOption, argResults, platform.environment)!;

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
  );

  return FileCodesignVisitor(
    codesignCertName: codesignCertName,
    codesignUserName: codesignUserName,
    fileSystem: fileSystem,
    rootDirectory: rootDirectory,
    passwordsFilePath: passwordsFilePath,
    processManager: processManager,
    dryrun: dryrun,
    gcsDownloadPath: gCloudDownloadPath,
    gcsUploadPath: gCloudUploadPath,
    googleCloudStorage: googleCloudStorage,
  ).validateAll();
}
