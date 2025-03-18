// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';
import 'dart:io';

import 'package:path/path.dart' as path;

final bool hasColor = stdout.supportsAnsiEscapes;
final String bold = hasColor ? '\x1B[1m' : ''; // used for shard titles
final String red = hasColor ? '\x1B[31m' : ''; // used for errors
final String reset = hasColor ? '\x1B[0m' : '';
final String reverse = hasColor ? '\x1B[7m' : ''; // used for clocks

Future<void> main() async {
  print('$clock STARTING ANALYSIS');
  await run();
  print('$clock ${bold}Analysis successful.$reset');
}

Future<void> run() async {
  final cocoonPath = path.join(path.dirname(Platform.script.path), '..');
  print('$clock Root path: $cocoonPath');
  print('$clock Licenses...');
  await verifyConsistentLicenses(cocoonPath);
  await verifyNoMissingLicense(cocoonPath);
}

// TESTS
String _generateLicense(String prefix) {
  return '${prefix}Copyright (2014|2015|2016|2017|2018|2019|2020|2021|2022|2023|2024|2025) The Flutter Authors. All rights reserved.\n'
      '${prefix}Use of this source code is governed by a BSD-style license that can be\n'
      '${prefix}found in the LICENSE file.';
}

/// Ensure that LICENSES in Cocoon and its packages are consistent with each other.
///
/// Verifies that every LICENSE file in Cocoon matches cocoon/LICENSE.
Future<void> verifyConsistentLicenses(String workingDirectory) async {
  final goldenLicensePath = '$workingDirectory/LICENSE';
  final goldenLicense = File(goldenLicensePath).readAsStringSync();
  if (goldenLicense.isEmpty) {
    throw Exception('No LICENSE was found at the root of Cocoon');
  }

  final badLicenses = <String>[];
  for (final entity in Directory(workingDirectory).listSync(recursive: true)) {
    final cocoonPath = entity.path.split('/../').last;
    if (cocoonPath.contains(RegExp('(.git)|(.dart_tool)|(.plugin_symlinks)'))) {
      continue;
    }

    if (path.basename(entity.path) == 'LICENSE') {
      final license = File(entity.path).readAsStringSync();
      if (license != goldenLicense) {
        badLicenses.add(cocoonPath);
      }
    }
  }

  if (badLicenses.isNotEmpty) {
    exitWithError(
      <String>[
        'The following LICENSE files do not match the golden LICENSE at root:',
      ]..insertAll(1, badLicenses),
    );
  }
}

Future<void> verifyNoMissingLicense(
  String workingDirectory, {
  bool checkMinimums = true,
}) async {
  final overrideMinimumMatches = checkMinimums ? null : 0;
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'dart',
    overrideMinimumMatches ?? 2000,
    _generateLicense('// '),
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'java',
    overrideMinimumMatches ?? 39,
    _generateLicense('// '),
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'h',
    overrideMinimumMatches ?? 30,
    _generateLicense('// '),
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'm',
    overrideMinimumMatches ?? 30,
    _generateLicense('// '),
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'swift',
    overrideMinimumMatches ?? 10,
    _generateLicense('// '),
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'gradle',
    overrideMinimumMatches ?? 100,
    _generateLicense('// '),
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'gn',
    overrideMinimumMatches ?? 0,
    _generateLicense('# '),
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'Dockerfile',
    overrideMinimumMatches ?? 1,
    _generateLicense('# '),
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'sh',
    overrideMinimumMatches ?? 1,
    '#![^\n]+sh\n${_generateLicense('# ')}',
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'bat',
    overrideMinimumMatches ?? 1,
    _generateLicense(':: '),
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'ps1',
    overrideMinimumMatches ?? 1,
    _generateLicense('# '),
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'html',
    overrideMinimumMatches ?? 1,
    '<!-- ${_generateLicense('')} -->',
    trailingBlank: false,
  );
  await _verifyNoMissingLicenseForExtension(
    workingDirectory,
    'xml',
    overrideMinimumMatches ?? 1,
    '<!-- ${_generateLicense('')} -->',
  );
}

