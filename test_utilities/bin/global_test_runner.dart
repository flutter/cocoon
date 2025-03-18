// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

// Runs all the configured tests for cocoon repo.
Future<Null> main(List<String> rawArgs) async {
  final argParser =
      ArgParser()
        ..addOption('tests-file', abbr: 't', defaultsTo: '../tests.yaml');
  final args = argParser.parse(rawArgs);

  // Load tests yaml file.
  final file = File(args['tests-file'] as String);
  final doc = loadYaml(file.readAsStringSync());
  // Execute the tests
  final baseDir = normalize(
    join(dirname(Platform.script.toFilePath()), '..', '..'),
  );
  final prepareScriptPath = join(
    baseDir,
    'test_utilities',
    'bin',
    'prepare_environment.sh',
  );
  await runShellCommand(<String>[prepareScriptPath], 'prepare environment');

  for (final task in doc['tasks'] as Iterable<Map<String, Object?>>) {
    final scriptPath = join(baseDir, task['script'] as String);
    final taskPath = join(baseDir, task['task'] as String);
    await runShellCommand(<String>[
      scriptPath,
      taskPath,
    ], task['task'] as String);
  }
}

Future<void> runShellCommand(List<String> args, String taskName) async {
  unawaited(
    Process.run('sh', args).then((result) {
      stdout.writeln('.. stdout ..');
      stdout.writeln(result.stdout);
      stdout.writeln('.. stderr ..');
      stderr.writeln(result.stderr);
      if (result.exitCode != 0) {
        stderr.writeln('There were failures running tests from $taskName');
        exit(result.exitCode);
      }
    }),
  );
}
