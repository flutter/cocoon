// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:github/github.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

import 'common.dart';

/// List of supported repositories with TESTOWNERS.
final List<SupportedConfig> configs = <SupportedConfig>[
  SupportedConfig(RepositorySlug('flutter', 'flutter')),
];

Future<void> main() async {
  for (final SupportedConfig config in configs) {
    test('validate test ownership for $config', () async {
      const String dart = 'dart';
      const String taskExecutable = 'bin/validate_task_ownership.dart';
      final List<String> taskArgs = <String>[config.slug.name, config.branch];

      const ProcessManager processManager = LocalProcessManager();
      final Process process = await processManager.start(
        <String>[dart, taskExecutable, ...taskArgs],
        workingDirectory: Directory.current.path,
      );

      final List<String> output = <String>[];
      final List<String> error = <String>[];

      process.stdout
          .transform<String>(const Utf8Decoder())
          .transform<String>(const LineSplitter())
          .listen((String line) {
        stdout.writeln('[STDOUT] $line');
        output.add(line);
      });

      process.stderr
          .transform<String>(const Utf8Decoder())
          .transform<String>(const LineSplitter())
          .listen((String line) {
        stderr.writeln('[STDERR] $line');
        error.add(line);
      });

      final int exitCode = await process.exitCode;
      if (exitCode != 0) {
        for (String line in error) {
          print(line);
        }
        fail('An error has occurred.');
      }
    });
  }
}
