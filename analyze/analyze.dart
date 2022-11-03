// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

const FileSystem fs = LocalFileSystem();

// Cocoon's root is the parent of the current working directory,
final Directory cocoonRoot = fs.currentDirectory.parent;

Future<void> main(List<String> arguments) async {
  print('STARTING ANALYSIS');
  print('cocoonRoot: ${cocoonRoot.path}');
  await run(arguments);
  print('Analysis successful.');
}

Future<void> run(List<String> arguments) async {
  bool assertsEnabled = false;
  assert(() {
    assertsEnabled = true;
    return true;
  }());
  if (!assertsEnabled) {
    exitWithError(<String>['The analyze.dart script must be run with --enable-asserts.']);
  }

  print('Trailing spaces...');
  await verifyNoTrailingSpaces(cocoonRoot.path);

  print('Executable allowlist...');
  await _checkForNewExecutables();
}

// TESTS

Future<void> verifyNoTrailingSpaces(
  String workingDirectory, {
  int minimumMatches = 100,
}) async {
  final List<File> files = await _allFiles(workingDirectory, null, minimumMatches: minimumMatches)
      .where((File file) => path.basename(file.path) != 'serviceaccount.enc')
      .where((File file) => path.basename(file.path) != 'Ahem.ttf')
      .where((File file) => path.extension(file.path) != '.snapshot')
      .where((File file) => path.extension(file.path) != '.png')
      .where((File file) => path.extension(file.path) != '.jpg')
      .where((File file) => path.extension(file.path) != '.ico')
      .where((File file) => path.extension(file.path) != '.jar')
      .where((File file) => path.extension(file.path) != '.swp')
      .toList();
  final List<String> problems = <String>[];
  for (final File file in files) {
    final List<String> lines = file.readAsLinesSync();
    for (int index = 0; index < lines.length; index += 1) {
      if (lines[index].endsWith(' ')) {
        problems.add('${file.path}:${index + 1}: trailing U+0020 space character');
      } else if (lines[index].endsWith('\t')) {
        problems.add('${file.path}:${index + 1}: trailing U+0009 tab character');
      }
    }
    if (lines.isNotEmpty && lines.last == '') problems.add('${file.path}:${lines.length}: trailing blank line');
  }
  if (problems.isNotEmpty) exitWithError(problems);
}

// UTILITY FUNCTIONS

Future<List<File>> _gitFiles(String workingDirectory, {bool runSilently = true}) async {
  final EvalResult evalResult = await _evalCommand(
    'git',
    <String>['ls-files', '-z'],
    workingDirectory: workingDirectory,
    runSilently: runSilently,
  );
  if (evalResult.exitCode != 0) {
    exitWithError(<String>[
      'git ls-files failed with exit code ${evalResult.exitCode}',
      'stdout:',
      evalResult.stdout,
      'stderr:',
      evalResult.stderr,
    ]);
  }
  final List<String> filenames = evalResult.stdout.split('\x00');
  assert(filenames.last.isEmpty); // git ls-files gives a trailing blank 0x00
  filenames.removeLast();
  return filenames.map<File>((String filename) => fs.file(path.join(workingDirectory, filename))).toList();
}

Stream<File> _allFiles(String workingDirectory, String? extension, {required int minimumMatches}) async* {
  final Set<String> gitFileNamesSet = <String>{};
  gitFileNamesSet.addAll((await _gitFiles(workingDirectory)).map((File f) => path.canonicalize(f.absolute.path)));

  assert(extension == null || !extension.startsWith('.'), 'Extension argument should not start with a period.');
  final Set<FileSystemEntity> pending = <FileSystemEntity>{fs.directory(workingDirectory)};
  int matches = 0;
  while (pending.isNotEmpty) {
    final FileSystemEntity entity = pending.first;
    pending.remove(entity);
    if (path.extension(entity.path) == '.tmpl') continue;
    if (entity is File) {
      if (!gitFileNamesSet.contains(path.canonicalize(entity.absolute.path))) continue;
      if (path.basename(entity.path) == 'flutter_export_environment.sh') continue;
      if (path.basename(entity.path) == 'gradlew.bat') continue;
      if (path.basename(entity.path) == '.DS_Store') continue;
      if (extension == null || path.extension(entity.path) == '.$extension') {
        matches += 1;
        yield entity;
      }
    } else if (entity is Directory) {
      if (fs.file(path.join(entity.path, '.dartignore')).existsSync()) continue;
      if (path.basename(entity.path) == '.git') continue;
      if (path.basename(entity.path) == '.idea') continue;
      if (path.basename(entity.path) == '.gradle') continue;
      if (path.basename(entity.path) == '.dart_tool') continue;
      if (path.basename(entity.path) == '.idea') continue;
      if (path.basename(entity.path) == 'build') continue;
      pending.addAll(entity.listSync());
    }
  }
  assert(
    matches >= minimumMatches,
    'Expected to find at least $minimumMatches files with extension ".$extension" in "$workingDirectory", but only found $matches.',
  );
}

