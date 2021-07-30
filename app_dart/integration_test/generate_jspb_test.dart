// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import 'common.dart';

/// Validates `bin/generate_jspb.dart` which is used in the ci.yaml roller script.
Future<void> main() async {
    test('validate cocoon ci.yaml generates jspb', () async {
      final ProcessResult generateResult = Process.runSync('dart', <String>['run', 'bin/generate_jspb.dart', '../.ci.yaml']);
      if (generateResult.exitCode != 0) {
        fail('generate_jspb.dart failed with exit code ${generateResult.exitCode}\n'
        'stderr: ${generateResult.stderr}\n'
        'stdout: ${generateResult.stdout}'
        );
      }

      // Update expectations file
      final File jspbExpectationsFile = File('integration_test/data/cocoon_config.json');
      jspbExpectationsFile.writeAsStringSync(generateResult.stdout as String);

      expectNoDiff();
    });
}
