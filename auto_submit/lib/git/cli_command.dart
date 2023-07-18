// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

class CliCommand {
  CliCommand();

  /// Method runs a single git command in a shell.
  Future<ProcessResult> runCliCommand({
    required String executable,
    required List<String> arguments,
    bool throwOnError = true,
    String? workingDirectory,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: true,
      mode: ProcessStartMode.normal,
    );

    final result = await Future.wait([
      process.exitCode,
      process.stdout.transform(const SystemEncoding().decoder).join(),
      process.stderr.transform(const SystemEncoding().decoder).join(),
    ]);

    final ProcessResult processResult = ProcessResult(
      process.pid,
      result[0] as int,
      result[1] as String,
      result[2] as String,
    );

    if (throwOnError) {
      if (processResult.exitCode != 0) {
        final Map<String, String> outputs = {
          if (processResult.stdout != null) 'Standard out': processResult.stdout.toString().trim(),
          if (processResult.stderr != null) 'Standard error': processResult.stderr.toString().trim(),
        }..removeWhere((k, v) => v.isEmpty);

        String errorMessage;
        if (outputs.isEmpty) {
          errorMessage = 'Unknown error.';
        } else {
          errorMessage = outputs.entries.map((entry) => '${entry.key}\n${entry.value}').join('\n');
        }

        throw ProcessException(executable, arguments, errorMessage, processResult.exitCode);
      }
    }

    return processResult;
  }
}