class EvalResult {
  EvalResult({
    required this.stdout,
    required this.stderr,
    this.exitCode = 0,
  });

  final String stdout;
  final String stderr;
  final int exitCode;
}

Future<EvalResult> _evalCommand(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  Map<String, String>? environment,
  bool allowNonZeroExit = false,
  bool runSilently = false,
}) async {
  final String commandDescription = '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  final String relativeWorkingDir = path.relative(workingDirectory);

  if (!runSilently) {
    print('RUNNING $relativeWorkingDir $commandDescription');
  }

  final Stopwatch time = Stopwatch()..start();
  final Process process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
  );

  final Future<List<List<int>>> savedStdout = process.stdout.toList();
  final Future<List<List<int>>> savedStderr = process.stderr.toList();
  final int exitCode = await process.exitCode;
  final EvalResult result = EvalResult(
    stdout: utf8.decode((await savedStdout).expand<int>((List<int> ints) => ints).toList()),
    stderr: utf8.decode((await savedStderr).expand<int>((List<int> ints) => ints).toList()),
    exitCode: exitCode,
  );

  if (!runSilently) {
    print('ELAPSED TIME: ${time.elapsed} for $commandDescription in $relativeWorkingDir');
  }

  if (exitCode != 0 && !allowNonZeroExit) {
    stderr.write(result.stderr);
    exitWithError(<String>[
      'ERROR: Last command exited with $exitCode.',
      'Command: $commandDescription',
      'Relative working directory: $relativeWorkingDir',
    ]);
  }

  return result;
}

// These files legitimately require executable permissions
const Set<String> kExecutableAllowlist = <String>{
  'build_and_analyze.sh',
  'dev/provision_salt.sh',
  'format.sh',
  'oneoff/cirrus_stats/load.sh',
  'test.sh',
  'test_utilities/bin/config_test_runner.sh',
  'test_utilities/bin/dart_test_runner.sh',
  'test_utilities/bin/flutter_test_runner.sh',
  'test_utilities/bin/global_test_runner.dart',
  'test_utilities/bin/prepare_environment.sh',
};

Future<void> _checkForNewExecutables() async {
  // 0b001001001
  const int executableBitMask = 0x49;

  final List<File> files = await _gitFiles(cocoonRoot.path);
  int unexpectedExecutableCount = 0;
  for (final File file in files) {
    final String relativePath = path.relative(
      file.path,
      from: cocoonRoot.path,
    );
    final FileStat stat = file.statSync();
    final bool isExecutable = stat.mode & executableBitMask != 0x0;
    if (isExecutable && !kExecutableAllowlist.contains(relativePath)) {
      unexpectedExecutableCount += 1;
      print('$relativePath is executable: ${(stat.mode & 0x1FF).toRadixString(2)}');
    }
  }
  if (unexpectedExecutableCount > 0) {
    throw Exception(
      'found $unexpectedExecutableCount unexpected executable file'
      '${unexpectedExecutableCount == 1 ? '' : 's'}! If this was intended, you '
      'must add this file to kExecutableAllowlist in analyze/analyze.dart',
    );
  }
}

void exitWithError(List<String> messages) {
  final String line = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
  print(line);
  messages.forEach(print);
  print(line);
  exit(1);
}
