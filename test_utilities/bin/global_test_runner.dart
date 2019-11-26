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
  doc['tasks'].forEach((task){
    String scriptPath = join(baseDir, task['script']);
    String taskPath = join(baseDir, task['task']);
    Process.run('sh', <String>[scriptPath, taskPath]).then((result) {
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode != 0) {
        String taskName = task['task'];
        stderr.writeln('There were failures running tests from $taskName');
        exit(result.exitCode);
      }
    });
  });
}

