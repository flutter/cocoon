// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:args/args.dart';
import 'package:yaml/yaml.dart';
import "package:path/path.dart";

// Runs all the configured tests for cocoon repo.
Future<Null> main(List<String> rawArgs) async {
  ArgParser argParser = ArgParser()
    ..addOption(
      'tests-file',
      abbr: 't',
      defaultsTo: '../tests.yaml'
    );
  ArgResults args = argParser.parse(rawArgs);

  // Load tests yaml file.
  File file = new File(args['tests-file']);
  var doc = loadYaml(file.readAsStringSync());
  // Execute the tests
  String baseDir = normalize(join(dirname(Platform.script.toFilePath()), '..', '..'));
  String prepareScriptPath = join(baseDir, 'test_utilities', 'bin', 'prepare_environment.sh');
  await runShellCommand(<String>[prepareScriptPath], 'prepare environment');
  doc['tasks'].forEach((task) async {
    String scriptPath = join(baseDir, task['script']);
    String taskPath = join(baseDir, task['task']);
    await runShellCommand(<String>[scriptPath, taskPath], task['task']);
  });
}

void runShellCommand(List<String> args, String taskName) async {
  Process.run('sh', args).then((result) {
      stdout.writeln('.. stdout ..');
      stdout.writeln(result.stdout);
      stdout.writeln('.. stderr ..');
      stderr.writeln(result.stderr);
      if (result.exitCode != 0) {
        stderr.writeln('There were failures running tests from $taskName');
        exit(result.exitCode);
      }
    });
}