Future<void> _verifyNoMissingLicenseForExtension(
  String workingDirectory,
  String extension,
  int minimumMatches,
  String license, {
  bool trailingBlank = true,
}) async {
  assert(!license.endsWith('\n'));
  final licensePattern = '$license\n${trailingBlank ? '\n' : ''}';
  final errors = <String>[];
  for (final file in _allFiles(
    workingDirectory,
    extension,
    minimumMatches: minimumMatches,
  )) {
    final contents = file.readAsStringSync().replaceAll('\r\n', '\n');
    if (contents.isEmpty) {
      continue; // let's not go down the /bin/true rabbit hole
    }
    if (!contents.startsWith(RegExp(licensePattern))) errors.add(file.path);
  }
  // Fail if any errors
  if (errors.isNotEmpty) {
    final s = errors.length == 1 ? ' does' : 's do';
    exitWithError(<String>[
      '${bold}The following ${errors.length} file$s not have the right license header:$reset',
      ...errors,
      'The expected license header is:',
      license,
      if (trailingBlank) '...followed by a blank line.',
    ]);
  }
}

Iterable<File> _allFiles(
  String workingDirectory,
  String extension, {
  required int minimumMatches,
}) sync* {
  assert(
    !extension.startsWith('.'),
    'Extension argument should not start with a period.',
  );
  final pending = <FileSystemEntity>{Directory(workingDirectory)};
  var matches = 0;
  while (pending.isNotEmpty) {
    final entity = pending.first;
    pending.remove(entity);
    if (path.extension(entity.path) == '.tmpl') continue;
    if (entity is File) {
      if (_isGeneratedPluginRegistrant(entity)) continue;
      if (path.basename(entity.path) == 'AppDelegate.h') continue;
      if (path.basename(entity.path) == 'flutter_export_environment.sh') {
        continue;
      }
      if (path.basename(entity.path) == 'gradlew.bat') continue;
      if (path.basename(entity.path) == 'Runner-Bridging-Header.h') continue;
      if (path.basename(entity.path).endsWith('g.dart')) continue;
      if (path.basename(entity.path).endsWith('mocks.mocks.dart')) continue;
      if (path.basename(entity.path).endsWith('pb.dart')) continue;
      if (path.basename(entity.path).endsWith('pbenum.dart')) continue;
      if (path.basename(entity.path).endsWith('pbjson.dart')) continue;
      if (path.basename(entity.path).endsWith('pbgrpc.dart')) continue;
      if (path.basename(entity.path).endsWith('pbserver.dart')) continue;
      if (path.extension(entity.path) == '.$extension') {
        matches += 1;
        yield entity;
      }
      if (path.basename(entity.path) == 'Dockerfile' &&
          extension == 'Dockerfile') {
        matches += 1;
        yield entity;
      }
    } else if (entity is Directory) {
      if (File(path.join(entity.path, '.dartignore')).existsSync()) continue;
      if (path.basename(entity.path) == '.git') continue;
      if (path.basename(entity.path) == '.gradle') continue;
      if (path.basename(entity.path) == '.dart_tool') continue;
      if (path.basename(entity.path) == 'third_party') continue;
      if (_isPartOfAppTemplate(entity)) continue;
      pending.addAll(entity.listSync());
    }
  }
  assert(
    matches >= minimumMatches,
    'Expected to find at least $minimumMatches files with extension ".$extension" in "$workingDirectory", but only found $matches.',
  );
}

bool _isPartOfAppTemplate(Directory directory) {
  const templateDirs = <String>{
    'android',
    'build',
    'ios',
    'linux',
    'macos',
    'web',
    'windows',
  };
  // Project directories will have a metadata file in them.
  if (File(path.join(directory.parent.path, '.metadata')).existsSync()) {
    return templateDirs.contains(path.basename(directory.path));
  }
  return false;
}

bool _isGeneratedPluginRegistrant(File file) {
  final filename = path.basenameWithoutExtension(file.path);
  return !path.split(file.path).contains('.pub-cache') &&
      (filename == 'generated_plugin_registrant' ||
          filename == 'GeneratedPluginRegistrant');
}

void exitWithError(List<String> messages) {
  final redLine =
      '$red━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$reset';
  print(redLine);
  messages.forEach(print);
  print(redLine);
  exit(1);
}

String get clock {
  final now = DateTime.now();
  return '$reverse▌'
      '${now.hour.toString().padLeft(2, "0")}:'
      '${now.minute.toString().padLeft(2, "0")}:'
      '${now.second.toString().padLeft(2, "0")}'
      '▐$reset';
}
