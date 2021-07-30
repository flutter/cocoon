// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

/// Validate the `yaml_converter.dart`, a boiler plate LSC script.
/// 
/// It ensures an empty change does not change Cocoon's ci.yaml.
void main() {
  // Run LSC script
  final File ciYamlFile = File('../.ci.yaml');
  final ProcessResult result = Process.runSync('dart', <String>['run', 'bin/yaml_converter.dart', ciYamlFile.path]);
  if (result.exitCode != 0) {
    throw Exception('LSC script exited with code ${result.exitCode}\n'
      'stdout: ${result.stdout}'
      '\nstderr: ${result.stderr}'
    );
  }

  // Write the LSC back to the ci.yaml
  ciYamlFile.writeAsStringSync(result.stdout as String);

  // Validate there is no diff
  final ProcessResult gitResult = Process.runSync('git', <String>['diff', '--exit-code']);
  if (gitResult.exitCode != 0) {
    final ProcessResult gitDiffOutput = Process.runSync('git', <String>['diff']);
    throw Exception('LSC script made a diff to Cocoon .ci.yaml\n${gitDiffOutput.stdout}');
  }
}
