// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:auto_submit/git/cli_command.dart';
import 'package:test/test.dart';

void main() {
  group('Testing git command locally', () {
    test('Checkout locally.', () async {
      var executable = 'ls';
      if (Platform.isWindows) {
        executable = 'dir';
      }

      final cliCommand = CliCommand();
      final processResult = await cliCommand.runCliCommand(
        executable: executable,
        arguments: [],
      );
      expect(processResult.exitCode, isZero);
    });
  });
}
