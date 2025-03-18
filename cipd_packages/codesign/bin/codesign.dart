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
const String kDryrunFlag = 'dryrun';
const String kCodesignCertNameOption = 'codesign-cert-name';
const String kInputZipPathOption = 'input-zip-file-path';
const String kOutputZipPathOption = 'output-zip-file-path';
const String kAppSpecificPasswordOption = 'app-specific-password-file-path';
const String kCodesignAppstoreIDOption = 'codesign-appstore-id-file-path';
const String kCodesignTeamIDOption = 'codesign-team-id-file-path';

/// Perform Mac code signing based on file paths.
///
/// By default, if a user does not specify a dryrun flag, or selects dryrun
/// mode by providing the `--dryrun` flag, then [kDryrunFlag] is set to true,
/// a quick sanity check is performed and the notarization process is skipped.
/// On the other hand, if a user provides the flag `--no-dryrun`, [kDryrunFlag]
/// will be set to false, and code signed artifacts will go through the notarization
/// process.
///
/// For [kInputZipPathOption] and [kOutputZipPathOption], they are required parameter to specify the
/// input and output locations.
/// The codesign app will take the zip file located at the input location [kInputZipPathOption], and
/// put codesigned zip at [kOutputZipPathOption]. The work of downloading and uploading the zip
/// artifacts is delegated to recipe.
/// For example, supply
/// '--input-zip-file-path=/tmp/input.zip',
/// and code sign app will code sign the artifacts located at /tmp/input.zip.
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
/// Note: this tool uses Apple developer identity from keychain named build.keychain.
/// You can create/delete build.keychain by following the steps below:
/// /usr/bin/security create-keychain -p '' build.keychain         # for create
/// /usr/bin/security delete-keychain build.keychain               # for delete
///
/// Usage:
/// ```shell
/// dart run bin/codesign.dart --[no-]dryrun
/// --codesign-cert-name="FLUTTER.IO LLC"
/// --codesign-team-id-file-path=/a/b/c.txt
/// --codesign-appstore-id-file-path=/a/b/b.txt
/// --app-specific-password-file-path=/a/b/a.txt
/// --input-zip-file-path=/a/input.zip
/// --output-zip-file-path=/b/output.zip
/// ```
Future<void> main(List<String> args) async {
  Logger.root.onRecord.listen((LogRecord record) {
    stdout.writeln(record.toString());
  });

  final parser = ArgParser();
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
      help:
          'The name of the codesign certificate to be used when codesigning.'
          'the name of the certificate for flutter, for example, is: FLUTTER.IO LLC',
    )
    ..addOption(
      kInputZipPathOption,
      help: 'File path to the unsigned artifact zip file.',
    )
    ..addOption(
      kOutputZipPathOption,
      help: 'File path to codesigned artifact zip file for output.',
    )
    ..addOption(
      kAppSpecificPasswordOption,
      help:
          'The file path of a password file in file system. The password file stores the sensitive password <APP-SPECIFIC-PASSWORD>.',
    )
    ..addOption(
      kCodesignAppstoreIDOption,
      help:
          'The file path of a password file in file system. The password file stores the sensitive password <CODESIGN_APPSTORE_ID>.',
    )
    ..addOption(
      kCodesignTeamIDOption,
      help:
          'The file path of a password file in file system. The password file stores the sensitive password <CODESIGN_TEAM_ID>.',
    )
    ..addFlag(
      kDryrunFlag,
      defaultsTo: true,
      help: 'whether we are going to skip the notarization process.',
    );

  final argResults = parser.parse(args);

  const Platform platform = LocalPlatform();

  final codesignCertName =
      getValueFromArgs(kCodesignCertNameOption, argResults)!;
  final inputZipPath = getValueFromArgs(kInputZipPathOption, argResults)!;
  final outputZipPath = getValueFromArgs(kOutputZipPathOption, argResults)!;
  final appSpecificPasswordFilePath =
      getValueFromArgs(kAppSpecificPasswordOption, argResults)!;
  final codesignAppstoreIDFilePath =
      getValueFromArgs(kCodesignAppstoreIDOption, argResults)!;
  final codesignTeamIDFilePath =
      getValueFromArgs(kCodesignTeamIDOption, argResults)!;

  final dryrun = argResults[kDryrunFlag] as bool;

  if (!platform.isMacOS) {
    throw CodesignException(
      'Error! Expected operating system "macos", actual operating system is: '
      '"${platform.operatingSystem}"',
    );
  }

  const FileSystem fileSystem = LocalFileSystem();
  final rootDirectory = fileSystem.systemTempDirectory.createTempSync(
    'conductor_codesign',
  );
  const ProcessManager processManager = LocalProcessManager();

  return FileCodesignVisitor(
    codesignCertName: codesignCertName,
    fileSystem: fileSystem,
    rootDirectory: rootDirectory,
    appSpecificPasswordFilePath: appSpecificPasswordFilePath,
    codesignAppstoreIDFilePath: codesignAppstoreIDFilePath,
    codesignTeamIDFilePath: codesignTeamIDFilePath,
    processManager: processManager,
    dryrun: dryrun,
    inputZipPath: inputZipPath,
    outputZipPath: outputZipPath,
  ).validateAll();
}
