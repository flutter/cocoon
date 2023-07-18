// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:auto_submit/git/cli_command.dart';
import 'package:test/test.dart';

void main() {
  group('Testing git command locally', () {
    test('Checkout locally.', () async {
      String executable = 'ls';
      if (Platform.isWindows) {
        executable = 'dir';
      }

      final CliCommand cliCommand = CliCommand();
      final ProcessResult processResult = await cliCommand.runCliCommand(executable: executable, arguments: []);
      expect(processResult.exitCode, isZero);
    });
  });
}