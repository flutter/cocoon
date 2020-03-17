// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:pedantic/pedantic.dart';

const String angularDartProjectDirectory = '../app';
const String flutterProjectDirectory = '../app_flutter';

const String gcloudProjectIdFlag = 'project';
const String gcloudProjectIdAbbrFlag = 'p';

const String gcloudProjectVersionFlag = 'version';
const String gcloudProjectVersionAbbrFlag = 'v';

const String flutterProfileModeFlag = 'profile';
const String ignoreVersionFlag = 'force-deploy';
const String helpFlag = 'help';

String _gcloudProjectId;
String _gcloudProjectVersion;

bool _flutterProfileMode;
bool _ignoreVersion;

/// Check if [gcloudProjectIdFlag] and [gcloudProjectVersionFlag]
/// were passed as arguments. If they were, also set [_gcloudProjectId]
/// and [_gcloudProjectVersion] accordingly.
bool _getArgs(ArgParser argParser, List<String> arguments) {
  final ArgResults args = argParser.parse(arguments);

  final bool printHelpMessage = args[helpFlag] as bool;
  if (printHelpMessage) {
    return false;
  }

  _gcloudProjectId = args[gcloudProjectIdFlag] as String;
  _gcloudProjectVersion = args[gcloudProjectVersionFlag] as String;
  _flutterProfileMode = args[flutterProfileModeFlag] as bool;
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
  final ProcessResult result =
      await Process.run('flutter', <String>['--version']);
  final String flutterVersionOutput = result.stdout as String;

  // This makes an assumption that only the framework will have its version
  // printed out with the date in YYYY-MM-DD format.
  final RegExp dateRegExp =
      RegExp(r'([12]\d{3}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01]))');
  final String flutterVersionDateRaw =
      dateRegExp.allMatches(flutterVersionOutput).first.group(0);

  final DateTime flutterVersionDate = DateTime.parse(flutterVersionDateRaw);
  final DateTime now = DateTime.now();
  final Duration lastUpdateToFlutter = now.difference(flutterVersionDate);

  return lastUpdateToFlutter.inDays < 21;
}

/// Build app Angular Dart project
Future<bool> _buildAngularDartApp() async {
  /// Clean up previous build files to ensure this codebase is deployed.
  await Process.run(
    'rm',
    <String>['-rf', 'build/'],
    workingDirectory: angularDartProjectDirectory,
  );

  final Process pubProcess = await Process.start('pub', <String>['get'],
      workingDirectory: angularDartProjectDirectory);
  await stdout.addStream(pubProcess.stdout);
  if (await pubProcess.exitCode != 0) {
    return false;
  }

  final Process buildProcess = await Process.start(
    'pub',
    <String>[
      'run',
      'build_runner',
      'build',
      '--release',
      '--output',
      'build',
      '--delete-conflicting-outputs'
    ],
    workingDirectory: angularDartProjectDirectory,
  );
  await stdout.addStream(buildProcess.stdout);

  // The Angular Dart build dashboard page has been replaced with a Flutter
  // version. There are some administrative features missing in the Flutter
  // version so we still offer the old build dashboard.
  await Process.run(
      'mv', <String>['build/web/build.html', 'build/web/old_build.html'],
      workingDirectory: angularDartProjectDirectory);

  return await buildProcess.exitCode == 0;
}

/// Build app_flutter for web.
Future<bool> _buildFlutterWebApp() async {
  /// Clean up previous build files to ensure this codebase is deployed.
  await Process.run('rm', <String>['-rf', 'build/'],
      workingDirectory: flutterProjectDirectory);

  final Process process = await Process.start(
      'flutter',
      <String>[
        'build',
        'web',
        '--dart-define',
        'FLUTTER_WEB_USE_SKIA=true',
        _flutterProfileMode ? '--profile' : '--release'
      ],
      workingDirectory: flutterProjectDirectory);
  await stdout.addStream(process.stdout);

  final bool successfulReturn = await process.exitCode == 0;

  return successfulReturn;
}

/// Copy the built project from app to this app_dart project.
Future<bool> _copyAngularDartProject() async {
  final ProcessResult result = await Process.run('cp',
      <String>['-rn', '$angularDartProjectDirectory/build/web', 'build/']);

  // On MacOS, this will return exit code 1 since this copy does
  // have files that "fail" to overwrite due to `app_flutter`.
  return result.exitCode == 0 || result.exitCode == 1;
}

/// Copy the built project from app_flutter to this app_dart project.
Future<bool> _copyFlutterApp() async {
  final ProcessResult result = await Process.run(
      'cp', <String>['-r', '$flutterProjectDirectory/build', 'build/']);

  return result.exitCode == 0;
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
      _gcloudProjectId,
      '--version',
      _gcloudProjectVersion,
      '--no-promote',
      '--no-stop-previous-version',
    ],
  );

  /// Let this user confirm the details before Google Cloud sends for deployment.
  unawaited(stdin.pipe(process.stdin));

  await process.stderr.pipe(stderr);
  await process.stdout.pipe(stdout);

  return await process.exitCode == 0;
}

Future<void> main(List<String> arguments) async {
  final ArgParser argParser = ArgParser()
    ..addOption(gcloudProjectIdFlag, abbr: gcloudProjectIdAbbrFlag)
    ..addOption(gcloudProjectVersionFlag, abbr: gcloudProjectVersionAbbrFlag)
    ..addFlag(flutterProfileModeFlag)
    ..addFlag(ignoreVersionFlag)
    ..addFlag(helpFlag);

  if (!_getArgs(argParser, arguments)) {
    stdout.write('Required flags:\n'
        '--$gcloudProjectIdFlag gcp-id\n'
        '--$gcloudProjectVersionFlag version\n\n'
        'Optional flags:\n'
        '--$flutterProfileModeFlag\tBuild app_flutter in profile for debugging\n'
        '--$ignoreVersionFlag\tForce deploy with current Flutter version\n');
    exit(1);
  }

  if (!await _checkDependencies()) {
    stderr.writeln(
        'Update Flutter to a version on master from the past 3 weeks to deploy Cocoon');
    exit(1);
  }

  if (!await _buildAngularDartApp()) {
    stderr.writeln('Failed to build Angular Dart project');
    exit(1);
  }

  if (!await _buildFlutterWebApp()) {
    stderr.writeln('Failed to build Flutter app');
    exit(1);
  }

  /// Clean up previous build files to ensure the latest files are deployed.
  await Process.run('rm', <String>['-rf', 'build/']);

  if (!await _copyFlutterApp()) {
    stderr.writeln('Failed to copy Flutter app over');
    exit(1);
  }

  if (!await _copyAngularDartProject()) {
    stderr.writeln('Failed to copy Angular Dart project over');
    exit(1);
  }

  if (!await _deployToAppEngine()) {
    stderr.writeln('Failed to deploy to AppEngine');
    exit(1);
  }
}
