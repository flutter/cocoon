// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

const String cloudbuildDirectory = 'cloud_build';
const String workspaceDirectory = '../';

const String gcloudProjectIdFlag = 'project';
const String gcloudProjectIdAbbrFlag = 'p';

const String gcloudProjectVersionFlag = 'version';
const String gcloudProjectVersionAbbrFlag = 'v';

const String ignoreVersionFlag = 'ignore-version-check';
const String helpFlag = 'help';

String? _gcloudProjectId;
String? _gcloudProjectVersion;

late bool _ignoreVersion;

/// Check if [gcloudProjectIdFlag] and [gcloudProjectVersionFlag]
/// were passed as arguments. If they were, also set [_gcloudProjectId]
/// and [_gcloudProjectVersion] accordingly.
bool _getArgs(ArgParser argParser, List<String> arguments) {
  final ArgResults args = argParser.parse(arguments);

  final bool printHelpMessage = args[helpFlag] as bool;
  if (printHelpMessage) {
    return false;
  }

  _gcloudProjectId = args[gcloudProjectIdFlag] as String?;
  _gcloudProjectVersion = args[gcloudProjectVersionFlag] as String?;
  _ignoreVersion = args[ignoreVersionFlag] as bool;

  if (_gcloudProjectId == null) {
    stderr.write('--$gcloudProjectIdFlag must be defined\n');
    return false;
  }

  if (_gcloudProjectVersion == null) {
    stderr.write('--$gcloudProjectVersionFlag must be defined\n');
    return false;
  }

  return true;
}

/// Check the Flutter version installed and make sure it is a recent version
/// from the past 21 days.
///
/// Flutter tools handles the rest of the checks (e.g. Dart version) when
/// building the project.
Future<bool> _checkDependencies() async {
  if (_ignoreVersion) {
    return true;
  }

  stdout.writeln('Checking Flutter version via flutter --version');
  final ProcessResult result = await Process.run('flutter', <String>['--version']);
  final String flutterVersionOutput = result.stdout as String;

  // This makes an assumption that only the framework will have its version
  // printed out with the date in YYYY-MM-DD format.
  final RegExp dateRegExp = RegExp(r'([12]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]))');
  final String flutterVersionDateRaw = dateRegExp.allMatches(flutterVersionOutput).first.group(0)!;

  final DateTime flutterVersionDate = DateTime.parse(flutterVersionDateRaw);
  final DateTime now = DateTime.now();
  final Duration lastUpdateToFlutter = now.difference(flutterVersionDate);

  return lastUpdateToFlutter.inDays < 21;
}

/// Run the Google Cloud CLI tool to deploy to [_gcloudProjectId] under
/// version [_gcloudProjectVersion].
Future<bool> _deployToAppEngine() async {
  stdout.writeln('Deploying to AppEngine');

  /// The Google Cloud deployment command is an interactive process. It will
  /// print out what it is about to do, and ask for confirmation (Y/n).
  final Process process = await Process.start(
    'gcloud',
    <String>[
      'app',
      'deploy',
      '--project',
      _gcloudProjectId!,
      '--version',
      _gcloudProjectVersion!,
      '--no-promote',
      '--no-stop-previous-version',
//      '--quiet',
    ],
  );

  /// Let this user confirm the details before Google Cloud sends for deployment.
  unawaited(stdin.pipe(process.stdin));

  await process.stderr.pipe(stderr);
  await process.stdout.pipe(stdout);

  return await process.exitCode == 0;
}

/// Run [args] in bash shell and validate it finshes with exit code 0.
Future<void> shellCommand(List<String> args) async {
  final ProcessResult result = await Process.run(
    'bash',
    args,
    workingDirectory: workspaceDirectory,
  );

  if (result.exitCode != 0) {
    print('$args failed with exit code ${result.exitCode}');
    print('stdout: ${result.stdout}');
    print('stderr: ${result.stderr}');
    exit(1);
  }
}

Future<void> main(List<String> arguments) async {
  final ArgParser argParser = ArgParser()
    ..addOption(gcloudProjectIdFlag, abbr: gcloudProjectIdAbbrFlag)
    ..addOption(gcloudProjectVersionFlag, abbr: gcloudProjectVersionAbbrFlag)
    ..addFlag(ignoreVersionFlag)
    ..addFlag(helpFlag);

  if (!_getArgs(argParser, arguments)) {
    stdout.write('Required flags:\n'
        '--$gcloudProjectIdFlag gcp-id\n'
        '--$gcloudProjectVersionFlag version\n\n'
        'Optional flags:\n'
        '--$ignoreVersionFlag\tForce deploy with current Flutter version\n');
    exit(1);
  }

  if (!await _checkDependencies()) {
    stderr.writeln('Update Flutter to a version on master from the past 3 weeks to deploy Cocoon');
    exit(1);
  }

  await shellCommand(<String>['$cloudbuildDirectory/dashboard_build.sh']);

  if (!await _deployToAppEngine()) {
    stderr.writeln('Failed to deploy to AppEngine');
    exit(1);
  }
}
