// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:pedantic/pedantic.dart';

const String gcloudProjectIdFlag = 'project';
const String gcloudProjectIdAbbrFlag = 'p';

const String gcloudProjectVersionFlag = 'version';
const String gcloudProjectVersionAbbrFlag = 'v';

String _gcloudProjectId;
String _gcloudProjectVersion;

/// Check if [gcloudProjectIdFlag] and [gcloudProjectVersionFlag]
/// were passed as arguments. If they were, also set [_gcloudProjectId]
/// and [_gcloudProjectVersion] accordingly.
bool _getArgs(ArgParser argParser, List<String> arguments) {
  final ArgResults args = argParser.parse(arguments);

  _gcloudProjectId = args[gcloudProjectIdFlag];
  _gcloudProjectVersion = args[gcloudProjectVersionFlag];

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

/// Build app_flutter for web.
Future<bool> _buildFlutterWebApp() async {
  final Process process = await Process.start(
      'flutter', <String>['build', 'web'],
      workingDirectory: '../app_flutter');
  await stdout.addStream(process.stdout);

  return await process.exitCode == 0;
}

/// Copy the built project from app_flutter to this app_dart project.
Future<bool> _copyFlutterApp() async {
  final ProcessResult result =
      await Process.run('cp', <String>['-r', '../app_flutter/build', 'build']);

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
    ..addOption(gcloudProjectVersionFlag, abbr: gcloudProjectVersionAbbrFlag);

  if (!_getArgs(argParser, arguments)) {
    exit(1);
  }
  
  if (!await _buildFlutterWebApp()) {
    stderr.writeln('Failed to build Flutter app');
    exit(1);
  }

  if (!await _copyFlutterApp()) {
    stderr.writeln('Failed to copy Flutter app over');
    exit(1);
  }

  if (!await _deployToAppEngine()) {
    stderr.writeln('Failed to deploy to AppEngine');
    exit(1);
  }
}
