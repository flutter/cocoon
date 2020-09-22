// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:core' hide print;
import 'dart:core';
import 'dart:io' hide exit;
import 'dart:io';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'dart:io' as io_internals show exit;

final bool hasColor = stdout.supportsAnsiEscapes;
final String bold = hasColor ? '\x1B[1m' : ''; // used for shard titles
final String red = hasColor ? '\x1B[31m' : ''; // used for errors
final String reset = hasColor ? '\x1B[0m' : '';
final String reverse = hasColor ? '\x1B[7m' : ''; // used for clocks

Future<void> main(List<String> arguments) async {
  print('$clock STARTING ANALYSIS');
  try {
    await run(arguments);
  } on ExitException catch (error) {
    error.apply();
  }
  print('$clock ${bold}Analysis successful.$reset');
}

Future<void> run(List<String> arguments) async {
  String cocoonPath = path.join(path.dirname(Platform.script.path), '..');
  print('$clock Root path: $cocoonPath');
  print('$clock Licenses...');
  await verifyNoMissingLicense(cocoonPath);
}

// TESTS
String _generateLicense(String prefix) {
  assert(prefix != null);
  return '${prefix}Copyright (2014|2015|2016|2017|2018|2019|2020) The Flutter Authors. All rights reserved.\n'
      '${prefix}Use of this source code is governed by a BSD-style license that can be\n'
      '${prefix}found in the LICENSE file.';
}

Future<void> verifyNoMissingLicense(String workingDirectory, {bool checkMinimums = true}) async {
  final int overrideMinimumMatches = checkMinimums ? null : 0;
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'dart', overrideMinimumMatches ?? 2000, _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'java', overrideMinimumMatches ?? 39, _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'h', overrideMinimumMatches ?? 30, _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'm', overrideMinimumMatches ?? 30, _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'swift', overrideMinimumMatches ?? 10, _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'gradle', overrideMinimumMatches ?? 100, _generateLicense('// '));
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'gn', overrideMinimumMatches ?? 0, _generateLicense('# '));
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'sh', overrideMinimumMatches ?? 1, '#!/bin/bash\n' + _generateLicense('# '));
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'bat', overrideMinimumMatches ?? 1, _generateLicense(':: '));
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'ps1', overrideMinimumMatches ?? 1, _generateLicense('# '));
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'html', overrideMinimumMatches ?? 1, '<!-- ${_generateLicense('')} -->',
      trailingBlank: false);
  await _verifyNoMissingLicenseForExtension(
      workingDirectory, 'xml', overrideMinimumMatches ?? 1, '<!-- ${_generateLicense('')} -->');
}

Future<void> _verifyNoMissingLicenseForExtension(
    String workingDirectory, String extension, int minimumMatches, String license,
    {bool trailingBlank = true}) async {
  assert(!license.endsWith('\n'));
  final String licensePattern = license + '\n' + (trailingBlank ? '\n' : '');
  final List<String> errors = <String>[];
  for (final File file in _allFiles(workingDirectory, extension, minimumMatches: minimumMatches)) {
    final String contents = file.readAsStringSync().replaceAll('\r\n', '\n');
    if (contents.isEmpty) continue; // let's not go down the /bin/true rabbit hole
    if (!contents.startsWith(RegExp(licensePattern))) errors.add(file.path);
  }
  // Fail if any errors
  if (errors.isNotEmpty) {
    final String s = errors.length == 1 ? ' does' : 's do';
    exitWithError(<String>[
      '${bold}The following ${errors.length} file$s not have the right license header:$reset',
      ...errors,
      'The expected license header is:',
      license,
      if (trailingBlank) '...followed by a blank line.',
    ]);
  }
}

Iterable<File> _allFiles(String workingDirectory, String extension, {@required int minimumMatches}) sync* {
  assert(extension == null || !extension.startsWith('.'), 'Extension argument should not start with a period.');
  final Set<FileSystemEntity> pending = <FileSystemEntity>{Directory(workingDirectory)};
  int matches = 0;
  while (pending.isNotEmpty) {
    final FileSystemEntity entity = pending.first;
    pending.remove(entity);
    if (path.extension(entity.path) == '.tmpl') continue;
    if (entity is File) {
      if (_isGeneratedPluginRegistrant(entity)) continue;
      if (path.basename(entity.path) == 'flutter_export_environment.sh') continue;
      if (path.basename(entity.path) == 'gradlew.bat') continue;
      if (path.basename(entity.path) == 'AppDelegate.h') continue;
      if (path.basename(entity.path) == 'Runner-Bridging-Header.h') continue;
      if (path.basename(entity.path).endsWith('g.dart')) continue;
      if (path.basename(entity.path).endsWith('pb.dart')) continue;
      if (path.basename(entity.path).endsWith('gql.dart')) continue;
      if (extension == null || path.extension(entity.path) == '.$extension') {
        matches += 1;
        yield entity;
      }
    } else if (entity is Directory) {
      if (File(path.join(entity.path, '.dartignore')).existsSync()) continue;
      if (path.basename(entity.path) == '.git') continue;
      if (path.basename(entity.path) == '.gradle') continue;
      if (path.basename(entity.path) == '.dart_tool') continue;
      if (path.basename(entity.path) == 'build') continue;
      if (path.basename(entity.path) == 'ios') continue;
      if (path.basename(entity.path) == 'android') continue;
      pending.addAll(entity.listSync());
    }
  }
  assert(matches >= minimumMatches,
      'Expected to find at least $minimumMatches files with extension ".$extension" in "$workingDirectory", but only found $matches.');
}

bool _isGeneratedPluginRegistrant(File file) {
  final String filename = path.basename(file.path);
  return !file.path.contains('.pub-cache') &&
      (filename == 'GeneratedPluginRegistrant.java' ||
          filename == 'GeneratedPluginRegistrant.h' ||
          filename == 'GeneratedPluginRegistrant.m' ||
          filename == 'generated_plugin_registrant.dart');
}

void exitWithError(List<String> messages) {
  final String redLine = '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset';
  print(redLine);
  messages.forEach(print);
  print(redLine);
  exit(1);
}

class ExitException implements Exception {
  ExitException(this.exitCode);

  final int exitCode;

  void apply() {
    io_internals.exit(exitCode);
  }
}

String get clock {
  final DateTime now = DateTime.now();
  return '$reverse▌'
      '${now.hour.toString().padLeft(2, "0")}:'
      '${now.minute.toString().padLeft(2, "0")}:'
      '${now.second.toString().padLeft(2, "0")}'
      '▐$reset';
}
