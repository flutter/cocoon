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
const String kGcsDownloadPathOption = 'gcs-download-path';
const String kGcsUploadPathOption = 'gcs-upload-path';
const String kAppSpecificPasswordOption = 'app-specific-password-file-path';
const String kCodesignAppstoreIDOption = 'codesign-appstore-id-file-path';
const String kCodesignTeamIDOption = 'codesign-team-id-file-path';

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
/// For example, supply
/// '--gcs-download-path=gs://flutter_infra_release/ios-usb-dependencies/unsigned/libimobiledevice/<commit>/libimobiledevice.zip',
/// and code sign app will download the artifact at
/// 'flutter_infra_release/ios-usb-dependencies/unsigned/libimobiledevice/<commit>/libimobiledevice.zip'
/// on google cloud storage
///
/// For [kAppSpecificPasswordOption], [kCodesignAppstoreIDOption] and [kCodesignTeamIDOption],
/// they are file paths of the password files in the file system.
/// Each of the file paths stores a single line of sensitive password.
/// sensitive passwords include <CODESIGN_APPSTORE_ID>, <CODESIGN_TEAM_ID>, and <APP_SPECIFIC_PASSWORD>.
/// For example, if a user supplies --app-specific-password-file-path=/tmp/passwords.txt,
/// then we would be expecting a password file located at /tmp/passwords.txt.
/// The password file should contain the password name APP-SPECIFIC-PASSWORD and its value, deliminated by a single colon.
/// The content of a password file would look similar to:
/// APP-SPECIFIC-PASSWORD:789
///
/// [kCodesignCertNameOption] is public information. For codesigning flutter artifacts,
/// a user can provide values for this variable as shown in the example below.
///
/// Usage:
/// ```shell
/// dart run bin/codesign.dart --[no-]dryrun
/// --codesign-cert-name="FLUTTER.IO LLC"
/// --codesign-team-id-file-path=/a/b/c.txt
/// --codesign-appstore-id-file-path=/a/b/b.txt
/// --app-specific-password-file-path=/a/b/a.txt
/// --gcs-download-path=gs://flutter_infra_release/flutter/<commit>/android-arm-profile/artifacts.zip
/// --gcs-upload-path=gs://flutter_infra_release/flutter/<commit>/android-arm-profile/artifacts.zip
/// ```
Future<void> main(List<String> args) async {
  final ArgParser parser = ArgParser();
  parser
    ..addFlag(
      kHelpFlag,
      help: 'Prints usage info.',
      callback: (bool value) {
        if (value) {
          stdout.write('${parser.usage}\n');
          exit(1);
        }
      },
    )
    ..addOption(
      kCodesignCertNameOption,
      help: 'The name of the codesign certificate to be used when codesigning.'
          'the name of the certificate for flutter, for example, is: FLUTTER.IO LLC',
    )
    ..addOption(
      kGcsDownloadPathOption,
      help: 'The google cloud bucket path to download the artifact from\n'
          'e.g. supply `--gcs-download-path=gs://flutter_infra_release/ios-usb-dependencies/unsigned/ios-deploy/<commit>/ios-deploy.zip`'
          ' if you would like to codesign ios-deploy.zip, which has a google cloud bucket path of flutter_infra_release/ios-usb-dependencies/unsigned/ios-deploy/<commit>/ios-deploy.zip to be downloaded from \n',
    )
    ..addOption(
      kGcsUploadPathOption,
      help: 'The google cloud bucket path to upload the artifact to. \n'
          'e.g. supply `--gcs-upload-path=gs://flutter_infra_release/ios-usb-dependencies/ios-deploy/<commit>/ios-deploy.zip`'
          ' if you would like to codesign ios-deploy.zip, which has a google cloud bucket path of flutter_infra_release/ios-usb-dependencies/ios-deploy/<commit>/ios-deploy.zip to be uploaded to',
    )
    ..addOption(
      kAppSpecificPasswordOption,
      help:
          'The file path of a password file in file system. The password file stores the sensitive password <APP-SPECIFIC-PASSWORD> \n',
    )
    ..addOption(
      kCodesignAppstoreIDOption,
      help:
          'The file path of a password file in file system. The password file stores the sensitive password <CODESIGN_APPSTORE_ID> \n',
    )
    ..addOption(
      kCodesignTeamIDOption,
      help:
          'The file path of a password file in file system. The password file stores the sensitive password <CODESIGN_TEAM_ID> \n',
    )
    ..addFlag(
      kDryrunFlag,
      defaultsTo: true,
      help: 'whether we are going to upload the artifacts back to GCS for dryrun',
    );

  final ArgResults argResults = parser.parse(args);

  const Platform platform = LocalPlatform();

  final String codesignCertName = getValueFromArgs(kCodesignCertNameOption, argResults)!;
  final String gCloudDownloadPath = getValueFromArgs(kGcsDownloadPathOption, argResults)!;
  final String gCloudUploadPath = getValueFromArgs(kGcsUploadPathOption, argResults)!;
  final String appSpecificPasswordFilePath = getValueFromArgs(kAppSpecificPasswordOption, argResults)!;
  final String codesignAppstoreIDFilePath = getValueFromArgs(kCodesignAppstoreIDOption, argResults)!;
  final String codesignTeamIDFilePath = getValueFromArgs(kCodesignTeamIDOption, argResults)!;

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
    fileSystem: fileSystem,
    rootDirectory: rootDirectory,
    appSpecificPasswordFilePath: appSpecificPasswordFilePath,
    codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
    codesignTeamIDFilePath: codesignTeamIDFilePath,
    processManager: processManager,
    dryrun: dryrun,
    gcsDownloadPath: gCloudDownloadPath,
    gcsUploadPath: gCloudUploadPath,
    googleCloudStorage: googleCloudStorage,
  ).validateAll();
}
