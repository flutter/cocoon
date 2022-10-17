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
const String kGCloudDownloadUploadPathOption = 'google-cloud-download-upload-path';

/// Perform Mac code signing based on file paths.
///
/// If [kDryrunFlag] is set to false, code signed artifacts will be uploaded
/// back to google cloud storage.
/// Otherwise, nothing will be uploaded back for dry run. default value is
/// true.
///
/// For [kGCloudDownloadUploadPathOption], it is a required parameter to specify the google cloud bucket paths.
/// This path is a single string concatenated by a '#' sign, the path before the '#' sign should be (1) google cloud bucket prefix to download the remote artifacts,
/// and the path after the '#' sign should be (2) the cloud bucket prefix to upload codesigned artifact to.
/// For example, supply '--google-cloud-download-upload-path=ios-usb-dependencies/unsigned/libimobiledevice/<commit>/libimobiledevice.zip#ios-usb-dependencies/libimobiledevice/<commit>/libimobiledevice.zip',
/// and code sign app will download the artifact at 'ios-usb-dependencies/unsigned/libimobiledevice/<commit>/libimobiledevice.zip', and upload signed artifact back to
/// 'ios-usb-dependencies/libimobiledevice/<commit>/libimobiledevice.zip'.
///
/// Usage:
/// ```shell
/// dart run bin/codesign.dart [--dryrun] --google-cloud-download-upload-path=flutter/<commit>/android-arm-profile/artifacts.zip#flutter/<commit>/android-arm-profile/artifacts.zip
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
      kGCloudDownloadUploadPathOption,
      help:
          'A path concatenated by the google cloud bucket path to download the artifact from, and the google cloud bucket path to upload the artifact to. Deliminated by "#". \n'
          'e.g. supply `--google-cloud-download-upload-path=flutter_infra_release/ios-usb-dependencies/unsigned/ios-deploy/<commit>/ios-deploy.zip#flutter_infra_release/ios-usb-dependencies/ios-deploy/<commit>/ios-deploy.zip`'
          ' if you would like to codesign ios-deploy.zip, which has a google cloud bucket path of flutter_infra_release/ios-usb-dependencies/unsigned/ios-deploy/<commit>/ios-deploy.zip to be downloaded from \n'
          ' and has a google cloud bucket path of flutter_infra_release/ios-usb-dependencies/ios-deploy/<commit>/ios-deploy.zip to be uploaded to',
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
  final String gCloudDownloadUploadPath =
      getValueFromEnvOrArgs(kGCloudDownloadUploadPathOption, argResults, platform.environment)!;

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
    gCloudDownloadUploadPath: gCloudDownloadUploadPath,
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
    googleCloudStorage: googleCloudStorage,
  ).validateAll();
}
